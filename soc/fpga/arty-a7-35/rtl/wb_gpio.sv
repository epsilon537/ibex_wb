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
  )(
    inout wire [size-1:0] gpio,
    wb_if.slave           wb
  );

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
    end
    else 
      if (valid) begin
	 wb.ack <= ~wb.stall;
	 if (wb.we)
           case (wb.adr[3:0])
`ifdef NO_MODPORT_EXPRESSIONS
             4'h4 : output_reg    <= wb.dat_m[size-1:0];
             4'h8 : direction_reg <= wb.dat_m[size-1:0];
`else	  
             4'h4 : output_reg    <= wb.dat_i[size-1:0];
             4'h8 : direction_reg <= wb.dat_i[size-1:0];
`endif	  
             default         : ;
           endcase
	 else
           case (wb.adr[3:0])
`ifdef NO_MODPORT_EXPRESSIONS	  
             4'h0 : wb.dat_s <= input_reg;
             4'h4 : wb.dat_s <= output_reg;
             4'h8 : wb.dat_s <= direction_reg;
`else
             4'h0 : wb.dat_o <= input_reg;
             4'h4 : wb.dat_o <= output_reg;
             4'h8 : wb.dat_o <= direction_reg;	  
`endif
             default         : ;	  
           endcase
      end
      else
	wb.ack <= 1'b0;
   
endmodule

`resetall
