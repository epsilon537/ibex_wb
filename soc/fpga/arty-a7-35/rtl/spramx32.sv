/* Single port 32 bit RAM */

`default_nettype none

module spramx32
  #(parameter size       = 'h80,
    parameter addr_width = $clog2(size) - 2,
    parameter init_file  = ""
   )(
    input  wire                     clk,  // clock
    input  wire  [addr_width - 1:0] addr, // address
    input  wire                     ce,   // chip enable
    input  wire  [3:0]              we,   // write enables
    input  wire  [31:0]             d,    // data input
    output logic [31:0]             q);   // data output

   (* ram_decomp = "power" *) logic [31:0] mem[size];

   always @(posedge clk)
     if (ce)
       begin
          if (we[0]) mem[addr][7:0]   <= d[7:0];
          if (we[1]) mem[addr][15:8]  <= d[15:8];
          if (we[2]) mem[addr][23:16] <= d[23:16];
          if (we[3]) mem[addr][31:24] <= d[31:24];
       end

   always_ff @(posedge clk)
     if (ce)
       q <= mem[addr];
       
  if (init_file != "") begin
    initial begin
      $display("Initializing SRAM from %s", init_file);
      $readmemh(init_file, mem);
      $display("Done initializing SRAM from %s", init_file);
    end
  end
   
endmodule

`resetall
