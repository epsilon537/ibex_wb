/* Converter between DM slave interface and Wishbone interface */

`default_nettype none

module slave2wb
  (core_if.master slave,
   wb_if.slave    wb);

   logic valid;

   assign valid       = wb.cyc & wb.stb;
   assign slave.req   = valid;
   assign slave.we    = wb.we;
   assign slave.addr  = {2'b00, wb.adr, 2'b00};
   
   assign slave.be    = wb.sel;
`ifdef NO_MODPORT_EXPRESSIONS   
   assign slave.wdata = wb.dat_m;
   assign wb.dat_s    = slave.rdata;
`else
   assign slave.wdata = wb.dat_i;
   assign wb.dat_o    = slave.rdata;
`endif
   assign wb.stall    = ~slave.gnt;
   assign wb.err      = slave.err;

   always_ff @(posedge wb.clk)
     if (wb.rst)
       wb.ack <= 1'b0;
     else
       wb.ack <= valid & ~wb.stall;
endmodule

`resetall
