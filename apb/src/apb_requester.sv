import apb_pkg::*;
module apb_requester (
    apb_if.requester aif_r,
    front_if         fif
);
  logic                  PCLK;
  logic                  PRESET;
  logic [ADDR_WIDTH-1:0] PADDR;
  logic                  PWRITE;
  logic                  PENABLE;
  logic [DATA_WIDTH-1:0] PWDATA;
  logic [           3:0] PSEL;
  logic                  PREADY;
  logic [DATA_WIDTH-1:0] PRDATA;
  logic                  transfer;
  logic                  write;
  logic [          31:0] addr;
  logic [DATA_WIDTH-1:0] wdata;
  logic [DATA_WIDTH-1:0] rdata;
  logic                  ready;

  assign PCLK          = aif_r.PCLK;
  assign PRESET        = aif_r.PRESET;
  assign aif_r.PADDR   = PADDR;
  assign aif_r.PWRITE  = PWRITE;
  assign aif_r.PENABLE = PENABLE;
  assign aif_r.PWDATA  = PWDATA;
  assign aif_r.PSEL    = PSEL;
  assign PREADY        = aif_r.PREADY;
  assign PRDATA        = aif_r.PRDATA;

  assign transfer      = fif.transfer;
  assign write         = fif.write;
  assign addr          = fif.addr;
  assign wdata         = fif.wdata;
  assign rdata         = fif.rdata;
  assign ready         = fif.ready;
  assign fif.rdata     = PRDATA;
  assign fif.ready     = PREADY;

  logic decoder_en;
  logic temp_write_reg, temp_write_next;
  logic [ADDR_WIDTH-1:0] temp_addr_reg, temp_addr_next;
  logic [DATA_WIDTH-1:0] temp_wdata_reg, temp_wdata_next;
  logic [3:0] pselx;

  assign PSEL = pselx;

  typedef enum {
    IDLE,
    SETUP,
    ACCESS
  } apb_state_e;

  apb_state_e state, next_state;

  always_ff @(posedge PCLK, posedge PRESET) begin
    if (PRESET) begin
      state          <= IDLE;
      temp_write_reg <= 0;
      temp_addr_reg  <= 0;
      temp_wdata_reg <= 0;
    end else begin
      state          <= next_state;
      temp_write_reg <= temp_write_next;
      temp_addr_reg  <= temp_addr_next;
      temp_wdata_reg <= temp_wdata_next;
    end
  end

  always_comb begin
    next_state      = state;
    temp_write_next = temp_write_reg;
    temp_addr_next  = temp_addr_reg;
    temp_wdata_next = temp_wdata_reg;
    decoder_en      = 1'b0;
    PENABLE         = 1'b0;
    PADDR           = temp_addr_reg;
    PWRITE          = temp_write_reg;
    PWDATA          = temp_wdata_reg;
    case (state)
      IDLE: begin
        decoder_en = 1'b0;
        if (transfer) begin
          next_state      = SETUP;
          temp_write_next = write;
          temp_addr_next  = addr;
          temp_wdata_next = wdata;
        end
      end
      SETUP: begin
        decoder_en = 1'b1;
        PENABLE    = 1'b0;
        PADDR      = temp_addr_reg;
        PWRITE     = temp_write_reg;
        next_state = ACCESS;
        if (temp_write_reg) begin
          PWDATA = temp_wdata_reg;
        end
      end
      ACCESS: begin
        decoder_en = 1'b1;
        PENABLE    = 1'b1;
        if (!transfer & ready) begin
          next_state = IDLE;
        end else if (transfer & ready) begin
          next_state = SETUP;
        end else begin
          next_state = ACCESS;
        end
      end
    endcase
  end

  apb_decoder U_APB_DECODER (
      .en (decoder_en),
      .sel(temp_addr_reg),
      .y  (pselx)
  );


endmodule

module apb_decoder (
    input  logic                  en,
    input  logic [DATA_WIDTH-1:0] sel,
    output logic [           3:0] y
);
  always_comb begin
    y = 4'b0000;
    if (en) begin
      casex (sel)
        32'h1000_0xxx: y = 4'b0001;  // RAM
        32'h1000_1xxx: y = 4'b0010;  // P1
        32'h1000_2xxx: y = 4'b0100;  // P2
        32'h1000_3xxx: y = 4'b1000;  // P3
      endcase
    end
  end
endmodule
