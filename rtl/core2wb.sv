/* Converter between Ibex core interface and Wishbone interface */

`default_nettype none

module core2wb
  (core_if.slave core,
   wb_if.master  wb);

   logic [31:0] wdata;
   logic [3:0]  sel;
   logic        we;
   logic [31:0] adr;
   logic transaction_ongoing;
   logic stb;

   assign core.rvalid = wb.ack & transaction_ongoing;
   assign core.gnt = ~transaction_ongoing;
   assign core.err = wb.err & transaction_ongoing;
`ifdef NO_MODPORT_EXPRESSIONS
   assign core.rdata  = wb.dat_s;
`else
   assign core.rdata  = wb.dat_i;
`endif

   initial transaction_ongoing = 1'b0;
   initial stb = 1'b0;

   /*One transfer per WB CYC bus cycle.*/

   always_ff @(posedge wb.clk)
     if (wb.rst) begin
        transaction_ongoing <= 1'b0;
        stb <= 1'b0;
     end
     else
       if (transaction_ongoing) begin
          if (!wb.stall)
            stb <= 1'b0; /*pipelined WB. For one transaction STB should only be high for one cycle after master has been granted access (through !stall).*/

          if (wb.ack || wb.err) begin
             transaction_ongoing <= 1'b0;
             stb <= 1'b0;
          end
       end
       else begin
          if (core.req) begin
             transaction_ongoing <= 1'b1;
             stb <= 1'b1;
             wdata <= core.wdata;
             adr <= core.addr;
             sel <= core.we ? core.be : '1;
             we <= core.we;
          end
       end

   assign wb.cyc = transaction_ongoing;
   assign wb.stb = stb;
   assign wb.adr = adr;
   assign wb.we = we;
   assign wb.sel = sel;
`ifdef NO_MODPORT_EXPRESSIONS
   assign wb.dat_m    = wdata;
`else
   assign wb.dat_o    = wdata;
`endif

endmodule

`resetall
