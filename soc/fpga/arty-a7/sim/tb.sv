/* Testbench */

`default_nettype none

module tb;
  timeunit 1ns / 1ps;

  const realtime       tclk = 1s / 100.0e6;

  bit                  clk100mhz;
  wire           [7:0] gpio0;
  wire           [3:0] gpio1;
  bit            [3:0] sw;
  wire           [3:0] led;
  bit            [3:0] btn;
  bit                  ck_rst_n;
  wire                 uart_rx;
  wire                 uart_tx;
  bit                  tck;
  bit                  trst_n;
  bit                  tms;
  bit                  tdi;
  wire                 tdo;





  //glbl glbl();
  ibex_soc dut (.*);

  always #(tclk / 2) clk100mhz = ~clk100mhz;

`ifdef ASSERT_ON
  bind dut wb_checker wbm0_checker (wbm[0]);
  bind dut wb_checker wbm1_checker (wbm[1]);
  bind dut wb_checker wbs0_checker (wbs[0]);
  bind dut wb_checker wbs1_checker (wbs[1]);
`endif

  initial begin : main
    //string filename;
    //int    status;

    //$timeformat(-9, 3, " ns");

    //status = $value$plusargs("filename=%s", filename);
    //chk_filename: assert(status) else $fatal(1, "No memory file provided. Please use './simv '+filename=<file.vmem>");
    //$readmemh(filename, tb.dut.wb_spram.spram.mem);

    repeat (3) @(negedge clk100mhz);
    ck_rst_n = 1'b1;

    #33ms $finish;
  end : main
endmodule

`resetall
