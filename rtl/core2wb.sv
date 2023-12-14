/* Converter between Ibex core interface and Wishbone interface */

`default_nettype none

module core2wb (
   core_if.slave core,
   wb_if.master  wb);

   logic [31:0] wdata;
   logic [3:0]  sel;
   logic        we;
   logic [27:0] adr;
   logic transaction_ongoing;
   logic stb;

   //read data is valid when we have a transaction ongoing and the slave asserts ack.
   assign core.rvalid = wb.ack & transaction_ongoing;

   //We don't allow multiple outstanding transactions. We deassert the grant signal as soon as a transaction is ongoing.
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
          /*pipelined WB: During a transaction STB should only be high for one clock cycle 
           *after master has been granted access by WB slave or WB interconnect  (through !stall).
           *As long as we're stalled, STB remains asserted.*/
          if (!wb.stall)
            stb <= 1'b0; 

          /*We don't do multiple transfers per transaction. A transaction ends when WB ack or
           *error is received, i.e. when the slave has accepted (or errored) the write data or
           *returned the read data.*/
          if (wb.ack || wb.err) begin
             transaction_ongoing <= 1'b0;
             stb <= 1'b0;
          end
       end
       else begin
          /*Ibex core.req indicates the CPU wants to initiate a transaction.*/
          if (core.req) begin
            /*Register the relevant signals so they hold their data for as long as we want to
             *for the purpose of this adapter.*/
             transaction_ongoing <= 1'b1;
             stb <= 1'b1;
             wdata <= core.wdata;
             adr <= core.addr[29:2];
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
