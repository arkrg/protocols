// for homework
import apb_pkg::*;  // note that package must be compiled first
class apbSignal;
  rand logic [31:0] addr;
  rand logic [31:0] wdata;
  rand int          slave_id;

  constraint sel_slave_c {slave_id inside {[0 : NUM_SLAVE - 1]};}
  constraint addr_mapping_c {
    (addr % 4 == 0);
    if (slave_id == 0)
    addr inside {[32'h1000_0000 : 32'h1000_0FFF]};
    else
    if (slave_id == 1)
    addr inside {[32'h1000_1000 : 32'h1000_1FFF]};
    else
    if (slave_id == 2)
    addr inside {[32'h1000_2000 : 32'h1000_2FFF]};
    else
    addr inside {[32'h1000_3000 : 32'h1000_3FFF]};
  }

  virtual front_if fif;
  function new(virtual front_if fif);
    this.fif = fif;
  endfunction

  task automatic send();
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

  task automatic recieve();
    fif.transfer <= 1;
    fif.write    <= 0;
    fif.addr     <= addr;
    fif.wdata    <= wdata;
    @(posedge fif.clk);
    fif.transfer <= 0;
    @(posedge fif.clk);
    wait (fif.ready);
    @(posedge fif.clk);
  endtask  //automatic
endclass

module tb_apb ();
  logic PCLK, PRESET;

  // interface
  front_if fif (
      .clk  (PCLK),
      .reset(PRESET)
  );
  apb_if aif (
      .PCLK,
      .PRESET
  );

  // dut instance
  apb_requester dut_requester (
      .fif  (fif),
      .aif_r(aif.requester)
  );
  genvar i;
  generate
    for (i = 0; i < NUM_SLAVE; i++)
    apb_completer #(.SLV_INDEX(i)) dut_completer (.aif_c(aif.completer));
  endgenerate

  // object instance
  apbSignal apbUART;

  initial begin
    int i;
    apbUART = new(fif);
    repeat (3) @(posedge PCLK);
    for (i = 0; i < 10; i++) begin
      apbUART.randomize();
      apbUART.send();
      apbUART.recieve();
    end
    #20;
    $finish;
  end

  // essential : initialize, wave dumping
  initial begin
    PCLK   = 0;
    PRESET = 1;
    #10;
    PRESET = 0;
  end
  always #5 PCLK = ~PCLK;
  initial begin
    $dumpfile("waves.vcd");
    $dumpvars();
  end
endmodule
