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
    
  typedef enum {
`ifdef DEBUG_MODULE_ACTIVE		
    DM_M,
`endif
    COREI_M,
    CORED_M
  } wb_master_e;
  
  typedef enum {
`ifdef DEBUG_MODULE_ACTIVE		
    DM_S,
`endif		
    RAM_S,
    GPIO0_S,
    GPIO1_S,
    UART_S,
    TIMER_S
  } wb_slave_e;

`ifdef DEBUG_MODULE_ACTIVE   
  localparam NrMaster = 3;
  localparam NrSlave = 6;
`else
  localparam NrMaster = 2;
  localparam NrSlave = 5;
`endif
   
  typedef logic [31:0] Wb_base_addr [NrSlave];

  function Wb_base_addr wb_base_addresses();
`ifdef DEBUG_MODULE_ACTIVE
     wb_base_addresses[DM_S] = 32'h1A110000;
`endif     
     wb_base_addresses[RAM_S] = 32'h00000000;
     wb_base_addresses[GPIO0_S] = 32'h10000000;
     wb_base_addresses[GPIO1_S] = 32'h10000010;
     wb_base_addresses[UART_S] = 32'h10010000;
     wb_base_addresses[TIMER_S] =  32'h10020000;
  endfunction

  localparam Wb_base_addr wb_base_addr = wb_base_addresses();
   
  typedef logic [31:0] Wb_size [NrSlave];

  //These are address range sizes in bytes
  function Wb_size wb_sizes();
`ifdef DEBUG_MODULE_ACTIVE      
    wb_sizes[DM_S] = 32'h10000;
`endif
    wb_sizes[RAM_S] = 32'h10000;
    wb_sizes[GPIO0_S] = 32'h00010; 
    wb_sizes[GPIO1_S] = 32'h00010; 
    wb_sizes[UART_S] = 32'h00010; 
    wb_sizes[TIMER_S] = 32'h00010; 
  endfunction

  localparam Wb_size wb_size = wb_sizes();
    
  logic clk;
  logic rst_n;
  //Non-Debug-Module-Reset, i.e. reset everything except Debug Module.
  //Driven by Debug Module itself to implement target reset function.
  logic ndmreset;
  
  wb_if wbm[NrMaster](.rst(ndmreset | (~rst_n)), .*);
  wb_if wbs[NrSlave](.rst(ndmreset | (~rst_n)), .*);
  
  // define the macro if you want to use debugger
`ifdef DEBUG_MODULE_ACTIVE
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
    .rst_n     (rst_n),
    .testmode  (1'b0),
    .ndmreset  (ndmreset),
    .dmactive  (dmactive),
    .debug_req (debug_req),
    .wbm       (wbm[DM_M]),
    .wbs       (wbs[DM_S]),
    .dmi_rst_n (dmi_rst_n),
    .*);

  dmi_jtag #(
        .IdcodeValue          ( 32'h249511C3    )
    ) dmi_jtag_inst (
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

   logic 	 unused = &{1'b0, dmactive, 1'b0};
`else
   logic 	 unused = &{1'b0, tck, trst_n, tms, tdi,1'b0};
   logic 	 debug_req;

   assign ndmreset = 1'b0;
   assign debug_req = 1'b0;
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
    .RV32B(ibex_pkg::RV32BBalanced),
    .RegFile(`PRIM_DEFAULT_IMPL == prim_pkg::ImplGeneric ? ibex_pkg::RegFileFF : ibex_pkg::RegFileFPGA)
  ) wb_ibex_core (
    .rst_n        (rst_n & (~ndmreset)),
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
    .debug_req    (debug_req),
    .fetch_enable (4'b1),
    .core_sleep   (),
    .*);

  wb_interconnect_sharedbus #(
    .numm      (NrMaster),
    .nums      (NrSlave),
    .base_addr (wb_base_addr),
    .size      (wb_size)
  ) wb_intercon (.*);

  wb_spramx32 #(
    .size(wb_size[RAM_S]),
    .init_file("spram.mem") //This is the .mem file that our SW build should produce.
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
    .i_cts_n   (1'b0),
    .o_rts_n(),
    .o_uart_rx_int(),
    .o_uart_tx_int(),
    .o_uart_rxfifo_int(),
    .o_uart_txfifo_int());

  wb_timer timer (
    .wb (wbs[TIMER_S]));
  
endmodule

`resetall
