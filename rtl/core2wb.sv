/* Converter between Ibex core interface and Wishbone interface */

`default_nettype none

module core2wb
  (core_if.slave core,
   wb_if.master  wb);

   logic cyc;

   assign core.gnt    = core.req & ~wb.stall;
   assign core.rvalid = wb.ack;
   assign core.err    = wb.err;
`ifdef NO_MODPORT_EXPRESSIONS   
   assign core.rdata  = wb.dat_s;
`else
   assign core.rdata  = wb.dat_i;   
`endif   
   assign wb.stb      = core.req;
   assign wb.adr      = core.addr;
`ifdef NO_MODPORT_EXPRESSIONS
   assign wb.dat_m    = core.wdata;
`else
   assign wb.dat_o    = core.wdata;
`endif
   assign wb.we       = core.we;
   assign wb.sel      = core.we ? core.be : '1;

   always_ff @(posedge wb.clk)
     if (wb.rst)
       cyc <= 1'b0;
     else
       if (core.req)
         cyc <= 1'b1;
       else if (wb.ack || wb.err)
         cyc <= 1'b0;

   assign wb.cyc = core.req | cyc;
endmodule

`resetall
