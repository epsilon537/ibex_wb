/* Converter between Ibex core interface and Wishbone interface */

`default_nettype none

module core2wb (
    core_if.slave core,
    wb_if.master  wb
);

  import wb_pkg::*;

  core2wb_no_ifs core2wb_no_ifs_inst (
      .clk(wb.clk),
      .rst(wb.rst),
      .core_req_i(core.req),
      .core_gnt_o(core.gnt),
      .core_rvalid_o(core.rvalid),
      .core_we_i(core.we),
      .core_be_i(core.be),
      .core_addr_i(core.addr),
      .core_wdata_i(core.wdata),
      .core_rdata_o(core.rdata),
      .core_err_o(core.err),

      .wb_ack_i(wb.ack),
      .wb_adr_o(wb.adr),
      .wb_cyc_o(wb.cyc),
      .wb_stall_i(wb.stall),
      .wb_stb_o(wb.stb),
      .wb_we_o(wb.we),
      .wb_sel_o(wb.sel),
      .wb_err_i(wb.err),
      .wb_dat_s_i(wb.dat_s),
      .wb_dat_m_o(wb.dat_m)
  );

endmodule

`resetall
