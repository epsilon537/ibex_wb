`default_nettype none

module ibex_soc(
  input  wire       clk100mhz,
   
  inout  wire [7:0] gpio0,
  inout  wire [3:0] gpio1,
  
  input  wire       ck_rst_n,
  
  input  wire       uart_rx,
  output wire       uart_tx,
  
  input  wire       tck,
  input  wire       trst_n,
  input  wire       tms,
  input  wire       tdi,
  output wire       tdo
  );
  
  logic clk;
  logic rst, rst_n;
  
  assign rst = ~rst_n;
  
  typedef enum {
    //DM_M,
    COREI_M,
    CORED_M
  } wb_master_e;
  
  typedef enum {
    //DM_S,
    RAM_S,
    GPIO0_S,
    GPIO1_S,
    UART_S,
    TIMER_S
  } wb_slave_e;
  
  localparam NrMaster = 2;
  localparam NrSlave = 5;
  
  localparam [31:0] wb_base_addr [NrSlave] = {
    //'h1A110000, //DMS
    'h00000000, //RAM
    'h10000000, //GPIO0
    'h10000010, //GPIO1
    'h10010000, //UART
    'h10020000  //TIMER
  };
  
  localparam [31:0] wb_size [NrSlave] = {
    //'h10000, //DMS
    'h10000, //RAM
    'h00010, //GPIO0
    'h00010, //GPIO1
    'h00010, //UART
    'h00010  //TIMER
  };
  
  wb_if wbm[NrMaster](.*);
  wb_if wbs[NrSlave](.*);
  
  // define the macro if you want to use debugger
`ifdef DEBUG_MODULE_ACTIVE
  
  logic          core_sleep;
  logic          ndmreset;
  logic          dmactive;
  logic          debug_req;
  logic          unavailable = 1'b0;
  dm::hartinfo_t hartinfo = '{zero1: 0,
                              nscratch: 2,
                              zero0: 0,
                              dataaccess: 1,
                              datasize: dm::DataCount,
                              dataaddr: dm::DataAddr};
  logic          dmi_rst_n;
  logic          dmi_req_valid;
  logic          dmi_req_ready;
  dm::dmi_req_t  dmi_req;
  logic          dmi_resp_valid;
  logic          dmi_resp_ready;
  dm::dmi_resp_t dmi_resp;
  logic          tdo_o;
  logic          tdo_oe;

  assign tdo = tdo_oe ? tdo_o : 1'bz;

  wb_dm_top wb_dm (
    .testmode  (1'b0),
    .wbm       (wbm[DM_M]),
    .wbs       (wbs[DM_S]),
    .dmi_rst_n (dmi_rst_n),
    .*);

  dmi_jtag dmi (
    .clk_i            (clk),
    .rst_ni           (rst_n),
    .testmode_i       (1'b0),
    .dmi_rst_no       (dmi_rst_n),
    .dmi_req_o        (dmi_req),
    .dmi_req_valid_o  (dmi_req_valid),
    .dmi_req_ready_i  (dmi_req_ready),
    .dmi_resp_i       (dmi_resp),
    .dmi_resp_ready_o (dmi_resp_ready),
    .dmi_resp_valid_i (dmi_resp_valid),
    .tck_i            (tck),
    .tms_i            (tms),
    .trst_ni          (trst_n),
    .td_i             (tdi),
    .td_o             (tdo_o),
    .tdo_oe_o         (tdo_oe));
`else
   logic 	 core_sleep;
   logic 	 ndmreset;
   logic 	 dmactive;

   assign tdo = 1'bz;
`endif

   `ifdef SYNTHESIS
  clkgen_xil7series clkgen (
    .IO_CLK     (clk100mhz),
    .IO_RST_N   (ck_rst_n),
    .clk_sys    (clk),
    .rst_sys_n  (rst_n));
   `else
   assign clk = clk100mhz;
   assign rst_n = ck_rst_n;
   `endif
   
  wb_ibex_core #(
    .RV32M(ibex_pkg::RV32MFast),
    .RV32B(ibex_pkg::RV32BBalanced)
  )wb_ibex_core (
    .instr_wb     (wbm[COREI_M]),
    .data_wb      (wbm[CORED_M]),
    .test_en      (1'b0),
    .hart_id      (32'h0),
    .boot_addr    (32'h0),
    .irq_software (1'b0),
    .irq_timer    (1'b0),
    .irq_external (1'b0),
    .irq_fast     (15'b0),
    .irq_nm       (1'b0),
    .fetch_enable (1'b1),
    .*);

  wb_interconnect_sharedbus #(
    .numm      (NrMaster),
    .nums      (NrSlave),
    .base_addr (wb_base_addr),
    .size      (wb_size)
  ) wb_intercon (.*);

  wb_spramx32 #(
    .size(wb_size[RAM_S]),
    .init_file("hello.mem")
  ) wb_spram (
    .wb(wbs[RAM_S]));
  
  wb_gpio #(
    .size (8)
  ) wb_gpio0 (
    .gpio (gpio0),
    .wb (wbs[GPIO0_S]));
  
  wb_gpio #(
    .size (4)
  ) wb_gpio1 (
    .gpio (gpio1),
    .wb (wbs[GPIO1_S]));
  
  wb_wbuart_wrap #(
    .HARDWARE_FLOW_CONTROL_PRESENT  (1'b0),
    .INITIAL_SETUP                  (31'd25),
    .LGFLEN                         (4'd4)
  ) wb_uart (
    .wb (wbs[UART_S]),
    .i_uart_rx (uart_rx),
    .o_uart_tx (uart_tx),
    .i_cts_n   (1'b0));

  wb_timer timer (
    .wb (wbs[TIMER_S]));
  
endmodule

`resetall
