-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Application interface for ePix320kM
-------------------------------------------------------------------------------
-- This file is part of 'ePix320kM firmware'.
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
use surf.SsiCmdMasterPkg.all;

library unisim;
use unisim.vcomponents.all;

use work.AppPkg.all;

entity Application is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType;
      SIMULATION_G : boolean := false
   );
   port (
      ----------------------
      -- Top Level Ports --
      ----------------------
      axiClk            : in sl;
      axiRst            : in sl;

      -- AXI-Lite Register Interface (sysClk domain)
      -- Register Address Range = [0x80000000:0xFFFFFFFF]
      axilReadMaster    : in  AxiLiteReadMasterType;
      axilReadSlave     : out AxiLiteReadSlaveType;
      axilWriteMaster   : in  AxiLiteWriteMasterType;
      axilWriteSlave    : out AxiLiteWriteSlaveType;

      -- Streaming Interfaces (axilClk domain)
      asicDataMasters    : out AxiStreamMasterArray(3 downto 0);
      asicDataSlaves     : in  AxiStreamSlaveArray(3 downto 0);
      remoteDmaPause     : in  slv(3 downto 0);
      oscopeMasters      : out AxiStreamMasterArray(3 downto 0);
      oscopeSlaves       : in  AxiStreamSlaveArray(3 downto 0);
      slowAdcMasters     : out AxiStreamMasterArray(3 downto 0);
      slowAdcSlaves      : in  AxiStreamSlaveArray(3 downto 0);

      -- SSI commands
      ssiCmd             : in SsiCmdMasterType;

      -- Transceiver high speed lanes
      fpgaOutObTransInP  : out slv(11 downto 8);
      fpgaOutObTransInM  : out slv(11 downto 8);
      fpgaInObTransOutP  : in  slv(11 downto 8);
      fpgaInObTransOutM  : in  slv(11 downto 8);

      -- ASIC Data Outs
      asicDataP          : in Slv24Array(NUMBER_OF_ASICS_C -1 downto 0);
      asicDataM          : in Slv24Array(NUMBER_OF_ASICS_C -1 downto 0);

      -- Fast ADC Ports
      adcMonDoutP        : in slv(11 downto 0);
      adcMonDoutM        : in slv(11 downto 0);
      adcDoClkP          : in slv(1 downto 0);
      adcDoClkM          : in slv(1 downto 0);
      adcFrameClkP       : in slv(1 downto 0);
      adcFrameClkM       : in slv(1 downto 0);

      -- ASIC Control Ports
      asicR0             : out sl;
      asicGlblRst        : out sl;
      asicSync           : out sl;
      asicAcq            : out sl;
      asicSro            : out sl;
      asicClkEn          : out sl;
      fpgaRdClkP         : out sl;
      fpgaRdClkM         : out sl;

      -- SACI Ports
      saciCmd            : out sl;
      saciClk            : out sl;
      saciSel            : out slv(3 downto 0);
      saciRsp            : in  sl;

      -- Spare ports both to carrier and to p&cb
      pcbSpare           : inout slv(5 downto 0);
      spareM             : inout slv(1 downto 0);
      spareP             : inout slv(1 downto 0);

      -- GT Clock Ports
      gtPllClkP          : in sl;
      gtPllClkM          : in sl;
      gtRefClkP          : in sl;
      gtRefClkM          : in sl;

      -- Bias Dac
      biasDacDin         : out sl;
      biasDacSclk        : out sl;
      biasDacCsb         : out sl;
      biasDacClrb        : out sl;

      -- High speed dac
      hsDacSclk          : out sl;
      hsDacDin           : out sl;
      hsCsb              : out sl;
      hsLdacb            : out sl;

      -- Digital Monitor
      digMon             : in slv(1 downto 0);

      -- External trigger Connector
      runToFpga          : in  sl;
      daqToFpga          : in  sl;
      ttlToFpga          : in  sl;
      fpgaTtlOut         : out sl;
      fpgaMps            : out sl;
      fpgaTg             : out sl;

      -- Fpga Clock IO
      fpgaClkInP         : in  sl;
      fpgaClkInM         : in  sl;
      fpgaClkOutP        : out sl;
      fpgaClkOutM        : out sl;

      -- Power and communication env Monitor
      pcbAdcDrdyL        : in  sl;
      pcbAdcData         : in  sl;
      pcbAdcCsb          : out sl;
      pcbAdcSclk         : out sl;
      pcbAdcDin          : out sl;
      pcbAdcSyncL        : out sl;
      pcbAdcRefClk       : out sl;

      -- Serial number
      serialNumber       : inout slv(2 downto 0);

      -- Power 
      syncDcdc           : out slv(6 downto 0);
      ldoShtdnL          : out slv(1 downto 0);
      dcdcSync           : out sl;
      pcbSync            : out sl;
      pcbLocalSupplyGood : in  sl;

      -- Digital board env monitor
      adcSpiClk          : out sl;
      adcSpiData         : in  sl;
      adcMonClkP         : out sl;
      adcMonClkM         : out sl;
      adcMonPdwn         : out sl;
      adcMonSpiCsb       : out sl;
      slowAdcDout        : in  sl;
      slowAdcDrdyL       : in  sl;
      slowAdcSyncL       : out sl;
      slowAdcSclk        : out sl;
      slowAdcCsb         : out sl;
      slowAdcDin         : out sl;
      slowAdcRefClk      : out sl
   );
