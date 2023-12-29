/* Converter between Ibex core interface and Wishbone interface */

`default_nettype none

module core2wb (
   core_if.slave core,
   wb_if.master  wb
);

   logic transaction_ongoing_reg;
   logic wbm_stb_reg;

   initial begin
      wbm_stb_reg = 1'b0;
      transaction_ongoing_reg = 1'b0;
   end

   always_comb begin
      if (!transaction_ongoing_reg) begin
         wb.stb = core.req;
         wb.cyc = core.req;
         core.rvalid = 1'b0;
         core.err = 1'b0;
      end
      else begin
         wb.stb = wb.stall ? wbm_stb_reg : 1'b0;
         wb.cyc = 1'b1;
         core.rvalid = wb.ack;
         core.err = wb.err;
      end
   end

   always_ff @(posedge wb.clk) begin
      if (wb.rst) begin
         wbm_stb_reg <= 1'b0;
         transaction_ongoing_reg <= 1'b0;
      end
      else begin
         if (!transaction_ongoing_reg) begin
            if (core.req) begin
               transaction_ongoing_reg <= 1'b1;
               wbm_stb_reg <= 1'b1;
            end
         end
         else begin
            if (!wb.stall) begin
               wbm_stb_reg <= 1'b0;
               if (wb.ack || wb.err) begin
                  transaction_ongoing_reg <= 1'b0;
               end
            end
         end
      end
   end

   assign core.gnt = ~transaction_ongoing_reg;
`ifdef NO_MODPORT_EXPRESSIONS
   assign core.rdata  = wb.dat_s;
   assign wb.dat_m = core.wdata;
`else
   assign core.rdata  = wb.dat_i;
   assign wb.dat_o = core.wdata;
`endif
   assign wb.adr = core.addr[29:2];
   assign wb.sel = core.we ? core.be : '1;
   assign wb.we = core.we;

endmodule

`resetall
