import apb_pkg::*; // note that package must be compiled first
interface front_if (
    input logic clk,
    input logic reset
);
    logic                  transfer;
    logic                  write;
    logic [          31:0] addr;
    logic [DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH-1:0] rdata;
    logic                  ready;
endinterface  //front_if

interface apb_if (
    input logic PCLK,
    input logic PRESET
);
    logic [ADDR_WIDTH-1:0] PADDR;
    logic [ NUM_SLAVE-1:0] PSEL;
    logic                  PENABLE;
    logic                  PWRITE;
    logic [DATA_WIDTH-1:0] PWDATA;
    logic                  PREADY;
    logic [DATA_WIDTH-1:0] PRDATA;

    modport requester(
        input PCLK,
        input PRESET,
        output PADDR,
        output PSEL,
        output PENABLE,
        output PWRITE,
        output PWDATA,
        input PREADY,
        input PRDATA
    );
    modport completer(
        input PCLK,
        input PRESET,
        input PADDR,
        input PSEL,
        input PENABLE,
        input PWRITE,
        input PWDATA,
        output PREADY,
        output PRDATA
    );

endinterface
