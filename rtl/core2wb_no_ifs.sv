/* Converter between Ibex core interface and Wishbone interface */

`ifdef __ICARUS__
`timescale 1 ns / 1 ps
`endif

module core2wb_no_ifs (
    input logic clk,
    input logic rst,
    input logic core_req_i,
    output logic core_gnt_o,
    output logic core_rvalid_o,
    input logic core_we_i,
    input logic [3:0] core_be_i,
    input logic [31:0] core_addr_i,
    input logic [31:0] core_wdata_i,
    output logic [31:0] core_rdata_o,
    output logic core_err_o,

    input logic wb_ack_i,
    output logic [27:0] wb_adr_o,
    output logic wb_cyc_o,
    input logic wb_stall_i,
    output logic wb_stb_o,
    output logic wb_we_o,
    output logic [3:0] wb_sel_o,
    input logic wb_err_i,
    input logic [31:0] wb_dat_s_i,
    output logic [31:0] wb_dat_m_o
);

  logic unused = &{core_addr_i[31:30], core_addr_i[1:0]};

  logic transaction_ongoing_reg;
  logic wbm_stb_reg, wbm_we_reg;
  logic [31:0] dat_m_reg;
  logic [27:0] adr_reg;
  logic [ 3:0] sel_reg;

  initial begin
    wbm_stb_reg = 1'b0;
    wbm_we_reg = 1'b0;
    dat_m_reg = 0;
    adr_reg = 0;
    sel_reg = 0;
    transaction_ongoing_reg = 1'b0;
  end

  logic [3:0] wb_sel;
  logic [27:0] wb_adr;
  logic [31:0] wb_dat_m;
  logic wb_we;
  logic wb_stb;
  logic wb_cyc;
  logic core_rvalid;
  logic core_err;

  always_comb begin
    if (!transaction_ongoing_reg) begin
      /* Put new core transactions on the bus right away...*/
      wb_sel = core_we_i ? core_be_i : 4'b1111;
      wb_adr = core_addr_i[29:2];
      wb_dat_m = core_wdata_i;
      wb_we = core_we_i;
      wb_stb = core_req_i;
      wb_cyc = core_req_i;
      core_rvalid = 1'b0;
      core_err = 1'b0;
    end else begin  //A transaction is ongoing...
      /* Extend the asserted signals using their registered counterparts in case the bus is stalled. */
      wb_sel = sel_reg;
      wb_adr = adr_reg;
      wb_dat_m = dat_m_reg;
      wb_we = wbm_we_reg;
      wb_stb = wbm_stb_reg;
      wb_cyc = 1'b1;
      core_rvalid = wb_ack_i;
      core_err = wb_err_i;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      sel_reg <= 0;
      adr_reg <= 0;
      dat_m_reg <= 0;
      wbm_we_reg <= 1'b0;
      wbm_stb_reg <= 1'b0;
      transaction_ongoing_reg <= 1'b0;
    end else begin
      if (!transaction_ongoing_reg) begin
        //If the core issued a new request...
        if (core_req_i) begin
          transaction_ongoing_reg <= 1'b1;
          wbm_stb_reg <= wb_stall_i;  //Extend STB if the slave is stalling.
          wbm_we_reg <= core_we_i;
          dat_m_reg <= core_wdata_i;
          adr_reg <= core_addr_i[29:2];
          sel_reg <= core_we_i ? core_be_i : 4'b1111;  //'1 means all bits set.
        end
      end else begin  //A transaction is ongoing...
        if (!wb_stall_i) begin
          wbm_stb_reg <= 1'b0;  //Clear the register STB as soon as the slave stops stalling.
        end
        if (wb_ack_i || wb_err_i) begin
          transaction_ongoing_reg <= 1'b0;
        end
      end
    end
  end

  assign wb_sel_o = wb_sel;
  assign wb_adr_o = wb_adr;
  assign wb_dat_m_o = wb_dat_m;
  assign wb_we_o = wb_we;
  assign wb_stb_o = wb_stb;
  assign wb_cyc_o = wb_cyc;
  assign core_rvalid_o = core_rvalid;
  assign core_err_o = core_err;

  assign core_gnt_o = core_req_i & ~transaction_ongoing_reg;
  assign core_rdata_o = wb_dat_s_i;

endmodule

`resetall
