/* Converter between Ibex core interface and Wishbone interface */

`default_nettype none

module core2wb (
    core_if.slave core,
    wb_if.master  wb
);

  import wb_pkg::*;

  logic transaction_ongoing_reg;
  logic wbm_stb_reg, wbm_we_reg;
  dat_t dat_m_reg;
  adr_t adr_reg;
  sel_t sel_reg;

  initial begin
    wbm_stb_reg = 1'b0;
    wbm_we_reg = 1'b0;
    dat_m_reg = 0;
    adr_reg = 0;
    sel_reg = 0;
    transaction_ongoing_reg = 1'b0;
  end

  always_comb begin
    if (!transaction_ongoing_reg) begin
      /* Put new core transactions on the bus right away...*/
      wb.sel = core.we ? core.be : '1;
      wb.adr = core.addr[29:2];
      wb.dat_m = core.wdata;
      wb.we = core.we;
      wb.stb = core.req;
      wb.cyc = core.req;
      core.rvalid = 1'b0;
      core.err = 1'b0;
    end else begin  //A transaction is ongoing...
      /* Extend the asserted signals using their registered counterparts in case the bus is stalled. */
      wb.sel = sel_reg;
      wb.adr = adr_reg;
      wb.dat_m = dat_m_reg;
      wb.we = wbm_we_reg;
      wb.stb = wbm_stb_reg;
      wb.cyc = 1'b1;
      core.rvalid = wb.ack;
      core.err = wb.err;
    end
  end

  always_ff @(posedge wb.clk) begin
    if (wb.rst) begin
      sel_reg <= 0;
      adr_reg <= 0;
      dat_m_reg <= 0;
      wbm_we_reg <= 1'b0;
      wbm_stb_reg <= 1'b0;
      transaction_ongoing_reg <= 1'b0;
    end else begin
      if (!transaction_ongoing_reg) begin
        //If the core issued a new request...
        if (core.req) begin
          transaction_ongoing_reg <= 1'b1;
          wbm_stb_reg <= wb.stall;  //Extend STB if the slave is stalling.
          wbm_we_reg <= core.we;
          dat_m_reg <= core.wdata;
          adr_reg <= core.addr[29:2];
          sel_reg <= core.we ? core.be : '1;
        end
      end else begin  //A transaction is ongoing...
        if (!wb.stall) begin
          wbm_stb_reg <= 1'b0;  //Clear the register STB as soon as the slave stops stalling.
        end
        if (wb.ack || wb.err) begin
          transaction_ongoing_reg <= 1'b0;
        end
      end
    end
  end

  assign core.gnt = ~transaction_ongoing_reg;
`ifdef NO_MODPORT_EXPRESSIONS
  assign core.rdata = wb.dat_s;
`else
  assign core.rdata = wb.dat_i;
  assign wb.dat_o   = core.wdata;
`endif

endmodule

`resetall