end entity;


architecture rtl of Application is

   constant NUM_AXIL_MASTERS_C         : natural := 4;
   constant NUM_AXIL_SLAVES_C          : natural := 1;

   constant PLLREGS_AXI_INDEX_C        : natural := 0;
   constant ASIC_INDEX_C               : natural := 1;
   constant POWER_CONTROL_INDEX_C      : natural := 3;
   constant DESER_INDEX_C              : natural := 2;

   constant AXI_BASE_ADDR_C            : slv(31 downto 0) := X"80000000"; --0

   constant XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXI_BASE_ADDR_C, 28, 24);

   -- AXI-Lite Signals
   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0); 
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_SLVERR_C); 
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0); 
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_READ_SLAVE_EMPTY_SLVERR_C);

   signal fabRefClk        : sl;
   signal fabClock         : sl;
   signal refClk           : sl;
   signal sysRst           : sl;
   signal adcClk           : sl;
   signal appClk           : sl;
   signal refRst           : sl;
   signal adcRst           : sl;
   signal appRst           : sl;
   signal fpgaPllClk       : sl;
   signal pllRst           : sl;
   signal fabReset         : sl;
   signal asicRdClk        : slv(NUMBER_OF_ASICS_C - 1 downto 0);

   signal sspClk           : sl;
   signal sspRst           : sl;
   signal sspLinkUp        : Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
   signal sspValid         : Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
   signal sspData          : Slv16Array((NUMBER_OF_ASICS_C * 24)-1 downto 0);
   signal sspSof           : Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
   signal sspEof           : Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
   signal sspEofe          : Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);

