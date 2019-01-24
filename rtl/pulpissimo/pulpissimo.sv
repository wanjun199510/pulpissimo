// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module pulpissimo
#(
  parameter CORE_TYPE   = 0,
            // 0 for RISCY, 1 for ZERORISCY, 2 for MICRORISCY
  parameter USE_FPU     = 1
)
(
`ifdef PULP_FPGA_EMUL
   input  logic       zynq_safen_spim_i, // if 1, use SPI master to Zynq and not safe domain
   input  logic       zynq_safen_uart_i, // if 1, use UART to Zynq and not safe domain
   // signals for the interposer between safe domain and soc domain in FPGA emulator
   output logic       zynq2soc_spim_sck_o,
   output logic       zynq2soc_spim_csn_o,
   output logic       zynq2soc_spim_sdo0_o,
   output logic       zynq2soc_spim_sdo1_o,
   output logic       zynq2soc_spim_sdo2_o,
   output logic       zynq2soc_spim_sdo3_o,
   input  logic       zynq2soc_spim_sdi0_i,
   input  logic       zynq2soc_spim_sdi1_i,
   input  logic       zynq2soc_spim_sdi2_i,
   input  logic       zynq2soc_spim_sdi3_i,
   output logic       zynq2soc_uart_tx_o,
   input  logic       zynq2soc_uart_rx_i,
   input  logic       zynq_clk_i,
   input  logic       zynq_soc_clk_i,
   input  logic       zynq_cluster_clk_i,
   input  logic       zynq_rst_n_i,
`endif

   inout  wire        pad_spim_sdio0,
   inout  wire        pad_spim_sdio1,
   inout  wire        pad_spim_sdio2,
   inout  wire        pad_spim_sdio3,
   inout  wire        pad_spim_csn0,
   inout  wire        pad_spim_csn1,
   inout  wire        pad_spim_sck,

   inout  wire        pad_uart_rx,
   inout  wire        pad_uart_tx,

   inout  wire        pad_cam_pclk,
   inout  wire        pad_cam_hsync,
   inout  wire        pad_cam_data0,
   inout  wire        pad_cam_data1,
   inout  wire        pad_cam_data2,
   inout  wire        pad_cam_data3,
   inout  wire        pad_cam_data4,
   inout  wire        pad_cam_data5,
   inout  wire        pad_cam_data6,
   inout  wire        pad_cam_data7,
   inout  wire        pad_cam_vsync,

   inout  wire        pad_sdio_clk,
   inout  wire        pad_sdio_cmd,
   inout  wire        pad_sdio_data0,
   inout  wire        pad_sdio_data1,
   inout  wire        pad_sdio_data2,
   inout  wire        pad_sdio_data3,

   inout  wire        pad_i2c0_sda,
   inout  wire        pad_i2c0_scl,

   inout  wire        pad_i2s0_sck,
   inout  wire        pad_i2s0_ws,
   inout  wire        pad_i2s0_sdi,
   inout  wire        pad_i2s1_sdi,

   inout  wire        pad_reset_n,
   inout  wire        pad_bootsel,

   inout  wire        pad_jtag_tck,
   inout  wire        pad_jtag_tdi,
   inout  wire        pad_jtag_tdo,
   inout  wire        pad_jtag_tms,
   inout  wire        pad_jtag_trst,

   inout  wire        pad_xtal_in
  );

  localparam AXI_ADDR_WIDTH             = 32;
  localparam AXI_CLUSTER_SOC_DATA_WIDTH = 64;
  localparam AXI_SOC_CLUSTER_DATA_WIDTH = 32;
  localparam AXI_CLUSTER_SOC_ID_WIDTH   = 6;
  localparam AXI_SOC_CLUSTER_ID_WIDTH   = 4;

  localparam AXI_USER_WIDTH             = 6;
  localparam AXI_CLUSTER_SOC_STRB_WIDTH = AXI_CLUSTER_SOC_DATA_WIDTH/8;
  localparam AXI_SOC_CLUSTER_STRB_WIDTH = AXI_SOC_CLUSTER_DATA_WIDTH/8;

  localparam BUFFER_WIDTH               = 8;
  localparam EVENT_WIDTH                = 8;

  localparam CVP_ADDR_WIDTH             = 32;
  localparam CVP_DATA_WIDTH             = 32;

  //***********************************************************
  //********** PAD FRAME TO PAD CONTROL SIGNALS ***************
  //***********************************************************

  logic [47:0][5:0] s_pad_cfg ;

  logic s_out_spim_sdio0 ;
  logic s_out_spim_sdio1 ;
  logic s_out_spim_sdio2 ;
  logic s_out_spim_sdio3 ;
  logic s_out_spim_csn0  ;
  logic s_out_spim_csn1  ;
  logic s_out_spim_sck   ;
  logic s_out_uart_rx    ;
  logic s_out_uart_tx    ;
  logic s_out_cam_pclk   ;
  logic s_out_cam_hsync  ;
  logic s_out_cam_data0  ;
  logic s_out_cam_data1  ;
  logic s_out_cam_data2  ;
  logic s_out_cam_data3  ;
  logic s_out_cam_data4  ;
  logic s_out_cam_data5  ;
  logic s_out_cam_data6  ;
  logic s_out_cam_data7  ;
  logic s_out_cam_vsync  ;
  logic s_out_sdio_clk   ;
  logic s_out_sdio_cmd   ;
  logic s_out_sdio_data0 ;
  logic s_out_sdio_data1 ;
  logic s_out_sdio_data2 ;
  logic s_out_sdio_data3 ;
  logic s_out_i2c0_sda   ;
  logic s_out_i2c0_scl   ;
  logic s_out_i2s0_sck   ;
  logic s_out_i2s0_ws    ;
  logic s_out_i2s0_sdi   ;
  logic s_out_i2s1_sdi   ;

  logic s_in_spim_sdio0  ;
  logic s_in_spim_sdio1  ;
  logic s_in_spim_sdio2  ;
  logic s_in_spim_sdio3  ;
  logic s_in_spim_csn0   ;
  logic s_in_spim_csn1   ;
  logic s_in_spim_sck    ;
  logic s_in_uart_rx     ;
  logic s_in_uart_tx     ;
  logic s_in_cam_pclk    ;
  logic s_in_cam_hsync   ;
  logic s_in_cam_data0   ;
  logic s_in_cam_data1   ;
  logic s_in_cam_data2   ;
  logic s_in_cam_data3   ;
  logic s_in_cam_data4   ;
  logic s_in_cam_data5   ;
  logic s_in_cam_data6   ;
  logic s_in_cam_data7   ;
  logic s_in_cam_vsync   ;
  logic s_in_sdio_clk    ;
  logic s_in_sdio_cmd    ;
  logic s_in_sdio_data0  ;
  logic s_in_sdio_data1  ;
  logic s_in_sdio_data2  ;
  logic s_in_sdio_data3  ;
  logic s_in_i2c0_sda    ;
  logic s_in_i2c0_scl    ;
  logic s_in_i2s0_sck    ;
  logic s_in_i2s0_ws     ;
  logic s_in_i2s0_sdi    ;
  logic s_in_i2s1_sdi    ;

  logic s_oe_spim_sdio0  ;
  logic s_oe_spim_sdio1  ;
  logic s_oe_spim_sdio2  ;
  logic s_oe_spim_sdio3  ;
  logic s_oe_spim_csn0   ;
  logic s_oe_spim_csn1   ;
  logic s_oe_spim_sck    ;
  logic s_oe_uart_rx     ;
  logic s_oe_uart_tx     ;
  logic s_oe_cam_pclk    ;
  logic s_oe_cam_hsync   ;
  logic s_oe_cam_data0   ;
  logic s_oe_cam_data1   ;
  logic s_oe_cam_data2   ;
  logic s_oe_cam_data3   ;
  logic s_oe_cam_data4   ;
  logic s_oe_cam_data5   ;
  logic s_oe_cam_data6   ;
  logic s_oe_cam_data7   ;
  logic s_oe_cam_vsync   ;
  logic s_oe_sdio_clk    ;
  logic s_oe_sdio_cmd    ;
  logic s_oe_sdio_data0  ;
  logic s_oe_sdio_data1  ;
  logic s_oe_sdio_data2  ;
  logic s_oe_sdio_data3  ;
  logic s_oe_i2c0_sda    ;
  logic s_oe_i2c0_scl    ;
  logic s_oe_i2s0_sck    ;
  logic s_oe_i2s0_ws     ;
  logic s_oe_i2s0_sdi    ;
  logic s_oe_i2s1_sdi    ;

  //***********************************************************
  //********** OTHER PAD FRAME SIGNALS ************************
  //***********************************************************

  logic s_ref_clk        ;
  logic s_rstn           ;

  logic s_jtag_tck       ;
  logic s_jtag_tdi       ;
  logic s_jtag_tdo       ;
  logic s_jtag_tms       ;
  logic s_jtag_trst      ;

  //***********************************************************
  //********** SOC TO SAFE DOMAINS SIGNALS ********************
  //***********************************************************

  logic                        s_test_clk;
  logic                        s_slow_clk;
  logic                        s_sel_fll_clk;

  logic [11:0]                 s_pm_cfg_data;
  logic                        s_pm_cfg_req;
  logic                        s_pm_cfg_ack;

  logic                        s_cluster_busy;

  logic                        s_soc_tck;
  logic                        s_soc_trstn;
  logic                        s_soc_tms;
  logic                        s_soc_tdi;

  logic                        s_test_mode;
  logic                        s_dft_cg_enable;
  logic                        s_mode_select;

  logic [31:0]                 s_gpio_out;
  logic [31:0]                 s_gpio_in;
  logic [31:0]                 s_gpio_dir;
  logic [191:0]                s_gpio_cfg;

  logic                        s_rf_tx_clk;
  logic                        s_rf_tx_oeb;
  logic                        s_rf_tx_enb;
  logic                        s_rf_tx_mode;
  logic                        s_rf_tx_vsel;
  logic                        s_rf_tx_data;
  logic                        s_rf_rx_clk;
  logic                        s_rf_rx_enb;
  logic                        s_rf_rx_data;

  logic                        s_uart_tx;
  logic                        s_uart_rx;

