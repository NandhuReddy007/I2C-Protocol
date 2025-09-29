`include "I2C_slave.v"
`include "I2C_master.v"
module i2c_tb;

  reg clk;
  reg rst;
  reg [6:0] addr1;
  reg [6:0] addr2;
  reg [6:0] s_addr1;
  reg [6:0] s_addr2;
  reg [7:0]data_in1;
  reg[7:0] data_in2;
  reg[7:0] data_slave;
  reg enable1;
  reg enable2;
  reg enable_s1;
  reg enable_s2;
  reg lines_busy=0;
  reg prev_sda, prev_scl;
  reg rw;
  reg interrupt;

  wire [7:0] data_out;
  wire readyl;
  wire ready2;

  wire busy1;
  wire busy2;

  wire i2c_sda;
  wire i2c_scl;

  pullup(i2c_sda);
  pullup(i2c_scl);

  i2c_master master1(.clk(clk), .rst(rst), .addr(addr1), .data_in(data_in1), .enable(enable1), .rw(rw), .lines_busy(lines_busy), .data_out(data_out), .ready(ready1), .i2c_sda(i2c_sda), .i2c_scl(i2c_scl));

  
  //i2c_master master2(.clk(clk), .rst(rst), .addr(addr1), .data_in(data_in2), .enable(enable2), .rw(rw), .lines_busy(lines_busy), .data_out(data_out), .ready(ready2), .i2c_sda(i2c_sda), .i2c_scl(i2c_scl));
  
  i2c_slave1 slave1(.sda(i2c_sda), .scl(i2c_scl), .enable(enable_s1), .data_out(data_slave), .busy(busy1) , .s_addr(s_addr1), .lines_busy(lines_busy), .interrupt(interrupt));

  //i2c_slave1 slave1(.sda(i2c_sda), .scl(i2c_scl), .enable(enable_s2), .data_out(data_slave), .busy(busy2) , .s_addr(s_addr2, .lines_busy(lines_busy), .interrupt(interrupt));

  initial begin
    clk=0;
    forever begin
      clk = #1 ~clk;
    end
  end

  initial begin
    interrupt=0;
    rst=1;
    #100;

    rst=0;
    
    //clock stretching
    addr1 = 7'b0000001;
    s_addr1=7'b0000001;
    enable1=1;
    enable_s1=1;
    rw = 0;
    data_in1 = 8'b11001101;
    wait(master1.state == 5);
    #4
    interrupt=1;
    #24
    interrupt=0;

    wait(master1.state == 8);
    data_in1= 8'b10001111;
    wait(master1.state == 5);
    wait(master1.state == 8);
    #10

    enable1=0;
    enable_s1=0;

    /*
    //2 masters to one slave
    addr2=7'b0000001;
    addr1=7'b0000010;
    s_addrl=7'b0000001;
    rw=0;

    data_inl=8'b11000011;
    data_in2=8'b11001100;
    wait(masterl.state == 8 || master2.state == 8 || masterl.state == 9 || master2.state == 9);
    data_in2=8'b10100101;

    wait(masterl.state == 5 || master2.state == 5 || masterl.state == 9 || master2.state == 9);
    wait(masterl.state == 8 || master2.state == 8 || masterl.state == 9 || master2.state == 9);

    enable=0 ;* /
    
    
    /* 2 slaves to single master with multiple data
    addr1=7'b0000001;//master
    s_addrl =7'b0000001;//slavel
    s_addr2 =7'b0000010;//slave2
    rw = 1;
    data_slave = 8'b01010101;//slave data
    wait(slave2.state == 5||slavel.state == 5);//hold state
    wait(slave2.state == 3||slavel.state == 3);//write state
    data_slave= 8'b11110000;
    wait(slavel.state == 5);

    enable=0 ;*/
    

    /* single master to single slave with multiple data
    addrl = 7'b0000001;
    rw = 1;
    data_slave = 8'b01010101;
    wait(slavel.state == 5);
    wait(slavel.state == 3);
    data_slave= 8'b11110000;
    wait(slavel.state == 5);

    enable=0 ;*/

    // #500
    
    
    $finish;
  end
  
  initial begin
      $dumpfile("dump.vcd"); 
      $dumpvars(1); 
  end
    
endmodule


