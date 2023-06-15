/* Single port 32 bit RAM with Wishbone interface */

`default_nettype none

module wb_spramx32
  #(parameter size = 'h80,
    parameter init_file = ""
   )
   (wb_if.slave wb);

   localparam addr_width = $clog2(size) - 2;

   logic                    valid;
   logic [addr_width - 1:0] ram_addr;     // RAM address
   logic                    ram_ce;
   logic [3:0]              ram_we;
   logic [31:0]             ram_d;
   logic [31:0]             ram_q;

`ifdef VERILATOR
   spramx32
     #(.size(size),
       .init_file(init_file))
   spram
     (.clk  (wb.clk),
      .addr (ram_addr),
      .ce   (ram_ce),
      .we   (ram_we),
      .d    (ram_d),
      .q    (ram_q));
`else
/*On the Arty, use XPM memory instances. When Vivado synthesizes an XPM memory instance, it produces a .mmi file for that memory.
 *This .mmi file can be used for post-implementation updates of the memory contents in the FPGA bitstream.*/
xpm_memory_spram #(
   .ADDR_WIDTH_A(addr_width),              // DECIMAL
   .AUTO_SLEEP_TIME(0),           // DECIMAL
   .BYTE_WRITE_WIDTH_A(8),       // DECIMAL
   .ECC_MODE("no_ecc"),           // String
   .MEMORY_INIT_PARAM("0"),       // String
   .MEMORY_OPTIMIZATION("true"),  // String
   .MEMORY_PRIMITIVE("auto"),     // String
   .MEMORY_SIZE(size*8),          // DECIMAL, memory size in bits
   .MESSAGE_CONTROL(0),           // DECIMAL
   .READ_DATA_WIDTH_A(32),        // DECIMAL
   .READ_LATENCY_A(1),            // DECIMAL
   .READ_RESET_VALUE_A("0"),      // String
   .USE_MEM_INIT(1),              // DECIMAL
   .WAKEUP_TIME("disable_sleep"), // String
   .WRITE_DATA_WIDTH_A(32),       // DECIMAL
   .WRITE_MODE_A("read_first")    // String
)
xpm_memory_spram_inst (
   .dbiterra(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                    // on the data output of port A.

   .douta(ram_q),                   // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
   .sbiterra(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                    // on the data output of port A.

   .addra(ram_addr),                   // ADDR_WIDTH_A-bit input: Address for port A write and read operations.
   .clka(wb.clk),                     // 1-bit input: Clock signal for port A.
   .dina(ram_d),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
   .ena(ram_ce),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                    // cycles when read or write operations are initiated. Pipelined
                                    // internally.

   .injectdbiterra(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                    // ECC enabled (Error injection capability is not available in
                                    // "decode_only" mode).

   .injectsbiterra(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                    // ECC enabled (Error injection capability is not available in
                                    // "decode_only" mode).

   .regcea(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
                                    // data path.

   .rsta(wb.rst),                     // 1-bit input: Reset signal for the final port A output register stage.
                                    // Synchronously resets output port douta to the value specified by
                                    // parameter READ_RESET_VALUE_A.

   .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
   .wea(ram_we)                        // WRITE_DATA_WIDTH_A-bit input: Write enable vector for port A input
                                    // data port dina. 1 bit wide when word-wide writes are used. In
                                    // byte-wide write configurations, each bit controls the writing one
                                    // byte of dina to address addra. For example, to synchronously write
                                    // only bits [15-8] of dina when WRITE_DATA_WIDTH_A is 32, wea would be
                                    // 4'b0010.
);
`endif

   assign ram_addr = wb.adr[addr_width + 1 : 2];
   assign ram_ce   = valid;
   assign ram_we   = {4{wb.we}} & wb.sel;
`ifdef NO_MODPORT_EXPRESSIONS   
   assign ram_d    = wb.dat_m;
   assign wb.dat_s = ram_q;
`else
   assign ram_d    = wb.dat_i;   
   assign wb.dat_o = ram_q;
`endif   
   /* Wishbone control */
   assign valid    = wb.cyc & wb.stb;
   assign wb.stall = 1'b0;
   assign wb.err   = 1'b0;

   always_ff @(posedge wb.clk)
     if (wb.rst)
       wb.ack <= 1'b0;
     else
       wb.ack <= valid & ~wb.stall;
endmodule

`resetall