`ifdef PULP_FPGA_EMUL
  logic                        s_safe2soc_uart_tx;
  logic                        s_safe2soc_uart_rx;
`endif

  logic                        s_i2c0_scl_out;
  logic                        s_i2c0_scl_in;
  logic                        s_i2c0_scl_oe;
  logic                        s_i2c0_sda_out;
  logic                        s_i2c0_sda_in;
  logic                        s_i2c0_sda_oe;
  logic                        s_i2c1_scl_out;
  logic                        s_i2c1_scl_in;
  logic                        s_i2c1_scl_oe;
  logic                        s_i2c1_sda_out;
  logic                        s_i2c1_sda_in;
  logic                        s_i2c1_sda_oe;
  logic                        s_i2s_sd0_in;
  logic                        s_i2s_sd1_in;
  logic                        s_i2s_sck_in;
  logic                        s_i2s_ws_in;
  logic                        s_i2s_sck0_out;
  logic                        s_i2s_ws0_out;
  logic [1:0]                  s_i2s_mode0_out;
  logic                        s_i2s_sck1_out;
  logic                        s_i2s_ws1_out;
  logic [1:0]                  s_i2s_mode1_out;
  logic                        s_spi_master0_csn0;
  logic                        s_spi_master0_csn1;
  logic                        s_spi_master0_sck;
  logic                        s_spi_master0_sdi0;
  logic                        s_spi_master0_sdi1;
  logic                        s_spi_master0_sdi2;
  logic                        s_spi_master0_sdi3;
  logic                        s_spi_master0_sdo0;
  logic                        s_spi_master0_sdo1;
  logic                        s_spi_master0_sdo2;
  logic                        s_spi_master0_sdo3;
  logic [1:0]                  s_spi_master0_mode;

