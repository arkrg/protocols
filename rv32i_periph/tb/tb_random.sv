import apb_pkg::*;  // note that package must be compiled first
class apbSignal;
  rand logic [31:0] addr;
  rand logic [31:0] wdata;
  // int               completer_id;
  randc int         completer_id;
  randc int         reg_id;

  // constraint sel_completer_c {completer_id inside {[0 : NUM_COMP - 1]};}
  // constraint sel_reg_c {reg_id inside {[0 : 3]};}
  constraint sel_completer_c {completer_id == 5;}
  constraint sel_reg_c {reg_id inside {[0 : 3]};}
  constraint addr_mapping_c {
    // if (completer_id == 0)
    // addr inside {[32'h1000_0000 : 32'h1000_0FFF]};
    // else
    // if (completer_id == 1)
    // addr inside {[32'h1000_1000 : 32'h1000_1FFF]};
    // else
    // if (completer_id == 2)
    // addr inside {[32'h1000_2000 : 32'h1000_2FFF]};
    // else
    // addr inside {[32'h1000_3000 : 32'h1000_3FFF]};
    addr[3:2] == reg_id;
    addr % 4 == 0;
  }

  virtual front_if fif;
  function new(virtual front_if fif);
    this.fif = fif;
  endfunction

  task automatic rsend();
    apbSignal.randomize();
    fif.transfer <= 1;
    fif.write    <= 1;
    fif.addr     <= addr;
    fif.wdata    <= wdata;
    @(posedge fif.clk);
    fif.transfer <= 0;
    @(posedge fif.clk);
    wait (fif.ready);
    @(posedge fif.clk);
  endtask  //automatic

  task automatic dsend(logic [31:0] addr, logic [31:0] wdata);
    fif.transfer <= 1;
    fif.write    <= 1;
    fif.addr     <= addr;
    fif.wdata    <= wdata;
    @(posedge fif.clk);
    fif.transfer <= 0;
    @(posedge fif.clk);
    wait (fif.ready);
    @(posedge fif.clk);
  endtask  //automatic

  task automatic recieve(logic [31:0] addr);
    fif.transfer <= 1;
    fif.write    <= 0;
    fif.addr     <= addr;
    @(posedge fif.clk);
    fif.transfer <= 0;
    @(posedge fif.clk);
    wait (fif.ready);
    @(posedge fif.clk);

  endtask  //automatic
endclass
//
module tb_basic ();
  logic clk, reset;
  logic tx, rx;
  logic [7:0] DLL, DLH;
  localparam int SYS_FREQ = 100_000_000;
  localparam int OVS = 16;
  localparam int BRATE = 9600;
  localparam int DIVISOR = SYS_FREQ / OVS / BRATE;

  assign {DLH, DLL} = DIVISOR;

  // interface
  front_if fif (
      .clk,
      .reset
  );
  apb_if aif (
      .PCLK(clk),
      .PRESETn(~reset)
  );
  assign aif.PSELC = aif.PSELR[4];

  apb_requester vip_requester (
      .fif  (fif),
      .aif_r(aif.requester)
  );
  // dut instance
  apb_uart_periph dut (
      .apb_c(aif.completer),
      .rx,
      .tx
  );

  // object instance
  apbSignal apbUART;

  initial begin
    int i;
    apbUART = new(fif);
    repeat (3) @(posedge clk);
    // for (i = 0; i < 100; i++) begin
    // apbUART.randomize();
    apbUART.send(32'h1000_400C, 32'h0000_0080);  // DLAB = 1;
    apbUART.send(32'h1000_4004, {24'h0, DLH});  // DLH write;
    apbUART.send(32'h1000_4000, {24'h0, DLL});  // DLL write;

    // apbUART.send(32'h1000_400C, 32'h0000_0080);  // DLAB = 1;
    // apbUART.send(32'h1000_4004, {24'h0, DLH});  // DLH write;
    // apbUART.send(32'h1000_4000, {24'h0, DLL});  // DLL write;
    // apbUART.recieve(32'h1000_400C);  // DLAB = 1;
    // end
    #20;
    $finish;
  end

  // essential : initialize, wave dumping
  initial begin
    clk   = 0;
    reset = 1;
    #10;
    reset = 0;
  end
  always #5 clk = ~clk;
  initial begin
    $dumpfile("waves.vcd");
    $dumpvars();
  end
endmodule
