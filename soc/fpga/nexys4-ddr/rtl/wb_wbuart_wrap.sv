
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/01/2019 05:13:44 PM
// Design Name:
// Module Name: wb_wbuart_wrap
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

module wb_wbuart_wrap #(
    parameter [30:0]  INITIAL_SETUP = 31'd25,
    parameter [3:0]    LGFLEN = 4,
    parameter [0:0]   HARDWARE_FLOW_CONTROL_PRESENT = 1'b1
) (
    wb_if.slave wb,

    input  wire i_uart_rx,
    output wire o_uart_tx,

    input  wire i_cts_n,
    output wire o_rts_n,
    output wire o_uart_rx_int,
    output wire o_uart_tx_int,
    output wire o_uart_rxfifo_int,
    output wire o_uart_txfifo_int
);

  logic [1:0] addr;

  always_comb
    case (wb.adr[3:0])
      4'h0: addr = 2'b00;
      4'h4: addr = 2'b01;
      4'h8: addr = 2'b10;
      4'hc: addr = 2'b11;
      default: addr = 2'b01;
    endcase

  wbuart #(
      .INITIAL_SETUP                (INITIAL_SETUP),
      .LGFLEN                       (LGFLEN),
      .HARDWARE_FLOW_CONTROL_PRESENT(HARDWARE_FLOW_CONTROL_PRESENT)
  ) wbuart (
      .i_clk     (wb.clk),
      .i_rst     (wb.rst),
      .i_wb_cyc  (wb.cyc),
      .i_wb_stb  (wb.stb & wb.cyc),
      .i_wb_we   (wb.we),
      .i_wb_addr (addr),
      .i_wb_data (wb.dat_i),
      .o_wb_ack  (wb.ack),
      .o_wb_stall(wb.stall),
      .o_wb_data (wb.dat_o),

      .i_uart_rx(i_uart_rx),
      .o_uart_tx(o_uart_tx),

      .i_cts_n          (i_cts_n),
      .o_rts_n          (o_rts_n),
      .o_uart_tx_int    (o_uart_tx_int),
      .o_uart_rx_int    (o_uart_rx_int),
      .o_uart_txfifo_int(o_uart_txfifo_int),
      .o_uart_rxfifo_int(o_uart_rxfifo_int)
  );

  assign wb.err = 1'b0;

endmodule

`resetall

