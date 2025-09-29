module i2c_slave1(
  inout sda,
  inout scl,
  input enable,
  input lines_busy,
  input [6:0] s_addr,
  input [7:0] data_out,
  output wire busy,
  input interrupt);

  localparam READ_ADDR=0;
  localparam ADDR_ACK=1;
  localparam READ_DATA=2;
  localparam WRITE_DATA=3;
  localparam DATA_ACK=4;
  localparam DATA_REPEAT=5;

  reg [7:0] addr;
  reg [7:0] counter;
  reg [7:0] state=0;
  reg [7:0] data_in=0;
  reg sda_out=0;
  reg sda_in=0;
  reg start=0;
  reg write_enable=0;

  assign busy = ((state>1)) ? 1: 0;
  assign sda= (write_enable == 1)? sda_out : 'bz;
  assign scl = interrupt? 1'b0 : 'bz;

  always @(negedge sda) begin
    if((start == 0) && (scl == 1)) begin
      start <= 1;
      counter <= 7;
    end
  end
  
  always@(*)begin
    if(!lines_busy)begin
      state <= 0;
      counter <= 7;
    end
  end

  always @(posedge scl) begin
    if(start == 1) begin
      case (state)
      READ_ADDR: begin
          if(enable)begin
            addr[counter] <= sda;
            if(counter == 0) begin
              state <= ADDR_ACK;
            end
          else
            counter <= counter-1;
          end
      end
        
      ADDR_ACK:begin
        if(addr[7:1] == s_addr && enable) begin
          counter <= 7;
          if(addr[0] == 0) begin
            state <= READ_DATA;
          end
          else begin
            state <= WRITE_DATA;
          end
          end
        else begin
          if(!lines_busy )begin
            state <= READ_ADDR;
            counter <= 7;
          end
        end
      end
        
      READ_DATA: begin
        data_in[counter] <= sda;
        if(counter == 0) begin
          state <= DATA_ACK;
        end
        else
          counter <= counter-1;
      end

      DATA_ACK: begin
        if(enable == 1) begin
          state <= READ_DATA;
          counter <= 7;
        end
        else begin
          state <= READ_ADDR;
        end
      end

      WRITE_DATA: begin
        if(counter == 0 && enable == 0)
          state <= READ_ADDR;
        else if(counter == 0 && enable == 1) begin
          state <= DATA_REPEAT;
        end
        else
          counter <= counter-1;
      end

      DATA_REPEAT: begin
        state <= WRITE_DATA;
        counter <= 7;
      end
        
      endcase
    end
  end
  
  always @(negedge scl) begin
    case (state)

      READ_ADDR: begin
        write_enable <= 0;
      end

      ADDR_ACK: begin
        sda_out <= 0;
        if(addr[7:1] == s_addr && enable) begin
          write_enable <= 1;
        end
        else
          write_enable <= 0;
      end

      READ_DATA: begin
        write_enable <= 0;
      end

      WRITE_DATA: begin
        sda_out <= data_out[counter];
        write_enable <= 1;
      end

      DATA_ACK: begin
        sda_out <= 0;
        write_enable <= 1;
      end

      DATA_REPEAT: begin
        write_enable <= 0;
      end
      
    endcase
  end
  
endmodule
