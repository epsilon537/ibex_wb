/* Digital Core */

`default_nettype none

module core #(
    parameter num_scan_chains = 1
) (
    input  wire                       clk,
    input  wire                       ext_rst_n,
    input  wire [               15:0] gpio_i,
    output wire [               15:0] gpio_o,
    output wire [               15:0] gpio_oe_n,
    input  wire                       tck,
    input  wire                       trst_n,
    input  wire                       tms,
    input  wire                       tdi,
    output wire                       tdo,
    output wire                       tdo_oe_n,
    input  wire                       scan_mode,
    input  wire                       scan_en,
    output wire [num_scan_chains-1:0] sdo
);

  localparam ram_base_addr = 'h00000000;
  localparam ram_size = 'h10000;

  localparam gpio_base_addr = 'h10000000;
  localparam gpio_size = 'h1000;

  localparam dm_base_addr = 'h1A110000;
  localparam dm_size = 'h1000;

  logic rst, rst_n;
  logic                 core_sleep;
  logic                 ndmreset;
  logic                 dmactive;
  logic                 debug_req;
  dm::hartinfo_t        hartinfo;
  logic                 dmi_rst_n;
  logic                 dmi_req_valid;
  logic                 dmi_req_ready;
  dm::dmi_req_t         dmi_req;
  logic                 dmi_resp_valid;
  logic                 dmi_resp_ready;
  dm::dmi_resp_t        dmi_resp;
  logic          [15:0] gpio_oe;
  logic                 tdo_oe;

  wb_if wbm[3] (.*);
  wb_if wbs[3] (.*);

  sync_reset sync_reset (
      .clk      (clk),
      .ext_rst_n(ext_rst_n),
      .test_en  (scan_mode),
      .rst_n
  );

  wb_ibex_core wb_ibex_core (
      .instr_wb    (wbm[1]),
      .data_wb     (wbm[2]),
      .hart_id     (32'h0),
      .boot_addr   (32'h0),
      .irq_software(1'b0),
      .irq_timer   (1'b0),
      .irq_external(1'b0),
      .irq_fast    (15'b0),
      .irq_nm      (1'b0),
      .fetch_enable(1'b1),
      .test_en     (scan_en),
      .*
  );

  wb_dm_top wb_dm (
      .testmode   (scan_mode),
      .unavailable(1'b0),
      .wbm        (wbm[0]),
      .wbs        (wbs[0]),
      .dmi_rst_n  (dmi_rst_n),
      .*
  );

  dmi_jtag dmi (
      .clk_i           (clk),
      .rst_ni          (rst_n),
      .testmode_i      (scan_mode),
      .dmi_rst_no      (dmi_rst_n),
      .dmi_req_o       (dmi_req),
      .dmi_req_valid_o (dmi_req_valid),
      .dmi_req_ready_i (dmi_req_ready),
      .dmi_resp_i      (dmi_resp),
      .dmi_resp_ready_o(dmi_resp_ready),
      .dmi_resp_valid_i(dmi_resp_valid),
      .tck_i           (tck),
      .tms_i           (tms),
      .trst_ni         (trst_n),
      .td_i            (tdi),
      .td_o            (tdo),
      .tdo_oe_o        (tdo_oe)
  );

  wb_interconnect_sharedbus #(
      .numm     (3),
      .nums     (3),
      .base_addr({dm_base_addr, ram_base_addr, gpio_base_addr}),
      .size     ({dm_size, ram_size, gpio_size})
  ) wb_intercon (
      .*
  );

  wb_spram16384x32 wb_spram (.wb(wbs[1]));

  wb_gpio wb_gpio (
      .wb(wbs[2]),
      .*
  );

  assign rst = ~rst_n;

  assign gpio_oe_n = ~gpio_oe;

  assign tdo_oe_n = ~tdo_oe;

  assign hartinfo = '{
          zero1: 0,
          nscratch: 2,
          zero0: 0,
          dataaccess: 1,
          datasize: dm::DataCount,
          dataaddr: dm::DataAddr
      };
endmodule

`resetall
