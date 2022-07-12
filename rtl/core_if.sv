/* Core interface */

`default_nettype none

// verilator lint_off UNUSED
interface core_if
  (input wire clk,    //FIXME: clk and rst_n are not used so far. Should I hang on to them?
   input wire rst_n);

   logic        req;
   logic        gnt;
   logic        rvalid;
   logic        we;
   logic [3:0]  be;
   logic [31:0] addr;
   logic [31:0] wdata;
   logic [31:0] rdata;
   logic        err;

   modport master
     (input  clk,
      input  rst_n,
      output req,
      input  gnt,
      input  rvalid,
      output we,
      output be,
      output addr,
      output wdata,
      input  rdata,
      input  err);

   modport slave
     (input  clk,
      input  rst_n,
      input  req,
      output gnt,
      output rvalid,
      input  we,
      input  be,
      input  addr,
      input  wdata,
      output rdata,
      output err);

   modport monitor
     (input  clk,
      input  rst_n,
      input  req,
      input  gnt,
      input  rvalid,
      input  we,
      input  be,
      input  addr,
      input  wdata,
      input  rdata,
      input  err);
endinterface
// verilator lint_on UNUSED
`resetall