`ifdef PULP_FPGA_EMUL
  logic                        s_safe2soc_spi_master0_csn0;
  logic                        s_safe2soc_spi_master0_csn1;
  logic                        s_safe2soc_spi_master0_sck;
  logic                        s_safe2soc_spi_master0_sdi0;
  logic                        s_safe2soc_spi_master0_sdi1;
  logic                        s_safe2soc_spi_master0_sdi2;
  logic                        s_safe2soc_spi_master0_sdi3;
  logic                        s_safe2soc_spi_master0_sdo0;
  logic                        s_safe2soc_spi_master0_sdo1;
  logic                        s_safe2soc_spi_master0_sdo2;
  logic                        s_safe2soc_spi_master0_sdo3;
`endif

  logic                        s_spi_master1_csn0;
  logic                        s_spi_master1_csn1;
  logic                        s_spi_master1_sck;
  logic                        s_spi_master1_sdi;
  logic                        s_spi_master1_sdo;
  logic [1:0]                  s_spi_master1_mode;

  logic                        s_sdio_clk;
  logic                        s_sdio_cmdi;
  logic                        s_sdio_cmdo;
  logic                        s_sdio_cmd_oen ;
  logic [3:0]                  s_sdio_datai;
  logic [3:0]                  s_sdio_datao;
  logic [3:0]                  s_sdio_data_oen;


  logic                        s_cam_pclk;
  logic [7:0]                  s_cam_data;
  logic                        s_cam_hsync;
  logic                        s_cam_vsync;
  logic [3:0]                  s_timer0;
  logic [3:0]                  s_timer1;
  logic [3:0]                  s_timer2;
  logic [3:0]                  s_timer3;

  logic                        s_jtag_shift_dr;
  logic                        s_jtag_update_dr;
  logic                        s_jtag_capture_dr;

  logic                        s_axireg_sel;
  logic                        s_axireg_tdi;
  logic                        s_axireg_tdo;

  logic [7:0]                  s_soc_jtag_regi;
  logic [7:0]                  s_soc_jtag_rego;

  logic                        s_rstn_por;
  logic                        s_cluster_pow;
  logic                        s_cluster_byp;

  logic                        s_dma_pe_irq_ack;
  logic                        s_dma_pe_irq_valid;

  logic [127:0]                s_pad_mux_soc;
  logic [383:0]                s_pad_cfg_soc;

  //***********************************************************
  //********** SOC TO CLUSTER DOMAINS SIGNALS *****************
  //***********************************************************

  logic                        s_dma_pe_evt_ack;
  logic                        s_dma_pe_evt_valid;
  logic                        s_dma_pe_int_ack;
  logic                        s_dma_pe_int_valid;
  logic                        s_pf_evt_ack;
  logic                        s_pf_evt_valid;

  logic [BUFFER_WIDTH-1:0]     s_event_writetoken;
  logic [BUFFER_WIDTH-1:0]     s_event_readpointer;
  logic [EVENT_WIDTH-1:0]      s_event_dataasync;
  logic                        s_cluster_irq;

  //***********************************************************
  //********** PAD FRAME **************************************
  //***********************************************************

  pad_frame pad_frame_i
  (
        .pad_cfg_i             ( s_pad_cfg              ),

`ifndef PULP_FPGA_EMUL
        .ref_clk_o             ( s_ref_clk              ),
        .rstn_o                ( s_rstn                 ),
`endif
        .jtag_tdo_i            ( s_jtag_tdo             ),
        .jtag_tck_o            ( s_jtag_tck             ),
        .jtag_tdi_o            ( s_jtag_tdi             ),
        .jtag_tms_o            ( s_jtag_tms             ),
        .jtag_trst_o           ( s_jtag_trst            ),

        .oe_spim_sdio0_i       ( s_oe_spim_sdio0        ),
        .oe_spim_sdio1_i       ( s_oe_spim_sdio1        ),
        .oe_spim_sdio2_i       ( s_oe_spim_sdio2        ),
        .oe_spim_sdio3_i       ( s_oe_spim_sdio3        ),
        .oe_spim_csn0_i        ( s_oe_spim_csn0         ),
        .oe_spim_csn1_i        ( s_oe_spim_csn1         ),
        .oe_spim_sck_i         ( s_oe_spim_sck          ),
        .oe_sdio_clk_i         ( s_oe_sdio_clk          ),
        .oe_sdio_cmd_i         ( s_oe_sdio_cmd          ),
        .oe_sdio_data0_i       ( s_oe_sdio_data0        ),
        .oe_sdio_data1_i       ( s_oe_sdio_data1        ),
        .oe_sdio_data2_i       ( s_oe_sdio_data2        ),
        .oe_sdio_data3_i       ( s_oe_sdio_data3        ),
        .oe_i2s0_sck_i         ( s_oe_i2s0_sck          ),
        .oe_i2s0_ws_i          ( s_oe_i2s0_ws           ),
        .oe_i2s0_sdi_i         ( s_oe_i2s0_sdi          ),
        .oe_i2s1_sdi_i         ( s_oe_i2s1_sdi          ),
        .oe_cam_pclk_i         ( s_oe_cam_pclk          ),
        .oe_cam_hsync_i        ( s_oe_cam_hsync         ),
        .oe_cam_data0_i        ( s_oe_cam_data0         ),
        .oe_cam_data1_i        ( s_oe_cam_data1         ),
        .oe_cam_data2_i        ( s_oe_cam_data2         ),
        .oe_cam_data3_i        ( s_oe_cam_data3         ),
        .oe_cam_data4_i        ( s_oe_cam_data4         ),
        .oe_cam_data5_i        ( s_oe_cam_data5         ),
        .oe_cam_data6_i        ( s_oe_cam_data6         ),
        .oe_cam_data7_i        ( s_oe_cam_data7         ),
        .oe_cam_vsync_i        ( s_oe_cam_vsync         ),
        .oe_i2c0_sda_i         ( s_oe_i2c0_sda          ),
        .oe_i2c0_scl_i         ( s_oe_i2c0_scl          ),
        .oe_uart_rx_i          ( s_oe_uart_rx           ),
        .oe_uart_tx_i          ( s_oe_uart_tx           ),

        .out_spim_sdio0_i      ( s_out_spim_sdio0       ),
        .out_spim_sdio1_i      ( s_out_spim_sdio1       ),
        .out_spim_sdio2_i      ( s_out_spim_sdio2       ),
        .out_spim_sdio3_i      ( s_out_spim_sdio3       ),
        .out_spim_csn0_i       ( s_out_spim_csn0        ),
        .out_spim_csn1_i       ( s_out_spim_csn1        ),
        .out_spim_sck_i        ( s_out_spim_sck         ),
        .out_sdio_clk_i        ( s_out_sdio_clk         ),
        .out_sdio_cmd_i        ( s_out_sdio_cmd         ),
        .out_sdio_data0_i      ( s_out_sdio_data0       ),
        .out_sdio_data1_i      ( s_out_sdio_data1       ),
        .out_sdio_data2_i      ( s_out_sdio_data2       ),
        .out_sdio_data3_i      ( s_out_sdio_data3       ),
        .out_i2s0_sck_i        ( s_out_i2s0_sck         ),
        .out_i2s0_ws_i         ( s_out_i2s0_ws          ),
        .out_i2s0_sdi_i        ( s_out_i2s0_sdi         ),
        .out_i2s1_sdi_i        ( s_out_i2s1_sdi         ),
        .out_cam_pclk_i        ( s_out_cam_pclk         ),
        .out_cam_hsync_i       ( s_out_cam_hsync        ),
        .out_cam_data0_i       ( s_out_cam_data0        ),
        .out_cam_data1_i       ( s_out_cam_data1        ),
        .out_cam_data2_i       ( s_out_cam_data2        ),
        .out_cam_data3_i       ( s_out_cam_data3        ),
        .out_cam_data4_i       ( s_out_cam_data4        ),
        .out_cam_data5_i       ( s_out_cam_data5        ),
        .out_cam_data6_i       ( s_out_cam_data6        ),
        .out_cam_data7_i       ( s_out_cam_data7        ),
        .out_cam_vsync_i       ( s_out_cam_vsync        ),
        .out_i2c0_sda_i        ( s_out_i2c0_sda         ),
        .out_i2c0_scl_i        ( s_out_i2c0_scl         ),
        .out_uart_rx_i         ( s_out_uart_rx          ),
        .out_uart_tx_i         ( s_out_uart_tx          ),

        .in_spim_sdio0_o       ( s_in_spim_sdio0        ),
        .in_spim_sdio1_o       ( s_in_spim_sdio1        ),
        .in_spim_sdio2_o       ( s_in_spim_sdio2        ),
        .in_spim_sdio3_o       ( s_in_spim_sdio3        ),
        .in_spim_csn0_o        ( s_in_spim_csn0         ),
        .in_spim_csn1_o        ( s_in_spim_csn1         ),
        .in_spim_sck_o         ( s_in_spim_sck          ),
        .in_sdio_clk_o         ( s_in_sdio_clk          ),
        .in_sdio_cmd_o         ( s_in_sdio_cmd          ),
        .in_sdio_data0_o       ( s_in_sdio_data0        ),
        .in_sdio_data1_o       ( s_in_sdio_data1        ),
        .in_sdio_data2_o       ( s_in_sdio_data2        ),
        .in_sdio_data3_o       ( s_in_sdio_data3        ),
        .in_i2s0_sck_o         ( s_in_i2s0_sck          ),
        .in_i2s0_ws_o          ( s_in_i2s0_ws           ),
        .in_i2s0_sdi_o         ( s_in_i2s0_sdi          ),
        .in_i2s1_sdi_o         ( s_in_i2s1_sdi          ),
        .in_cam_pclk_o         ( s_in_cam_pclk          ),
        .in_cam_hsync_o        ( s_in_cam_hsync         ),
        .in_cam_data0_o        ( s_in_cam_data0         ),
        .in_cam_data1_o        ( s_in_cam_data1         ),
        .in_cam_data2_o        ( s_in_cam_data2         ),
        .in_cam_data3_o        ( s_in_cam_data3         ),
        .in_cam_data4_o        ( s_in_cam_data4         ),
        .in_cam_data5_o        ( s_in_cam_data5         ),
        .in_cam_data6_o        ( s_in_cam_data6         ),
        .in_cam_data7_o        ( s_in_cam_data7         ),
        .in_cam_vsync_o        ( s_in_cam_vsync         ),
        .in_i2c0_sda_o         ( s_in_i2c0_sda          ),
        .in_i2c0_scl_o         ( s_in_i2c0_scl          ),
        .in_uart_rx_o          ( s_in_uart_rx           ),
        .in_uart_tx_o          ( s_in_uart_tx           ),

        //EXT CHIP to PAD
        .pad_spim_sdio0        ( pad_spim_sdio0         ),
        .pad_spim_sdio1        ( pad_spim_sdio1         ),
        .pad_spim_sdio2        ( pad_spim_sdio2         ),
        .pad_spim_sdio3        ( pad_spim_sdio3         ),
        .pad_spim_csn0         ( pad_spim_csn0          ),
        .pad_spim_csn1         ( pad_spim_csn1          ),
        .pad_spim_sck          ( pad_spim_sck           ),
        .pad_sdio_clk          ( pad_sdio_clk           ),
        .pad_sdio_cmd          ( pad_sdio_cmd           ),
        .pad_sdio_data0        ( pad_sdio_data0         ),
        .pad_sdio_data1        ( pad_sdio_data1         ),
        .pad_sdio_data2        ( pad_sdio_data2         ),
        .pad_sdio_data3        ( pad_sdio_data3         ),
        .pad_i2s0_sck          ( pad_i2s0_sck           ),
        .pad_i2s0_ws           ( pad_i2s0_ws            ),
        .pad_i2s0_sdi          ( pad_i2s0_sdi           ),
        .pad_i2s1_sdi          ( pad_i2s1_sdi           ),
        .pad_cam_pclk          ( pad_cam_pclk           ),
        .pad_cam_hsync         ( pad_cam_hsync          ),
        .pad_cam_data0         ( pad_cam_data0          ),
        .pad_cam_data1         ( pad_cam_data1          ),
        .pad_cam_data2         ( pad_cam_data2          ),
        .pad_cam_data3         ( pad_cam_data3          ),
        .pad_cam_data4         ( pad_cam_data4          ),
        .pad_cam_data5         ( pad_cam_data5          ),
        .pad_cam_data6         ( pad_cam_data6          ),
        .pad_cam_data7         ( pad_cam_data7          ),
        .pad_cam_vsync         ( pad_cam_vsync          ),
        .pad_i2c0_sda          ( pad_i2c0_sda           ),
        .pad_i2c0_scl          ( pad_i2c0_scl           ),
        .pad_uart_rx           ( pad_uart_rx            ),
        .pad_uart_tx           ( pad_uart_tx            ),

        .pad_bootsel           ( pad_bootsel            ),
        .pad_reset_n           ( pad_reset_n            ),
        .pad_jtag_tck          ( pad_jtag_tck           ),
        .pad_jtag_tdi          ( pad_jtag_tdi           ),
        .pad_jtag_tdo          ( pad_jtag_tdo           ),
        .pad_jtag_tms          ( pad_jtag_tms           ),
        .pad_jtag_trst         ( pad_jtag_trst          ),
        .pad_xtal_in           ( pad_xtal_in            )

   );

  //***********************************************************
  //********** SAFE DOMAIN ************************************
  //***********************************************************
   safe_domain safe_domain_i (

        .ref_clk_i                  ( s_ref_clk                   ),
        .slow_clk_o                 ( s_slow_clk                  ),
        .rst_ni                     ( s_rstn                     ),

        .rst_no                     ( s_rstn_por                  ),

        .test_clk_o                 ( s_test_clk                  ),
        .test_mode_o                ( s_test_mode                 ),
        .mode_select_o              ( s_mode_select               ),
        .dft_cg_enable_o            ( s_dft_cg_enable             ),

        .sel_fll_clk_o              ( s_sel_fll_clk               ),

        .jtag_tck_i                 ( s_jtag_tck                  ),
        .jtag_trst_ni               ( s_jtag_trst                 ),
        .jtag_tms_i                 ( s_jtag_tms                  ),
        .jtag_tdi_i                 ( s_jtag_tdi                  ),
        .jtag_tdo_o                 ( s_jtag_tdo                  ),

        .jtag_shift_dr_o            ( s_jtag_shift_dr             ),
        .jtag_update_dr_o           ( s_jtag_update_dr            ),
        .jtag_capture_dr_o          ( s_jtag_capture_dr           ),

        .ndmreset_o                 (                             ),
        .dm_debug_req_o             (                             ),

        .axireg_sel_o               ( s_axireg_sel                ),
        .axireg_tdi_o               ( s_axireg_tdi                ),
        .axireg_tdo_i               ( s_axireg_tdo                ),

        .soc_jtag_reg_i             ( s_soc_jtag_regi             ),
        .soc_jtag_reg_o             ( s_soc_jtag_rego             ),

        .pad_cfg_o                  ( s_pad_cfg                   ),

        .pad_cfg_i                  ( s_pad_cfg_soc               ),
        .pad_mux_i                  ( s_pad_mux_soc               ),

        .gpio_out_i                 ( s_gpio_out                  ),
        .gpio_in_o                  ( s_gpio_in                   ),
        .gpio_dir_i                 ( s_gpio_dir                  ),
        .gpio_cfg_i                 ( s_gpio_cfg                  ),

`ifdef PULP_FPGA_EMUL
        .uart_tx_i                  ( s_safe2soc_uart_tx          ),
        .uart_rx_o                  ( s_safe2soc_uart_rx          ),
`else
        .uart_tx_i                  ( s_uart_tx                   ),
        .uart_rx_o                  ( s_uart_rx                   ),
`endif

        .i2c0_scl_out_i             ( s_i2c0_scl_out              ),
        .i2c0_scl_in_o              ( s_i2c0_scl_in               ),
        .i2c0_scl_oe_i              ( s_i2c0_scl_oe               ),
        .i2c0_sda_out_i             ( s_i2c0_sda_out              ),
        .i2c0_sda_in_o              ( s_i2c0_sda_in               ),
        .i2c0_sda_oe_i              ( s_i2c0_sda_oe               ),

        .i2c1_scl_out_i             ( s_i2c1_scl_out              ),
        .i2c1_scl_in_o              ( s_i2c1_scl_in               ),
        .i2c1_scl_oe_i              ( s_i2c1_scl_oe               ),
        .i2c1_sda_out_i             ( s_i2c1_sda_out              ),
        .i2c1_sda_in_o              ( s_i2c1_sda_in               ),
        .i2c1_sda_oe_i              ( s_i2c1_sda_oe               ),

        .i2s_sd0_in_o               ( s_i2s_sd0_in                ),
        .i2s_sd1_in_o               ( s_i2s_sd1_in                ),
        .i2s_sck_in_o               ( s_i2s_sck_in                ),
        .i2s_ws_in_o                ( s_i2s_ws_in                 ),
        .i2s_sck0_out_i             ( s_i2s_sck0_out              ),
        .i2s_ws0_out_i              ( s_i2s_ws0_out               ),
        .i2s_mode0_out_i            ( s_i2s_mode0_out             ),
        .i2s_sck1_out_i             ( s_i2s_sck1_out              ),
        .i2s_ws1_out_i              ( s_i2s_ws1_out               ),
        .i2s_mode1_out_i            ( s_i2s_mode1_out             ),

`ifdef PULP_FPGA_EMUL
        .spi_master0_csn0_i         ( s_safe2soc_spi_master0_csn0 ),
        .spi_master0_csn1_i         ( s_safe2soc_spi_master0_csn1 ),
        .spi_master0_sck_i          ( s_safe2soc_spi_master0_sck  ),
        .spi_master0_sdi0_o         ( s_safe2soc_spi_master0_sdi0 ),
        .spi_master0_sdi1_o         ( s_safe2soc_spi_master0_sdi1 ),
        .spi_master0_sdi2_o         ( s_safe2soc_spi_master0_sdi2 ),
        .spi_master0_sdi3_o         ( s_safe2soc_spi_master0_sdi3 ),
        .spi_master0_sdo0_i         ( s_safe2soc_spi_master0_sdo0 ),
        .spi_master0_sdo1_i         ( s_safe2soc_spi_master0_sdo1 ),
        .spi_master0_sdo2_i         ( s_safe2soc_spi_master0_sdo2 ),
        .spi_master0_sdo3_i         ( s_safe2soc_spi_master0_sdo3 ),
        .spi_master0_mode_i         ( s_safe2soc_spi_master0_mode ),
`else
        .spi_master0_csn0_i         ( s_spi_master0_csn0          ),
        .spi_master0_csn1_i         ( s_spi_master0_csn1          ),
        .spi_master0_sck_i          ( s_spi_master0_sck           ),
        .spi_master0_sdi0_o         ( s_spi_master0_sdi0          ),
        .spi_master0_sdi1_o         ( s_spi_master0_sdi1          ),
        .spi_master0_sdi2_o         ( s_spi_master0_sdi2          ),
        .spi_master0_sdi3_o         ( s_spi_master0_sdi3          ),
        .spi_master0_sdo0_i         ( s_spi_master0_sdo0          ),
        .spi_master0_sdo1_i         ( s_spi_master0_sdo1          ),
        .spi_master0_sdo2_i         ( s_spi_master0_sdo2          ),
        .spi_master0_sdo3_i         ( s_spi_master0_sdo3          ),
        .spi_master0_mode_i         ( s_spi_master0_mode          ),
`endif
        .spi_master1_csn0_i         ( 1'b1                        ),
        .spi_master1_csn1_i         ( 1'b1                        ),
        .spi_master1_sck_i          ( 1'b0                        ),
        .spi_master1_sdi_o          (                             ),
        .spi_master1_sdo_i          ( 1'b0                        ),
        .spi_master1_mode_i         ( 2'b00                       ),

        .sdio_clk_i                 ( s_sdio_clk                  ),
        .sdio_cmd_i                 ( s_sdio_cmdo                 ),
        .sdio_cmd_o                 ( s_sdio_cmdi                 ),
        .sdio_cmd_oen_i             ( s_sdio_cmd_oen              ),
        .sdio_data_i                ( s_sdio_datao                ),
        .sdio_data_o                ( s_sdio_datai                ),
        .sdio_data_oen_i            ( s_sdio_data_oen             ),

        .cam_pclk_o                 ( s_cam_pclk                  ),
        .cam_data_o                 ( s_cam_data                  ),
        .cam_hsync_o                ( s_cam_hsync                 ),
        .cam_vsync_o                ( s_cam_vsync                 ),

        .timer0_i                   ( s_timer0                    ),
        .timer1_i                   ( s_timer1                    ),
        .timer2_i                   ( s_timer2                    ),
        .timer3_i                   ( s_timer3                    ),

        .out_spim_sdio0_o           ( s_out_spim_sdio0            ),
        .out_spim_sdio1_o           ( s_out_spim_sdio1            ),
        .out_spim_sdio2_o           ( s_out_spim_sdio2            ),
        .out_spim_sdio3_o           ( s_out_spim_sdio3            ),
        .out_spim_csn0_o            ( s_out_spim_csn0             ),
        .out_spim_csn1_o            ( s_out_spim_csn1             ),
        .out_spim_sck_o             ( s_out_spim_sck              ),

        .out_sdio_clk_o             ( s_out_sdio_clk              ),
        .out_sdio_cmd_o             ( s_out_sdio_cmd              ),
        .out_sdio_data0_o           ( s_out_sdio_data0            ),
        .out_sdio_data1_o           ( s_out_sdio_data1            ),
        .out_sdio_data2_o           ( s_out_sdio_data2            ),
        .out_sdio_data3_o           ( s_out_sdio_data3            ),

        .out_uart_rx_o              ( s_out_uart_rx               ),
        .out_uart_tx_o              ( s_out_uart_tx               ),

        .out_cam_pclk_o             ( s_out_cam_pclk              ),
        .out_cam_hsync_o            ( s_out_cam_hsync             ),
        .out_cam_data0_o            ( s_out_cam_data0             ),
        .out_cam_data1_o            ( s_out_cam_data1             ),
        .out_cam_data2_o            ( s_out_cam_data2             ),
        .out_cam_data3_o            ( s_out_cam_data3             ),
        .out_cam_data4_o            ( s_out_cam_data4             ),
        .out_cam_data5_o            ( s_out_cam_data5             ),
        .out_cam_data6_o            ( s_out_cam_data6             ),
        .out_cam_data7_o            ( s_out_cam_data7             ),
        .out_cam_vsync_o            ( s_out_cam_vsync             ),

        .out_i2c0_sda_o             ( s_out_i2c0_sda              ),
        .out_i2c0_scl_o             ( s_out_i2c0_scl              ),
        .out_i2s0_sck_o             ( s_out_i2s0_sck              ),
        .out_i2s0_ws_o              ( s_out_i2s0_ws               ),
        .out_i2s0_sdi_o             ( s_out_i2s0_sdi              ),
        .out_i2s1_sdi_o             ( s_out_i2s1_sdi              ),

        .in_spim_sdio0_i            ( s_in_spim_sdio0             ),
        .in_spim_sdio1_i            ( s_in_spim_sdio1             ),
        .in_spim_sdio2_i            ( s_in_spim_sdio2             ),
        .in_spim_sdio3_i            ( s_in_spim_sdio3             ),
        .in_spim_csn0_i             ( s_in_spim_csn0              ),
        .in_spim_csn1_i             ( s_in_spim_csn1              ),
        .in_spim_sck_i              ( s_in_spim_sck               ),

        .in_sdio_clk_i              ( s_in_sdio_clk               ),
        .in_sdio_cmd_i              ( s_in_sdio_cmd               ),
        .in_sdio_data0_i            ( s_in_sdio_data0             ),
        .in_sdio_data1_i            ( s_in_sdio_data1             ),
        .in_sdio_data2_i            ( s_in_sdio_data2             ),
        .in_sdio_data3_i            ( s_in_sdio_data3             ),

        .in_uart_rx_i               ( s_in_uart_rx                ),
        .in_uart_tx_i               ( s_in_uart_tx                ),
        .in_cam_pclk_i              ( s_in_cam_pclk               ),
        .in_cam_hsync_i             ( s_in_cam_hsync              ),
        .in_cam_data0_i             ( s_in_cam_data0              ),
        .in_cam_data1_i             ( s_in_cam_data1              ),
        .in_cam_data2_i             ( s_in_cam_data2              ),
        .in_cam_data3_i             ( s_in_cam_data3              ),
        .in_cam_data4_i             ( s_in_cam_data4              ),
        .in_cam_data5_i             ( s_in_cam_data5              ),
        .in_cam_data6_i             ( s_in_cam_data6              ),
        .in_cam_data7_i             ( s_in_cam_data7              ),
        .in_cam_vsync_i             ( s_in_cam_vsync              ),

        .in_i2c0_sda_i              ( s_in_i2c0_sda               ),
        .in_i2c0_scl_i              ( s_in_i2c0_scl               ),
        .in_i2s0_sck_i              ( s_in_i2s0_sck               ),
        .in_i2s0_ws_i               ( s_in_i2s0_ws                ),
        .in_i2s0_sdi_i              ( s_in_i2s0_sdi               ),
        .in_i2s1_sdi_i              ( s_in_i2s1_sdi               ),

        .oe_spim_sdio0_o            ( s_oe_spim_sdio0             ),
        .oe_spim_sdio1_o            ( s_oe_spim_sdio1             ),
        .oe_spim_sdio2_o            ( s_oe_spim_sdio2             ),
        .oe_spim_sdio3_o            ( s_oe_spim_sdio3             ),
        .oe_spim_csn0_o             ( s_oe_spim_csn0              ),
        .oe_spim_csn1_o             ( s_oe_spim_csn1              ),
        .oe_spim_sck_o              ( s_oe_spim_sck               ),

        .oe_sdio_clk_o              ( s_oe_sdio_clk               ),
        .oe_sdio_cmd_o              ( s_oe_sdio_cmd               ),
        .oe_sdio_data0_o            ( s_oe_sdio_data0             ),
        .oe_sdio_data1_o            ( s_oe_sdio_data1             ),
        .oe_sdio_data2_o            ( s_oe_sdio_data2             ),
        .oe_sdio_data3_o            ( s_oe_sdio_data3             ),

        .oe_uart_rx_o               ( s_oe_uart_rx                ),
        .oe_uart_tx_o               ( s_oe_uart_tx                ),
        .oe_cam_pclk_o              ( s_oe_cam_pclk               ),
        .oe_cam_hsync_o             ( s_oe_cam_hsync              ),
        .oe_cam_data0_o             ( s_oe_cam_data0              ),
        .oe_cam_data1_o             ( s_oe_cam_data1              ),
        .oe_cam_data2_o             ( s_oe_cam_data2              ),
        .oe_cam_data3_o             ( s_oe_cam_data3              ),
        .oe_cam_data4_o             ( s_oe_cam_data4              ),
        .oe_cam_data5_o             ( s_oe_cam_data5              ),
        .oe_cam_data6_o             ( s_oe_cam_data6              ),
        .oe_cam_data7_o             ( s_oe_cam_data7              ),
        .oe_cam_vsync_o             ( s_oe_cam_vsync              ),

        .oe_i2c0_sda_o              ( s_oe_i2c0_sda               ),
        .oe_i2c0_scl_o              ( s_oe_i2c0_scl               ),
        .oe_i2s0_sck_o              ( s_oe_i2s0_sck               ),
        .oe_i2s0_ws_o               ( s_oe_i2s0_ws                ),
        .oe_i2s0_sdi_o              ( s_oe_i2s0_sdi               ),
        .oe_i2s1_sdi_o              ( s_oe_i2s1_sdi               ),

        .boot_l2_o                  ( s_boot_l2                   ),
        .*
   );

   // SOC DOMAIN
   soc_domain #(
      .CORE_TYPE          ( CORE_TYPE                  ),
      .USE_FPU            ( USE_FPU                    ),
      .AXI_ADDR_WIDTH     ( AXI_ADDR_WIDTH             ),
      .AXI_DATA_IN_WIDTH  ( AXI_CLUSTER_SOC_DATA_WIDTH ),
      .AXI_DATA_OUT_WIDTH ( AXI_SOC_CLUSTER_DATA_WIDTH ),
      .AXI_ID_IN_WIDTH    ( AXI_CLUSTER_SOC_ID_WIDTH   ),
      .AXI_ID_OUT_WIDTH   ( AXI_SOC_CLUSTER_ID_WIDTH   ),
      .AXI_USER_WIDTH     ( AXI_USER_WIDTH             ),
      .AXI_STRB_IN_WIDTH  ( AXI_CLUSTER_SOC_STRB_WIDTH ),
      .AXI_STRB_OUT_WIDTH ( AXI_SOC_CLUSTER_STRB_WIDTH ),
      .BUFFER_WIDTH       ( BUFFER_WIDTH               ),
      .EVNT_WIDTH         ( EVENT_WIDTH                )
   ) soc_domain_i (

        .ref_clk_i                    ( s_ref_clk                        ),
        .slow_clk_i                   ( s_slow_clk                       ),
        .test_clk_i                   ( s_test_clk                       ),

        .rstn_glob_i                  ( s_rstn_por                       ),
    `ifdef PULP_FPGA_EMUL
        .zynq_soc_clk_i               ( zynq_soc_clk_i                   ),
        .zynq_cluster_clk_i           ( zynq_cluster_clk_i               ),
    `endif

        .sel_fll_clk_i                ( s_sel_fll_clk                    ),

        .mode_select_i                ( s_mode_select                    ),
        .dft_cg_enable_i              ( s_dft_cg_enable                  ),
        .dft_test_mode_i              ( s_test_mode                      ),

        .soc_jtag_reg_o               ( s_soc_jtag_regi                  ),
        .soc_jtag_reg_i               ( s_soc_jtag_rego                  ),

        .boot_l2_i                    ( s_boot_l2                        ),

        .jtag_tck_i                   ( s_jtag_tck                       ),
        .jtag_trst_ni                 ( s_jtag_trst                      ),
        .jtag_shift_dr_i              ( s_jtag_shift_dr                  ),
        .jtag_update_dr_i             ( s_jtag_update_dr                 ),
        .jtag_capture_dr_i            ( s_jtag_capture_dr                ),
        .jtag_axireg_sel_i            ( s_axireg_sel                     ),
        .jtag_axireg_tdi_i            ( s_axireg_tdi                     ),
        .jtag_axireg_tdo_o            ( s_axireg_tdo                     ),

        .pad_cfg_o                    ( s_pad_cfg_soc                    ),
        .pad_mux_o                    ( s_pad_mux_soc                    ),

        .gpio_in_i                    ( s_gpio_in                        ),
        .gpio_out_o                   ( s_gpio_out                       ),
        .gpio_dir_o                   ( s_gpio_dir                       ),
        .gpio_cfg_o                   ( s_gpio_cfg                       ),

        .uart_tx_o                    ( s_uart_tx                        ),
        .uart_rx_i                    ( s_uart_rx                        ),

        .cam_clk_i                    ( s_cam_pclk                       ),
        .cam_data_i                   ( s_cam_data                       ),
        .cam_hsync_i                  ( s_cam_hsync                      ),
        .cam_vsync_i                  ( s_cam_vsync                      ),

        .timer_ch0_o                  ( s_timer0                         ),
        .timer_ch1_o                  ( s_timer1                         ),
        .timer_ch2_o                  ( s_timer2                         ),
        .timer_ch3_o                  ( s_timer3                         ),

        .i2c0_scl_i                   ( s_i2c0_scl_in                    ),
        .i2c0_scl_o                   ( s_i2c0_scl_out                   ),
        .i2c0_scl_oe_o                ( s_i2c0_scl_oe                    ),
        .i2c0_sda_i                   ( s_i2c0_sda_in                    ),
        .i2c0_sda_o                   ( s_i2c0_sda_out                   ),
        .i2c0_sda_oe_o                ( s_i2c0_sda_oe                    ),

        .i2c1_scl_i                   ( s_i2c1_scl_in                    ),
        .i2c1_scl_o                   ( s_i2c1_scl_out                   ),
        .i2c1_scl_oe_o                ( s_i2c1_scl_oe                    ),
        .i2c1_sda_i                   ( s_i2c1_sda_in                    ),
        .i2c1_sda_o                   ( s_i2c1_sda_out                   ),
        .i2c1_sda_oe_o                ( s_i2c1_sda_oe                    ),

        .i2s_sd0_i                    ( s_i2s_sd0_in                     ),
        .i2s_sd1_i                    ( s_i2s_sd1_in                     ),
        .i2s_ws_i                     ( s_i2s_ws_in                      ),
        .i2s_sck_i                    ( s_i2s_sck_in                     ),
        .i2s_ws0_o                    ( s_i2s_ws0_out                    ),
        .i2s_sck0_o                   ( s_i2s_sck0_out                   ),
        .i2s_mode0_o                  ( s_i2s_mode0_out                  ),
        .i2s_ws1_o                    ( s_i2s_ws1_out                    ),
        .i2s_sck1_o                   ( s_i2s_sck1_out                   ),
        .i2s_mode1_o                  ( s_i2s_mode1_out                  ),

        .spi_master0_clk_o            ( s_spi_master0_sck                ),
        .spi_master0_csn0_o           ( s_spi_master0_csn0               ),
        .spi_master0_csn1_o           ( s_spi_master0_csn1               ),
        .spi_master0_mode_o           ( s_spi_master0_mode               ),
        .spi_master0_sdo0_o           ( s_spi_master0_sdo0               ),
        .spi_master0_sdo1_o           ( s_spi_master0_sdo1               ),
        .spi_master0_sdo2_o           ( s_spi_master0_sdo2               ),
        .spi_master0_sdo3_o           ( s_spi_master0_sdo3               ),
        .spi_master0_sdi0_i           ( s_spi_master0_sdi0               ),
        .spi_master0_sdi1_i           ( s_spi_master0_sdi1               ),
        .spi_master0_sdi2_i           ( s_spi_master0_sdi2               ),
        .spi_master0_sdi3_i           ( s_spi_master0_sdi3               ),

        .sdio_clk_o                   ( s_sdio_clk                       ),
        .sdio_cmd_o                   ( s_sdio_cmdo                      ),
        .sdio_cmd_i                   ( s_sdio_cmdi                      ),
        .sdio_cmd_oen_o               ( s_sdio_cmd_oen                   ),
        .sdio_data_o                  ( s_sdio_datao                     ),
        .sdio_data_i                  ( s_sdio_datai                     ),
        .sdio_data_oen_o              ( s_sdio_data_oen                  ),

        .cluster_busy_i               ( s_cluster_busy                   ),

        .cluster_events_wt_o          ( s_event_writetoken               ),
        .cluster_events_rp_i          ( s_event_readpointer              ),
        .cluster_events_da_o          ( s_event_dataasync                ),

        .cluster_irq_o                ( s_cluster_irq                    ),

        .dma_pe_evt_ack_o             ( s_dma_pe_evt_ack                 ),
        .dma_pe_evt_valid_i           ( s_dma_pe_evt_valid               ),
        .dma_pe_irq_ack_o             ( s_dma_pe_irq_ack                 ),
        .dma_pe_irq_valid_i           ( s_dma_pe_irq_valid               ),
        .pf_evt_ack_o                 ( s_pf_evt_ack                     ),
        .pf_evt_valid_i               ( s_pf_evt_valid                   ),

        .cluster_pow_o                ( s_cluster_pow                    ),
        .cluster_byp_o                ( s_cluster_byp                    ),

        .data_slave_aw_writetoken_i   ( '0                               ),
        .data_slave_aw_addr_i         ( '0                               ),
        .data_slave_aw_prot_i         ( '0                               ),
        .data_slave_aw_region_i       ( '0                               ),
        .data_slave_aw_len_i          ( '0                               ),
        .data_slave_aw_size_i         ( '0                               ),
        .data_slave_aw_burst_i        ( '0                               ),
        .data_slave_aw_lock_i         ( '0                               ),
        .data_slave_aw_cache_i        ( '0                               ),
        .data_slave_aw_qos_i          ( '0                               ),
        .data_slave_aw_id_i           ( '0                               ),
        .data_slave_aw_user_i         ( '0                               ),
        .data_slave_aw_readpointer_o  (                                  ),

        .data_slave_ar_writetoken_i   ( '0                               ),
        .data_slave_ar_addr_i         ( '0                               ),
        .data_slave_ar_prot_i         ( '0                               ),
        .data_slave_ar_region_i       ( '0                               ),
        .data_slave_ar_len_i          ( '0                               ),
        .data_slave_ar_size_i         ( '0                               ),
        .data_slave_ar_burst_i        ( '0                               ),
        .data_slave_ar_lock_i         ( '0                               ),
        .data_slave_ar_cache_i        ( '0                               ),
        .data_slave_ar_qos_i          ( '0                               ),
        .data_slave_ar_id_i           ( '0                               ),
        .data_slave_ar_user_i         ( '0                               ),
        .data_slave_ar_readpointer_o  (                                  ),

        .data_slave_w_writetoken_i    ( '0                               ),
        .data_slave_w_data_i          ( '0                               ),
        .data_slave_w_strb_i          ( '0                               ),
        .data_slave_w_user_i          ( '0                               ),
        .data_slave_w_last_i          ( '0                               ),
        .data_slave_w_readpointer_o   (                                  ),

        .data_slave_r_writetoken_o    (                                  ),
        .data_slave_r_data_o          (                                  ),
        .data_slave_r_resp_o          (                                  ),
        .data_slave_r_last_o          (                                  ),
        .data_slave_r_id_o            (                                  ),
        .data_slave_r_user_o          (                                  ),
        .data_slave_r_readpointer_i   ( '0                               ),

        .data_slave_b_writetoken_o    (                                  ),
        .data_slave_b_resp_o          (                                  ),
        .data_slave_b_id_o            (                                  ),
        .data_slave_b_user_o          (                                  ),
        .data_slave_b_readpointer_i   ( '0                               ),

        .data_master_aw_writetoken_o  (                                  ),
        .data_master_aw_addr_o        (                                  ),
        .data_master_aw_prot_o        (                                  ),
        .data_master_aw_region_o      (                                  ),
        .data_master_aw_len_o         (                                  ),
        .data_master_aw_size_o        (                                  ),
        .data_master_aw_burst_o       (                                  ),
        .data_master_aw_lock_o        (                                  ),
        .data_master_aw_cache_o       (                                  ),
        .data_master_aw_qos_o         (                                  ),
        .data_master_aw_id_o          (                                  ),
        .data_master_aw_user_o        (                                  ),
        .data_master_aw_readpointer_i ( '0                               ),

        .data_master_ar_writetoken_o  (                                  ),
        .data_master_ar_addr_o        (                                  ),
        .data_master_ar_prot_o        (                                  ),
        .data_master_ar_region_o      (                                  ),
        .data_master_ar_len_o         (                                  ),
        .data_master_ar_size_o        (                                  ),
        .data_master_ar_burst_o       (                                  ),
        .data_master_ar_lock_o        (                                  ),
        .data_master_ar_cache_o       (                                  ),
        .data_master_ar_qos_o         (                                  ),
        .data_master_ar_id_o          (                                  ),
        .data_master_ar_user_o        (                                  ),
        .data_master_ar_readpointer_i ( '0                               ),

        .data_master_w_writetoken_o   (                                  ),
        .data_master_w_data_o         (                                  ),
        .data_master_w_strb_o         (                                  ),
        .data_master_w_user_o         (                                  ),
        .data_master_w_last_o         (                                  ),
        .data_master_w_readpointer_i  ( '0                               ),

        .data_master_r_writetoken_i   ( '0                               ),
        .data_master_r_data_i         ( '0                               ),
        .data_master_r_resp_i         ( '0                               ),
        .data_master_r_last_i         ( '0                               ),
        .data_master_r_id_i           ( '0                               ),
        .data_master_r_user_i         ( '0                               ),
        .data_master_r_readpointer_o  (                                  ),

        .data_master_b_writetoken_i   ( '0                               ),
        .data_master_b_resp_i         ( '0                               ),
        .data_master_b_id_i           ( '0                               ),
        .data_master_b_user_i         ( '0                               ),
        .data_master_b_readpointer_o  (                                  ),

        .cluster_clk_o                (                                  ),
        .cluster_rstn_o               (                                  ),

        .cluster_rtc_o                (                                  ),
        .cluster_fetch_enable_o       (                                  ),
        .cluster_boot_addr_o          (                                  ),
        .cluster_test_en_o            (                                  ),
        .*
    );

assign s_dma_pe_evt_valid               = '0;
assign s_dma_pe_irq_valid               = '0;
assign s_pf_evt_valid                   = '0;
assign s_cluster_busy                   = '0;
assign s_so                             = '0;

`ifdef PULP_FPGA_EMUL
  assign s_rstn    = zynq_rst_n_i;
  assign s_ref_clk = zynq_clk_i;

  // uart
  //+ assign s_safe2soc_uart_tx = (zynq_safen_uart_i == 1'b1) ? zynq2soc_uart_tx_i : s_uart_tx; // safe -> soc
  //+ assign zynq2soc_uart_rx_o = (zynq_safen_uart_i == 1'b1) ? s_uart_rx : 1'b0; // soc -> safe
  //+ assign s_uart_rx          = (zynq_safen_uart_i == 1'b0) ? s_safe2soc_uart_rx : 1'b0;

  // connect pulpchip uart pads or zynq uart wrapper
  // zynq_safen_uart_i ==  0 - enable pulpchip pad connection
  //                       1 - zynq wrapper connection
  assign s_safe2soc_uart_tx          = ~zynq_safen_uart_i ? s_uart_tx : 1'b0;
  assign s_uart_rx                   = ~zynq_safen_uart_i ? s_safe2soc_uart_rx : zynq2soc_uart_rx_i;

  assign zynq2soc_uart_tx_o          = zynq_safen_uart_i ? s_uart_tx : 1'b0;

  // spi master
  assign zynq2soc_spim_sck_o         = (zynq_safen_spim_i == 1'b1) ? s_spi_master0_sck  : 1'b0;
  assign zynq2soc_spim_csn_o         = (zynq_safen_spim_i == 1'b1) ? s_spi_master0_csn0 : 1'b0;
  assign zynq2soc_spim_sdo0_o        = (zynq_safen_spim_i == 1'b1) ? s_spi_master0_sdo0 : 1'b0;
  assign zynq2soc_spim_sdo1_o        = (zynq_safen_spim_i == 1'b1) ? s_spi_master0_sdo1 : 1'b0;
  assign zynq2soc_spim_sdo2_o        = (zynq_safen_spim_i == 1'b1) ? s_spi_master0_sdo2 : 1'b0;
  assign zynq2soc_spim_sdo3_o        = (zynq_safen_spim_i == 1'b1) ? s_spi_master0_sdo3 : 1'b0;

  assign s_safe2soc_spi_master0_sck  = (zynq_safen_spim_i == 1'b0) ? s_spi_master0_sck  : 1'b0;
  assign s_safe2soc_spi_master0_csn0 = (zynq_safen_spim_i == 1'b0) ? s_spi_master0_csn0 : 1'b0;
  assign s_safe2soc_spi_master0_sdo0 = (zynq_safen_spim_i == 1'b0) ? s_spi_master0_sdo0 : 1'b0;
  assign s_safe2soc_spi_master0_sdo1 = (zynq_safen_spim_i == 1'b0) ? s_spi_master0_sdo1 : 1'b0;
  assign s_safe2soc_spi_master0_sdo2 = (zynq_safen_spim_i == 1'b0) ? s_spi_master0_sdo2 : 1'b0;
  assign s_safe2soc_spi_master0_sdo3 = (zynq_safen_spim_i == 1'b0) ? s_spi_master0_sdo3 : 1'b0;
  assign s_spi_master0_sdi0          = (zynq_safen_spim_i == 1'b1) ? zynq2soc_spim_sdi0_i : s_safe2soc_spi_master0_sdi0;
  assign s_spi_master0_sdi1          = (zynq_safen_spim_i == 1'b1) ? zynq2soc_spim_sdi1_i : s_safe2soc_spi_master0_sdi1;
  assign s_spi_master0_sdi2          = (zynq_safen_spim_i == 1'b1) ? zynq2soc_spim_sdi2_i : s_safe2soc_spi_master0_sdi2;
  assign s_spi_master0_sdi3          = (zynq_safen_spim_i == 1'b1) ? zynq2soc_spim_sdi3_i : s_safe2soc_spi_master0_sdi3;
`endif

endmodule

