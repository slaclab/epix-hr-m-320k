-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Wrapper for ADC modules
-------------------------------------------------------------------------------
-- This file is part of 'Simple-PGPv4-KCU105-Example'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'Simple-PGPv4-KCU105-Example', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;
use surf.Ad9249Pkg.all;

library epix_hr_core;

library epix_leap_core;
use epix_leap_core.CorePkg.all;

library unisim;
use unisim.vcomponents.all;

entity AdcMon is
   generic (
      TPD_G                : time := 1 ns;
      AXIL_BASE_ADDR_G     : slv(31 downto 0);
      NUM_OF_SLOW_ADCS_G   : integer := 2;
      NUM_OF_PSCOPE_G      : integer := 4       -- Related to the number of fast adcs
   );                                           -- NUM_OF_PSCOPE_G * 4 
   port (
      -- Clock and Reset
      clk156          : in    sl;
      rst156          : in    sl;
      -- Trigger Interlace (axilClk domain)
      oscopeAcqStart  : in    slv(NUM_OF_PSCOPE_G - 1 downto 0);
      oscopeTrigBus   : in    slv(11 downto 0);
      slowAdcAcqStart : in    slv(NUM_OF_SLOW_ADCS_G - 1 downto 0);
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      -- Streaming Interfaces (axilClk domain)
      oscopeMasters   : out   AxiStreamMasterArray( NUM_OF_PSCOPE_G - 1 downto 0);
      oscopeSlaves    : in    AxiStreamSlaveArray( NUM_OF_PSCOPE_G - 1 downto 0);
      slowAdcMasters  : out   AxiStreamMasterArray(NUM_OF_SLOW_ADCS_G - 1 downto 0);
      slowAdcSlaves   : in    AxiStreamSlaveArray(NUM_OF_SLOW_ADCS_G -1 downto 0);
      -------------------
      --  Top Level Ports
      -------------------
      -- Slow ADC Ports
      slowAdcCsL      : out   slv(NUM_OF_SLOW_ADCS_G - 1 downto 0);
      slowAdcSclk     : out   sl;
      slowAdcDin      : out   sl;
      slowAdcSyncL    : out   sl;
      slowAdcDout     : in    sl;
      slowAdcDrdyL    : in    sl;
      slowAdcRefClk   : out   sl;
      -- ADC Monitor Ports
      adcMonSpiCsL    : out   sl;
      adcMonPdwn      : out   sl;
      adcMonSpiClk    : out   sl;
      adcMonSpiData   : inout sl;
      adcMonClkOutP   : out   sl;
      adcMonClkOutM   : out   sl;
      adcMonDoutP     : in    Slv8Array(1 downto 0);
      adcMonDoutM     : in    Slv8Array(1 downto 0);
      adcMonFrameClkP : in    slv(1 downto 0);
      adcMonFrameClkM : in    slv(1 downto 0);
      adcMonDataClkP  : in    slv(1 downto 0);
      adcMonDataClkM  : in    slv(1 downto 0)
    );
end AdcMon;

architecture mapping of AdcMon is

   constant MONADC_INDEX_C     : natural  := 0;    -- 0:1
   constant SCOPE_INDEX_C      : natural  := 2;    -- 2:5
   constant ADC_RD_INDEX_C     : natural  := 6;    -- 6:7
   constant ADC_CFG_INDEX_C    : natural  := 8;    -- 8
   constant NUM_AXIL_MASTERS_C : positive := 9;

   constant XBAR_CONFIG_C      : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 20, 16);

   signal axilWriteMasters     : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves      : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_SLVERR_C);
   signal axilReadMasters      : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves       : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_SLVERR_C);

   signal slowAdcCsLVec        : slv(1 downto 0);
   signal slowAdcSclkVec       : slv(1 downto 0);
   signal slowAdcDinVec        : slv(1 downto 0);
   signal slowAdcRefClkVec     : slv(1 downto 0);

   signal adcDclk              : slv(1 downto 0);
   signal adcBitClk            : slv(1 downto 0);
   signal adcBitClkDiv4        : slv(1 downto 0);
   signal adcBitRst            : slv(1 downto 0);
   signal adcBitRstDiv4        : slv(1 downto 0);


   signal adcValid             : slv(15 downto 0);
   signal adcData              : Slv16Array(15 downto 0);
   signal adcStreams           : AxiStreamMasterArray(15 downto 0) := (others=>AXI_STREAM_MASTER_INIT_C);
   signal monAdc               : Ad9249SerialGroupArray(NUM_OF_PSCOPE_G - 1 downto 0);

   signal adcClk               : sl;
   signal adcRst               : sl;

   signal adcSpiCsL_i          : slv(1 downto 0);
   signal adcPdwn_i            : slv(0 downto 0);

