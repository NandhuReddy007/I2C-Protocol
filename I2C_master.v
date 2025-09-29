// Code your design here
module i2c_master(
  input wire clk,rst,
  input wire [6:0] addr,
  input wire [7:0]data_in,
  input wire enable,
  input wire rw,
  input wire lines_busy,

  output reg [7:0] data_out,
  output wire ready,//active low

  inout i2c_sda,
  inout wire i2c_scl,
  inout interrupt

  );

  localparam IDLE=0;
  localparam START=1;
  localparam ADDRESS=2;
  localparam ACK_WAIT=3;
  localparam ADDR_ACK=4;
  localparam WRITE_DATA=5;
  localparam MASTER_DATA_ACK=6;
  localparam READ_DATA=7;
  localparam SLAVE_DATA_ACK=8;
  localparam ARB_LOST=9;
  localparam STOP=10;

  localparam DIVIDE_BY=4;

  reg [7:0] state;
  reg [7:0] saved_addr;
  reg [7:0] saved_data;
  reg [7:0] counter;
  reg [7:0] counter2=0;
  reg write_enable;
  reg sda_out;
  reg i2c_scl_enable=0;
  reg i2c_clk=1;

  assign interrupt = rst?1:0;
  assign ready = ((rst == 0) && (state == IDLE) ) ? 1: 0;
  assign i2c_scl =(i2c_scl_enable == 0)? 'bz : (i2c_clk == 1)?'bz:i2c_clk;
  assign i2c_sda= (write_enable == 1)?((sda_out == 1)?'bz:sda_out):'bz;

  always @(posedge clk) begin
    if(interrupt || rst) begin
      i2c_clk <= 0;
    end
    else begin
      if(counter2 == (DIVIDE_BY/2) -1) begin
      i2c_clk <= ~i2c_clk;
      counter2 <= 0;
    end
    else
      counter2 <= counter2+1;
    end
  end

  always @(negedge i2c_clk, posedge rst) begin
    if(rst == 1) begin
      i2c_scl_enable <= 0;
    end
    else begin
      if((state == IDLE) || (state == START) || (state == STOP) || (state == ARB_LOST)) begin
        i2c_scl_enable <= 0;
      end
      else begin
        i2c_scl_enable <= 1;
      end
    end
  end
  
  always @(posedge i2c_clk, posedge rst) begin
    if(rst == 1) begin
      state <= IDLE;
    end
    else begin
      case(state)
        IDLE: begin
          if(enable && i2c_sda == 1 && i2c_scl == 1) begin
            if(!lines_busy) begin
              state <= START;
              saved_addr <= {addr, rw};
              saved_data <= data_in;
            end
          end
          else
            state <= IDLE;
        end

        START: begin//1
          counter <= 7;
          state <= ADDRESS;
        end
        
        ADDRESS: begin //2
          if(counter == 0) begin
            state <= ADDR_ACK;
          end
          else begin
            if(sda_out == 1 && i2c_sda == 0)
              state <= ARB_LOST;
            else begin
              //counter <= counter-1;
            end
          end
        end

        ACK_WAIT: begin//3
          state <= ADDR_ACK;
        end

        ADDR_ACK: begin//4
          if(i2c_sda == 0) begin
            counter <= 7;
            if(saved_addr[0] == 0) begin
              state <= WRITE_DATA;
            end
            else begin
              state <= READ_DATA;
            end
          end
          else begin
            state<=STOP;
          end
        end

        WRITE_DATA: begin
          if(counter == 0) begin
            state <= SLAVE_DATA_ACK;
          end
          else begin
            if(sda_out == 1 && i2c_sda == 0)
            state <= ARB_LOST;
            else begin
            // counter <= counter-1;
            end
          end
        end

        SLAVE_DATA_ACK: begin
          if((i2c_sda == 0) && (enable == 0))
            state <= STOP;
          else begin
            if((enable == 1) && (i2c_sda == 0)) begin
              saved_data <= data_in;
              state <= WRITE_DATA;
              counter <= 7;
            end
          end
        end

        READ_DATA: begin
          data_out[counter] <= i2c_sda;
          if(counter == 0 )
            state <= MASTER_DATA_ACK;
          else begin
            // counter <= counter-1;
          end
        end

        MASTER_DATA_ACK: begin
          if(enable == 0)
            state <= STOP;
          else begin
            if(enable == 1)begin
              state <= READ_DATA;
              counter <= 7;
            end
          end
        end

        ARB_LOST: begin
          if(!lines_busy)begin
            state <= IDLE;
            counter <= 7;
          end
          else begin
            state <= ARB_LOST;
          end
        end

        STOP: begin
          state <= IDLE;
        end
        
      endcase
    end
  end

  always @(posedge i2c_scl ,posedge rst)begin
   if(rst)begin
     counter <= 7;
    end
    else if(counter == 0)begin

    end
    else begin 
      if ((state == 2||state == 5||state == 7)) begin
        counter <= counter-1;
       end
    end
  end
  
  always @(negedge i2c_clk, posedge rst) begin
    if(rst == 1) begin
       write_enable <= 1;
        sda_out <= 1;
     end
     else begin
       case(state)

         START: begin
           write_enable <= 1;
           sda_out <= 0;
        end
         
         ARB_LOST: begin
            write_enable <= 0;
            sda_out <= 1;
          end
         
          STOP: begin
            write_enable <= 1;
            sda_out <= 1;
            saved_addr <= 8'b11111111;
            $display("saved_addr p", saved_addr);
          end
         
       endcase
     end
  end
  
  always@(negedge i2c_scl,posedge rst)begin
    if(rst) begin
      write_enable <= 1;
      sda_out <= 1;
    end
    else begin
      case(state)
        ADDRESS: begin
          sda_out <= saved_addr[counter];
        end
        ADDR_ACK: begin
          write_enable <= 0;
        end

        WRITE_DATA: begin
          write_enable <= 1;
          sda_out <= saved_data[counter];
        end

        MASTER_DATA_ACK: begin
          write_enable <= 1;
          sda_out <= 0;
        end

        READ_DATA: begin
          write_enable <= 0;
        end

        SLAVE_DATA_ACK: begin
          write_enable <= 0;
        end
        
      endcase
    end
  end
  
endmodule