begin
   U_IBUFDS_GT : IBUFDS_GTE4
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00"
      )
      port map (
         I     => gtRefClkP,
         IB    => gtRefClkM,
         CEB   => '0',
         ODIV2 => open,
         O     => fabRefClk
      );

   U_BUFG_GT : BUFG_GT
      port map (
         I       => fabRefClk,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",              -- Divide by 1
         O       => fabClock
      );
  
   U_fpgaToAdcClk : entity surf.ClkOutBufDiff
      generic map(
         TPD_G        => TPD_G,
         XIL_DEVICE_G => XIL_DEVICE_C
      )
      port map (
         clkIn   => adcClk,
         clkOutP => adcMonClkP,
         clkOutN => adcMonClkM
      );
   
   U_PwrUpRst : entity surf.PwrUpRst
      generic map(
         TPD_G         => TPD_G,
         SIM_SPEEDUP_G => SIMULATION_G)
      port map(
         clk    => fabClock,
         rstOut => fabReset
      );
   
   U_AxiLiteCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         NUM_SLAVE_SLOTS_G  => NUM_AXIL_SLAVES_C,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => XBAR_CONFIG_C
      )
      port map (                
         sAxiWriteMasters(0)    => axilWriteMaster,    -- to entity
         sAxiWriteSlaves(0)     => axilWriteSlave,     -- to entity
         sAxiReadMasters(0)     => axilReadMaster,     -- to entity
         sAxiReadSlaves(0)      => axilReadSlave,      -- to entity
         mAxiWriteMasters       => axilWriteMasters,   -- to masters
         mAxiWriteSlaves        => axilWriteSlaves,    -- to masters
         mAxiReadMasters        => axilReadMasters,    -- to masters
         mAxiReadSlaves         => axilReadSlaves,     -- to masters
         axiClk                 => axiClk,
         axiClkRst              => axiRst
      );

   ------------------------------------------------
   --    Generate clocks from 156.25 MHz PGP     --
   ------------------------------------------------
   -- clkIn     : 156.25 MHz PGP
   -- base clk is 1000 MHz
   -- clkOut(0) : 160.00 MHz ASIC ref clock
   -- clkOut(1) : 50.00  MHz adc clock
   -- clkOut(2) : 100.00 MHz app clock
   -- clkOut(3) : 40.00 MHz  pll Clk
   ------------------------------------------------
   U_CoreClockGen : entity surf.ClockManagerUltraScale
      generic map(
         TPD_G                  => 1 ns,
         TYPE_G                 => "MMCM",  -- or "PLL"
         INPUT_BUFG_G           => true,
         FB_BUFG_G              => true,
         RST_IN_POLARITY_G      => '1',     -- '0' for active low
         NUM_CLOCKS_G           => 4,
         SIMULATION_G           => SIMULATION_G,
         -- MMCM attributes
         BANDWIDTH_G            => "OPTIMIZED",
         CLKIN_PERIOD_G         => 6.4,      -- 156.25 MHz
         DIVCLK_DIVIDE_G        => 5,        -- 31.25 MHz = 156.25Mhz / 5
         CLKFBOUT_MULT_F_G      => 32.0,     -- 1.0 Ghz = 31.25 MHz * 32
         CLKFBOUT_MULT_G        => 5,
         CLKOUT0_DIVIDE_F_G     => 6.25,     -- 160 MHz = 1 GHz / 6.25
         CLKOUT0_DIVIDE_G       => 1,
         CLKOUT1_DIVIDE_G       => 20,       -- 50 Mhz = 1 GHz / 20
         CLKOUT2_DIVIDE_G       => 10,       -- 100 Mhz = 1 GHz / 10
         CLKOUT3_DIVIDE_G       => 25,       -- 40 Mhz = 1 GHz / 25
         CLKOUT0_PHASE_G        => 0.0,
         CLKOUT1_PHASE_G        => 0.0,
         CLKOUT2_PHASE_G        => 0.0,
         CLKOUT3_PHASE_G        => 0.0,
         CLKOUT0_DUTY_CYCLE_G   => 0.5,
         CLKOUT1_DUTY_CYCLE_G   => 0.5,
         CLKOUT2_DUTY_CYCLE_G   => 0.5,
         CLKOUT3_DUTY_CYCLE_G   => 0.5,
         CLKOUT0_RST_HOLD_G     => 3,
         CLKOUT1_RST_HOLD_G     => 3,
         CLKOUT2_RST_HOLD_G     => 3,
         CLKOUT3_RST_HOLD_G     => 3,
         CLKOUT0_RST_POLARITY_G => '1',
         CLKOUT1_RST_POLARITY_G => '1',
         CLKOUT2_RST_POLARITY_G => '1',
         CLKOUT3_RST_POLARITY_G => '1'
   )
      port map(
         clkIn           => fabClock,
         rstIn           => fabReset,
         clkOut(0)       => refClk,
         clkOut(1)       => adcClk,
         clkOut(2)       => appClk,
         clkOut(3)       => fpgaPllClk,
         rstOut(0)       => refRst,
         rstOut(1)       => adcRst,
         rstOut(2)       => appRst,
         rstOut(3)       => pllRst,
         locked          => open,
         -- AXI-Lite Interface
         axilClk         => axiClk,
         axilRst         => axiRst,
         axilReadMaster  => axilReadMasters(PLLREGS_AXI_INDEX_C),
         axilReadSlave   => axilReadSlaves(PLLREGS_AXI_INDEX_C),
         axilWriteMaster => axilWriteMasters(PLLREGS_AXI_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(PLLREGS_AXI_INDEX_C)
   );

   U_AsicTop : entity work.AsicTop
      generic map (
         TPD_G            => TPD_G,
         SIMULATION_G     => SIMULATION_G,
         BUILD_INFO_G     => BUILD_INFO_G,
         AXIL_BASE_ADDR_G => XBAR_CONFIG_C(ASIC_INDEX_C).baseAddr
      )
      port map (
         -- AXI-Lite Interface (axilClk domain)
         axiClk          => axiClk,
         axiRst          => axiRst,
         axilReadMaster  => axilReadMasters(ASIC_INDEX_C),
         axilReadSlave   => axilReadSlaves(ASIC_INDEX_C),
         axilWriteMaster => axilWriteMasters(ASIC_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(ASIC_INDEX_C),

         -- Streaming Interfaces (axilClk domain)
         asicDataMasters => asicDataMasters,
         asicDataSlaves  => asicDataSlaves,
         remoteDmaPause  => remoteDmaPause,
         
         -- ASIC control ports
         asicR0          => asicR0,
         asicGlblRst     => asicGlblRst,
         asicSync        => asicSync,
         asicAcq         => asicAcq,
         asicSro         => asicSro,
         asicClkEn       => asicClkEn,

         -- Clocking ports
         refClk          => refClk,
         refRst          => refRst,

         -- appClk          => appClk,
         -- appRst          => appRst,

         -- SSI commands
         ssiCmd         => ssiCmd,

         -- External trigger inputs
         daqToFpga      => daqToFpga,
         ttlToFpga      => ttlToFpga,

         -- ref ports
         refClk          => refClk,
         refRst          => refRst
      );

   U_PwrCtrl : entity work.PowerCtrl
      generic map (
         TPD_G             => TPD_G,
         EN_DEVICE_DNA_G   => EN_DEVICE_DNA_G
      )
      port map (
         axiClk             => axiClk,
         axiRst             => axiRst,
         axilReadMaster     => axilReadMasters(POWER_CONTROL_INDEX_C),
         axilReadSlave      => axilReadSlaves(POWER_CONTROL_INDEX_C),
         axilWriteMaster    => axilWriteMasters(POWER_CONTROL_INDEX_C),
         axilWriteSlave     => axilWriteSlaves(POWER_CONTROL_INDEX_C),
         syncDcdc           => syncDcdc,
         ldoShtdnL          => ldoShtdnL,
         dcdcSync           => dcdcSync,
         pcbSync            => pcbSync,
         pcbLocalSupplyGood => pcbLocalSupplyGood
      );
   
   U_Deser : entity work.AppDeser
      generic map (
         TPD_G             => TPD_G,
         SIMULATION_G     => SIMULATION_G,
         AXIL_BASE_ADDR_G => XBAR_CONFIG_C(DESER_INDEX_C).baseAddr
      )
      port map (
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axiClk,
         axilRst         => axiRst,
         axilReadMaster  => axilReadMasters(DESER_INDEX_C),
         axilReadSlave   => axilReadSlaves(DESER_INDEX_C),
         axilWriteMaster => axilWriteMasters(DESER_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(DESER_INDEX_C),
         -- ASIC Ports
         asicDataP       => asicDataP,
         asicDataN       => asicDataM,
         -- ref ports
         refClk          => refClk,
         refRst          => refRst,
         -- Streaming Interfaces (sspClk domain)
         sspClk          => sspClk,
         sspRst          => sspRst,
         sspLinkUp       => sspLinkUp,
         sspValid        => sspValid,
         sspData         => sspData,
         sspSof          => sspSof,
         sspEof          => sspEof,
         sspEofe         => sspEofe,
         -- ASIC RdOut Clks
         asicRdClk      => asicRdClk
      );
   
   U_fpgaToAsicClk : entity surf.ClkOutBufDiff
      generic map(
         TPD_G        => TPD_G,
         XIL_DEVICE_G => XIL_DEVICE_C
      )
      port map (
         clkIn   => asicRdClk(0),
         clkOutP => fpgaClkOutP,
         clkOutN => fpgaClkOutM
      );


   end rtl; -- rtl