begin

   U_adcClk : entity surf.ClockManagerUltraScale
      generic map(
         TPD_G              => TPD_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => false,
         FB_BUFG_G          => true,
         RST_IN_POLARITY_G  => '1',
         NUM_CLOCKS_G       => 1,
         -- MMCM attributes
         CLKIN_PERIOD_G     => 6.4,     -- 156.25 MHz
         DIVCLK_DIVIDE_G    => 5,       -- 31.25 MHz = 156.25 MHz/5
         CLKFBOUT_MULT_F_G  => 32.0,    -- 1GHz = 32 x 31.25 MHz
         CLKOUT0_DIVIDE_F_G => 20.0     -- 50 MHz = 1GHz/20
      )
      port map(
         -- Clock Input
         clkIn     => clk156,
         rstIn     => rst156,
         -- Clock Outputs
         clkOut(0) => adcClk,
         -- Reset Outputs
         rstOut(0) => adcRst
      );

   U_adcClkOut : entity surf.ClkOutBufDiff
      generic map (
         TPD_G        => TPD_G,
         XIL_DEVICE_G => XIL_DEVICE_C
      )
      port map (
         clkIn   => adcClk,
         clkOutP => adcMonClkOutP,
         clkOutN => adcMonClkOutM
      );

   ---------------------------
   -- AXI-Lite Crossbar Module
   ---------------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => XBAR_CONFIG_C
      )
      port map (
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves,
         axiClk              => axilClk,
         axiClkRst           => axilRst
      );

   -----------------------
   -- Virtual oscilloscope
   -----------------------
   GEN_OSCOPE :
   for i in NUM_OF_PSCOPE_G - 1 downto 0 generate
      U_PseudoScope : entity work.PseudoScopeAxi
         generic map (
         TPD_G                      => TPD_G,
         MASTER_AXI_STREAM_CONFIG_G => APP_AXIS_CONFIG_C
      )
         port map (
         sysClk           => axilClk,
         sysClkRst        => axilRst,
         adcData          => adcData(4*i+3 downto 4*i),
         adcValid         => adcValid(4*i+3 downto 4*i),
         arm              => oscopeAcqStart(i),
         triggerIn        => oscopeTrigBus,
         mAxisMaster      => oscopeMasters(i),
         mAxisSlave       => oscopeSlaves(i),
         -- AXI lite slave port for register access
         axilClk          => axilClk,
         axilRst          => axilRst,
         sAxilWriteMaster => axilWriteMasters(SCOPE_INDEX_C + i),
         sAxilWriteSlave  => axilWriteSlaves(SCOPE_INDEX_C + i),
         sAxilReadMaster  => axilReadMasters(SCOPE_INDEX_C + i),
         sAxilReadSlave   => axilReadSlaves(SCOPE_INDEX_C + i)
         );
   
         GenAdcStr : for j in 0 to NUM_OF_PSCOPE_G - 1 generate
            adcData(4*i+j)  <= adcStreams(4*i+j).tData(15 downto 0);
            adcValid(4*i+j) <= adcStreams(4*i+j).tValid;
         end generate;
   end generate GEN_OSCOPE ;

   GEN_FAST_ADC :
   for i in 1 downto 0 generate
      monAdc(i).fClkP           <= adcMonFrameClkP(i);
      monAdc(i).fClkN           <= adcMonFrameClkM(i);
      monAdc(i).dClkP           <= adcMonDataClkP(i);
      monAdc(i).dClkN           <= adcMonDataClkM(i);
      monAdc(i).chP(7 downto 0) <= adcMonDoutP(i);
      monAdc(i).chN(7 downto 0) <= adcMonDoutM(i);
   
      U_IBUFDS : IBUFDS
         port map (
            I  => adcMonDataClkP(i),
            IB => adcMonDataClkM(i),
            O  => adcDclk(i)
         );

      ------------------------------------------
      -- Generate clocks from ADC incoming clock
      ------------------------------------------
      -- clkIn     : 350.00 MHz ADC clock
      -- clkOut(0) : 350.00 MHz adcBitClk clock
      -- clkOut(1) :  87.50 MHz adcBitClkDiv4 clock
      U_iserdesClockGen : entity surf.ClockManagerUltraScale
         generic map(
            TPD_G             => TPD_G,
            TYPE_G            => "PLL",
            INPUT_BUFG_G      => true,
            FB_BUFG_G         => true,
            RST_IN_POLARITY_G => '1',
            NUM_CLOCKS_G      => 2,
            -- MMCM attributes
            CLKIN_PERIOD_G    => 2.85,  -- 350MHz
            CLKFBOUT_MULT_G   => 3,     -- 1050MHz = 3 x 350MHz
            CLKOUT0_DIVIDE_G  => 3,     -- 350MHz = 1050MHz/3
            CLKOUT1_DIVIDE_G  => 12     -- 87.5MHz = 1050MHz/12
         )
         port map(
            clkIn     => adcDclk(i),
            rstIn     => '0',
            clkOut(0) => adcBitClk(i),
            clkOut(1) => adcBitClkDiv4(i),
            rstOut(0) => adcBitRst(i),
            rstOut(1) => adcBitRstDiv4(i)
         );

   U_MonAdcReadout : entity surf.Ad9249ReadoutGroup
      generic map (
         TPD_G           => TPD_G,
         SIM_DEVICE_G    => XIL_DEVICE_C,
         NUM_CHANNELS_G  => 8,
         DEFAULT_DELAY_G => (others => '0'),
         ADC_INVERT_CH_G => "00000000",
         USE_MMCME_G     => false
      )
      port map (
         -- Master system clock
         axilClk         => axilClk,
         axilRst         => axilRst,
         -- Axi Interface
         axilReadMaster  => axilReadMasters(ADC_RD_INDEX_C + i),
         axilReadSlave   => axilReadSlaves(ADC_RD_INDEX_C + i),
         axilWriteMaster => axilWriteMasters(ADC_RD_INDEX_C + i),
         axilWriteSlave  => axilWriteSlaves(ADC_RD_INDEX_C + i),
         -- Reset for adc deserializer (axilClk domain)
         adcClkRst       => '0',
         -- clocks must be provided with USE_MMCME_G = false
         adcBitClkIn     => adcBitClk(i),
         adcBitClkDiv4In => adcBitClkDiv4(i),
         adcBitRstIn     => adcBitRst(i),
         adcBitRstDiv4In => adcBitRstDiv4(i),
         -- Serial Data from ADC
         adcSerial       => monAdc(i),
         -- Deserialized ADC Data
         adcStreamClk    => axilClk,
         adcStreams      => adcStreams(8*i+7 downto 8*i)
      );
   
   end generate;

   U_AdcConf : entity surf.Ad9249Config
   generic map (
      TPD_G             => TPD_G,
      AXIL_CLK_PERIOD_G => AXIL_CLK_PERIOD_C,
      NUM_CHIPS_G       => 1)
   port map (
      -- AXI-Lite Interface
      axilClk         => axilClk,
      axilRst         => axilRst,
      axilReadMaster  => axilReadMasters(ADC_CFG_INDEX_C),
      axilReadSlave   => axilReadSlaves(ADC_CFG_INDEX_C),
      axilWriteMaster => axilWriteMasters(ADC_CFG_INDEX_C),
      axilWriteSlave  => axilWriteSlaves(ADC_CFG_INDEX_C),
      -- SPI Ports
      adcPdwn         => adcPdwn_i,
      adcSclk         => adcMonSpiClk,
      adcSdio         => adcMonSpiData,
      adcCsb          => adcSpiCsL_i
      );

   --------------------
   --  Slow ADC Readout
   --------------------
   GEN_SLOW_ADC :
   for i in NUM_OF_SLOW_ADCS_G - 1 downto 0 generate
      U_AdcCntrl : entity epix_hr_core.SlowAdcCntrlAxi
         generic map (
         SYS_CLK_PERIOD_G  => AXIL_CLK_PERIOD_C,
         ADC_CLK_PERIOD_G  => 200.0E-9,  -- 5MHz
         SPI_SCLK_PERIOD_G => 2.0E-6)    -- 500kHz
         port map (
         -- Master system clock
         sysClk           => axilClk,
         sysClkRst        => axilRst,
         -- Trigger Control
         adcStart         => slowAdcAcqStart(i),
         -- AXI lite slave port for register access
         axilClk          => axilClk,
         axilRst          => axilRst,
         sAxilWriteMaster => axilWriteMasters(MONADC_INDEX_C + i),
         sAxilWriteSlave  => axilWriteSlaves(MONADC_INDEX_C + i),
         sAxilReadMaster  => axilReadMasters(MONADC_INDEX_C + i),
         sAxilReadSlave   => axilReadSlaves(MONADC_INDEX_C + i),
         -- AXI stream output
         axisClk          => axilClk,
         axisRst          => axilRst,
         mAxisMaster      => slowAdcMasters(i),
         mAxisSlave       => slowAdcSlaves(i),
         -- ADC Control Signals
         adcRefClk        => slowAdcRefClkVec(i),
         adcDrdy          => slowAdcDrdyL,
         adcSclk          => slowAdcSclkVec(i),
         adcDout          => slowAdcDout,
         adcCsL           => slowAdcCsLVec(i),
         adcDin           => slowAdcDinVec(i)
      );
   end generate GEN_SLOW_ADC;


   slowAdcRefClk <= slowAdcRefClkVec(0);
   slowAdcCsL    <= slowAdcCsLVec;
   slowAdcSyncL  <= '0';

   process(slowAdcCsLVec, slowAdcDinVec, slowAdcSclkVec)
      variable sclk : sl;
      variable din  : sl;
   begin
      sclk := '0';
      din  := '0';
      for i in 0 to NUM_OF_SLOW_ADCS_G - 1 loop
         if (slowAdcCsLVec(i) = '0') then
            sclk := slowAdcSclkVec(i);
            din  := slowAdcDinVec(i);
         end if;
      end loop;
      slowAdcSclk <= sclk;
      slowAdcDin  <= din;
   end process;

end mapping;
