//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/30/2019 10:24:14 PM
// Design Name:
// Module Name: wb_gpio
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`default_nettype none

module wb_gpio #(
    parameter size = 32
) (
    inout wire        [size-1:0] gpio,
          wb_if.slave            wb
);

  logic unused = &{1'b0, wb.adr[27:2], wb.sel, 1'b0};

  logic [size-1:0] input_reg;
  logic [size-1:0] output_reg    = 'b0;
  logic [size-1:0] direction_reg = 'b0;

  for (genvar i = 0; i < size; i = i + 1) begin
    assign gpio[i] = direction_reg[i] ? output_reg[i] : 1'bz;
    assign input_reg[i] = direction_reg[i] ? 1'b0 : gpio[i];
  end

  logic valid;
  assign valid = wb.cyc && wb.stb;

  assign wb.stall = 1'b0;
  assign wb.err = 1'b0;

  always_ff @(posedge wb.clk)
    if (wb.rst) begin
      direction_reg <= '0;
      output_reg <= '0;
      wb.ack <= 1'b0;
`ifdef NO_MODPORT_EXPRESSIONS
      wb.dat_s <= '0;
`else
      wb.dat_o <= '0;
`endif
    end else if (valid) begin
      wb.ack <= ~wb.stall;
      if (wb.we)
        case (wb.adr[1:0])
`ifdef NO_MODPORT_EXPRESSIONS
          2'h1:    output_reg <= wb.dat_m[size-1:0];
          2'h2:    direction_reg <= wb.dat_m[size-1:0];
`else
          2'h1:    output_reg <= wb.dat_i[size-1:0];
          2'h2:    direction_reg <= wb.dat_i[size-1:0];
`endif
          default: ;
        endcase
      else
        case (wb.adr[1:0])
`ifdef NO_MODPORT_EXPRESSIONS
          2'h0:    wb.dat_s <= 32'(input_reg);
          2'h1:    wb.dat_s <= 32'(output_reg);
          2'h2:    wb.dat_s <= 32'(direction_reg);
`else
          2'h0:    wb.dat_o <= 32'(input_reg);
          2'h1:    wb.dat_o <= 32'(output_reg);
          2'h2:    wb.dat_o <= 32'(direction_reg);
`endif
          default: ;
        endcase
    end else wb.ack <= 1'b0;

endmodule

`resetall
