//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/13/2020 05:06:15 PM
// Design Name: 
// Module Name: wb_timer
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

module wb_timer(
    wb_if.slave wb
    );
    
    logic [31:0] control_reg = 'b0;
    logic [31:0] counter_reg = 'b0;
    
    logic valid;
    assign valid = wb.cyc && wb.stb;
    
    assign wb.stall = 1'b0;
    assign wb.err = 1'b0;
    
    always @(posedge wb.clk)
        if (wb.rst) begin
            control_reg <= '0;
            counter_reg <= '0;
`ifdef NO_MODPORT_EXPRESSIONS	   
	    wb.dat_s <= '0;
`else
	    wb.dat_o <= '0;
`endif	   
        end
        else begin
            if (valid)
                if (wb.we)
                    case (wb.adr[2:0])
`ifdef NO_MODPORT_EXPRESSIONS
                        3'h0 : control_reg <= wb.dat_m;
                        3'h4 : counter_reg <= wb.dat_m;		      
`else		      
                        3'h0 : control_reg <= wb.dat_i;
                        3'h4 : counter_reg <= wb.dat_i;
`endif		      
                        default : ;
                    endcase
                else
                    case (wb.adr[2:0])
`ifdef NO_MODPORT_EXPRESSIONS		      
                        3'h0 : wb.dat_s <= control_reg;
                        3'h4 : wb.dat_s <= counter_reg;
`else
                        3'h0 : wb.dat_o <= control_reg;
                        3'h4 : wb.dat_o <= counter_reg;		      
`endif		      
                        default : ;
                    endcase
                    
            if (~(wb.we & valid))
                if (control_reg[1]) begin
                    counter_reg <= 'b0;
                    control_reg[1] <= 'b0;
                end
                else if (control_reg[0])
                    counter_reg <= counter_reg + 1;
        end
                
    always_ff @(posedge wb.clk or posedge wb.rst)
        if (wb.rst)
            wb.ack <= 1'b0;
        else
            wb.ack <= valid & ~wb.stall;
    
endmodule

`resetall
