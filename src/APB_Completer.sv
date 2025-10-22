module APB_Completer (
    // global Signals
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic        PWRITE,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY
);

    logic [31:0] slv_reg[4];
    logic [31:0] r_PRDATA;
    logic r_PREADY;

    wire PSEL_AND_PENABLE = PSEL & PENABLE;

    always_ff @(posedge PCLK, posedge PRESET) begin 
        if (PRESET) begin
            slv_reg[0] <= 0;
            slv_reg[1] <= 0;
            slv_reg[2] <= 0;
            slv_reg[3] <= 0;

            r_PRDATA <= 0;
            r_PREADY <= 0;
        end else begin
            r_PREADY <= 1'b0;
            if (PSEL_AND_PENABLE) begin
                r_PREADY <= 1;
                if (PWRITE) begin
                    // WRITE Transaction
                    slv_reg[PADDR[3:2]] <= PWDATA;
                end else begin
                    // READ Transaction
                    r_PRDATA <= slv_reg[PADDR[3:2]];
                end
            end
        end
    end

    assign PREADY = (PSEL_AND_PENABLE) ? r_PREADY : 1'bz;
    assign PRDATA = (PSEL_AND_PENABLE & PREADY) ? r_PRDATA : 32'bz;
endmodule
