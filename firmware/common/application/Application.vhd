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
use surf.Pgp4Pkg.all;

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;

library l2si_core;
use l2si_core.L2SiPkg.all;

library unisim;
use unisim.vcomponents.all;

use work.AppPkg.all;

library epix_leap_core;
use epix_leap_core.CorePkg.all;

entity Application is
   generic (
      TPD_G             : time := 1 ns;
      BUILD_INFO_G      : BuildInfoType;
      SIMULATION_G      : boolean := false;
      NUM_OF_CARRIER_G  : integer   := 1
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
      oscopeMasters      : out AxiStreamMasterArray(NUM_OF_CARRIER_G - 1 downto 0);
      oscopeSlaves       : in  AxiStreamSlaveArray(NUM_OF_CARRIER_G - 1 downto 0);
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

      -- ASIC Control Ports
      asicR0             : out sl;
      asicGlblRst        : out sl;
      asicSync           : out sl;
      asicAcq            : out sl;
      asicSro            : out sl;
      asicClkEn          : out sl;
      fpgaRdClkP         : out sl;
      fpgaRdClkM         : out sl;
      rdClkSel           : out sl;

      -- SACI Ports
      saciCmd            : out sl;
      saciClk            : out sl;
      saciSel            : out slv(NUMBER_OF_ASICS_C - 1 downto 0);
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
      gtLclsClkP         : in sl;
      gtLclsClkM         : in sl;

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
      digMon               : in slv(1 downto 0);

      -- External trigger Connector
      runToFpga            : in  sl;
      daqToFpga            : in  sl;
      ttlToFpga            : in  sl;
      fpgaTtlOut           : out sl;
      fpgaMps              : out sl;
      fpgaTg               : out sl;

      -- Fpga Clock IO
      fpgaClkInP           : in  sl;
      fpgaClkInM           : in  sl;
      fpgaClkOutP          : out sl;
      fpgaClkOutM          : out sl;

      -- Serial number
      serialNumber         : inout slv(2 downto 0);

      -- Power 
      syncDcdc             : out slv(6 downto 0);
      pwrAnaEn             : out slv(1 downto 0);
      pcbSync              : out sl;
      pwrGood              : in  slv(1 downto 0);

      -- Fast ADC Ports
      adcMonDoutP           : in slv(11 downto 0);
      adcMonDoutM           : in slv(11 downto 0);
      adcMonDataClkP        : in slv(1 downto 0);
      adcMonDataClkM        : in slv(1 downto 0);
      adcMonFrameClkP       : in slv(1 downto 0);
      adcMonFrameClkM       : in slv(1 downto 0);

      -- Digital board env monitor
      adcMonSpiClk          : out sl;
      adcMonSpiData         : inout  sl;
      adcMonClkP            : out sl;
      adcMonClkM            : out sl;
      adcMonPdwn            : out sl;
      adcMonSpiCsL          : out sl;

      slowAdcDout           : in  slv(1 downto 0);
      slowAdcDrdyL          : in  slv(1 downto 0);
      slowAdcSyncL          : out slv(1 downto 0);
      slowAdcSclk           : out slv(1 downto 0);
      slowAdcCsL            : out slv(1 downto 0);
      slowAdcDin            : out slv(1 downto 0);
      slowAdcRefClk         : out slv(1 downto 0);
   
      jitclnrLolL           : in sl
   );
end entity;


architecture rtl of Application is

   constant NUM_AXIL_SLAVES_C    : natural := 1;

   constant SACI_INDEX_C         : natural  := 0;  -- 0:3
   constant DESER_INDEX_C        : natural  := 4;
   constant ASIC_INDEX_C         : natural  := 5;
   constant PWR_INDEX_C          : natural  := 6;
   constant ADC_INDEX_C          : natural  := 7;
   constant DAC_INDEX_C          : natural  := 8;
   constant TIMING_INDEX_C       : natural  := 9;
   constant NUM_AXIL_MASTERS_C   : positive := 10;

   constant AXI_BASE_ADDR_C      : slv(31 downto 0) := X"80000000"; --0

   constant XBAR_CONFIG_C        : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXI_BASE_ADDR_C, 28, 24);

   -- AXI-Lite Signals
   signal axilWriteMasters       : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0); 
   signal axilWriteSlaves        : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_SLVERR_C); 
   signal axilReadMasters        : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0); 
   signal axilReadSlaves         : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_READ_SLAVE_EMPTY_SLVERR_C);

   signal clk156                 : sl;
   signal rst156                 : sl;
   signal clk250                 : sl;
   signal clk100                 : sl;
   signal rst250                 : sl;
   signal sspClk                 : sl;
   signal sspRst                 : sl;
   
   signal sspLinkUp              : Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
   signal sspValid               : Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
   signal sspData                : Slv16Array((NUMBER_OF_ASICS_C * 24)-1 downto 0);
   signal sspSof                 : Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
   signal sspEof                 : Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
   signal sspEofe                : Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);

   signal triggerClk             : sl;
   signal triggerRst             : sl;
   signal triggerData            : TriggerEventDataArray(1 downto 0);

   signal l1Clk                  : sl                    := '0';
   signal l1Rst                  : sl                    := '0';
   signal l1Feedbacks            : TriggerL1FeedbackArray(1 downto 0) := (others => TRIGGER_L1_FEEDBACK_INIT_C);
   signal l1Acks                 : slv (1 downto 0);

   signal eventClk               : sl;
   signal eventRst               : sl;
   signal eventTrigMsgMasters    : AxiStreamMasterArray(1 downto 0);
   signal eventTrigMsgSlaves     : AxiStreamSlaveArray(1 downto 0);
   signal eventTrigMsgCtrl       : AxiStreamCtrlArray(1 downto 0);
   signal eventTimingMsgMasters  : AxiStreamMasterArray(1 downto 0);
   signal eventTimingMsgSlaves   : AxiStreamSlaveArray(1 downto 0);
   signal clearReadout           : slv (1 downto 0) := (others => '0');

   signal v1LinkUp               : sl  := '0';
   signal v2LinkUp               : sl  := '0';

   signal oscopeAcqStart         : sl;
   signal oscopeTrigBus          : slv(11 downto 0);
   signal slowAdcAcqStart        : slv(3 downto 0);
   signal dacTrig                : sl;
   signal boardConfig            : AppConfigType;

   signal asicSyncSig            : sl;
   signal asicAcqSig             : sl;
   signal asicSroSig             : sl;
   signal asicGrSig              : sl;
   signal dacDinSig              : sl;
   signal dacCsLSig              : sl;
   signal dacClrLSig             : sl;
   signal dacLoadSig             : sl;
   signal asicDigRstSig          : sl;
   signal asicClkSyncEnSig       : sl;
   signal slowAdcDinSig          : slv(1 downto 0);
   signal slowAdcSyncLSig        : slv(1 downto 0);
   signal slowAdcRefClkSig       : slv(1 downto 0);

   signal saciClkVec             : sl;
   signal saciCmdVec             : sl;
   signal saciSelSig             : slv(NUMBER_OF_ASICS_C - 1 downto 0);

   signal clk6Meg                : sl;

begin

   saciSel       <= saciSelSig;
   saciClk       <= saciClkVec ;
   saciCmd       <= saciCmdVec ;
   -- asicSync      <= asicSyncSig;
   -- asicAcq       <= asicAcqSig;
   -- asicGlblRst   <= asicGrSig;
   -- dacDin        <= dacDinSig;
   -- dacCsL        <= dacCsLSig;
   -- dacClrL       <= dacClrLSig;
   -- dacLoad       <= dacLoadSig;
   -- asicDigRst    <= asicDigRstSig;
   -- asicClkSyncEn <= asicClkSyncEnSig;
   -- slowAdcDin    <= slowAdcDinSig;    
   -- slowAdcSyncL  <= slowAdcSyncLSig;  
   -- slowAdcRefClk <= slowAdcRefClkSig; 

   
   -- fpgaTtlOut <= 
   --       digMon(0)            when boardConfig.epixhrDbgSel1 = "00000" else
   --       digMon(1)            when boardConfig.epixhrDbgSel1 = "00000" else
   --       asicSyncSig          when boardConfig.epixhrDbgSel1 = "00001" else
   --       asicAcqSig           when boardConfig.epixhrDbgSel1 = "00010" else
   --       asicSroSig           when boardConfig.epixhrDbgSel1 = "00011" else
   --       saciCmdVec(0)        when boardConfig.epixhrDbgSel1 = "00100" else
   --       saciCmdVec(1)        when boardConfig.epixhrDbgSel1 = "00101" else
   --       saciCmdVec(2)        when boardConfig.epixhrDbgSel1 = "00110" else
   --       saciCmdVec(3)        when boardConfig.epixhrDbgSel1 = "00111" else
   --       saciSelSig(0)        when boardConfig.epixhrDbgSel1 = "01000" else
   --       saciSelSig(1)        when boardConfig.epixhrDbgSel1 = "01001" else
   --       saciSelSig(2)        when boardConfig.epixhrDbgSel1 = "01010" else
   --       saciSelSig(3)        when boardConfig.epixhrDbgSel1 = "01011" else   
   --       asicGrSig            when boardConfig.epixhrDbgSel1 = "10010" else
   --       dacDinSig            when boardConfig.epixhrDbgSel1 = "10011" else
   --       dacCsLSig(0)         when boardConfig.epixhrDbgSel1 = "10100" else
   --       dacCsLSig(1)         when boardConfig.epixhrDbgSel1 = "10101" else
   --       dacClrLSig           when boardConfig.epixhrDbgSel1 = "10110" else
   --       dacLoadSig           when boardConfig.epixhrDbgSel1 = "10111" else
   --       saciClkVec(0)        when boardConfig.epixhrDbgSel2 = "00001" else
   --       saciClkVec(1)        when boardConfig.epixhrDbgSel2 = "00010" else
   --       saciClkVec(2)        when boardConfig.epixhrDbgSel2 = "00011" else
   --       saciClkVec(3)        when boardConfig.epixhrDbgSel2 = "00100" else
   --       asicDigRstSig        when boardConfig.epixhrDbgSel2 = "10000" else
   --       asicClkSyncEnSig     when boardConfig.epixhrDbgSel2 = "10001" else   
   --       slowAdcDinSig        when boardConfig.epixhrDbgSel2 = "10010" else
   --       slowAdcDout          when boardConfig.epixhrDbgSel2 = "10011" else
   --       slowAdcDrdyL         when boardConfig.epixhrDbgSel2 = "10100" else
   --       slowAdcRefClkSig     when boardConfig.epixhrDbgSel2 = "10101" else
   --       slowAdcSyncLSig      when boardConfig.epixhrDbgSel2 = "10110" else
   --       saciResp             when boardConfig.epixhrDbgSel2 = "10111" else
   --       '0';

   U_AxiLiteCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         NUM_SLAVE_SLOTS_G      => NUM_AXIL_SLAVES_C,
         NUM_MASTER_SLOTS_G     => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G       => XBAR_CONFIG_C
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

   U_ClkGen : entity work.AppClk
      generic map (
         TPD_G                  => TPD_G,
         SIMULATION_G           => SIMULATION_G
         )
      port map (
         -- 156.25 MHz Clock input
         gtRefClkP              =>  gtRefClkP,
         gtRefClkM              =>  gtRefClkM,
         -- 250 Mhz Pll Output
         gtPllClkP              => gtPllClkP,
         gtPllClkM              => gtPllClkM,
         -- 50 Mhz clock output to pll(2)
         fpgaClkOutP            => fpgaClkOutP, 
         fpgaClkOutM            => fpgaClkOutM,

         jitclnLolL             => jitclnrLolL,
         clk156                 => clk156,
         rst156                 => rst156,
         clk250                 => clk250,
         rst250                 => rst250,
         sspClk                 => sspClk,
         sspRst                 => sspRst,
         clk6Meg                => clk6Meg
      );
      
   U_AsicTop : entity work.AsicTop
      generic map (
         TPD_G                  => TPD_G,
         SIMULATION_G           => SIMULATION_G,
         BUILD_INFO_G           => BUILD_INFO_G,
         AXIL_BASE_ADDR_G       => XBAR_CONFIG_C(ASIC_INDEX_C).baseAddr
      )
      port map (
         -- sys clock signals (ASIC RD clock domain)
         sysRst               => rst250,
         sysClk               => clk250,
         -- Trigger Interface
         triggerClk           => triggerClk,
         triggerRst           => triggerRst,
         triggerData          => triggerData,
         -- L1 trigger feedback (optional)
         l1Clk                => l1Clk,
         l1Rst                => l1Rst,
         l1Feedbacks          => l1Feedbacks,
         l1Acks               => l1Acks,
         -- External trigger inputs
         ttlToFpga           => ttlToFpga,
         daqToFpga           => daqToFpga,
         -- SW trigger in (from VC)
         ssiCmd               => ssiCmd,   
         -- Register Inputs/Outputs (axiClk domain)
         boardConfig          => boardConfig,               
         -- Event streams
         eventClk             => eventClk,
         eventRst             => eventRst,
         eventTrigMsgMasters  => eventTrigMsgMasters,
         eventTrigMsgSlaves   => eventTrigMsgSlaves,
         eventTrigMsgCtrl     => eventTrigMsgCtrl,
         eventTimingMsgMasters=> eventTimingMsgMasters,
         eventTimingMsgSlaves => eventTimingMsgSlaves,
         clearReadout         => clearReadout,
         -- ADC/DAC Debug Trigger Interface (axilClk domain)
         oscopeAcqStart       => oscopeAcqStart,
         oscopeTrigBus        => oscopeTrigBus,
         slowAdcAcqStart      => slowAdcAcqStart,
         dacTrig              => dacTrig,
         -- SSP Interfaces (sspClk domain)
         sspClk               => sspClk,
         sspRst               => sspRst,
         sspLinkUp            => sspLinkUp,
         sspValid             => sspValid,
         sspData              => sspData,
         sspSof               => sspSof,
         sspEof               => sspEof,
         sspEofe              => sspEofe,
         -- AXI-Lite Interface (axilClk domain)
         axiClk              => axiClk,
         axiRst              => axiRst,
         axilReadMaster       => axilReadMasters(ASIC_INDEX_C),
         axilReadSlave        => axilReadSlaves(ASIC_INDEX_C),
         axilWriteMaster      => axilWriteMasters(ASIC_INDEX_C),
         axilWriteSlave       => axilWriteSlaves(ASIC_INDEX_C),
         -- Streaming Interfaces (axilClk domain)
         asicDataMasters      => asicDataMasters,
         asicDataSlaves       => asicDataSlaves,
         remoteDmaPause       => remoteDmaPause,
         -------------------
         --  Top Level Ports
         -------------------
         -- ASIC Ports
         digMon               => digMon,
         asicGlblRst               => asicGlblRst,
         asicR0               => asicR0,
         asicAcq              => asicAcqSig,
         asicSync             => asicSyncSig,
         asicSro              => asicSroSig,
         asicDigRst           => asicDigRstSig,
         asicClkSyncEn        => asicClkSyncEnSig,
         -- Clocking ports
         rdClkSel        => rdClkSel,
         -- Digital Ports
         -- spareIo              => spareIo,
         serialNumber         => serialNumber,
         -- Timing link up status
         v1LinkUp             => v1LinkUp,
         v2LinkUp             => v2LinkUp
      );
   
   ----------------------------
   -- SACI Interface Controller
   ----------------------------
   U_AxiLiteSaciMaster : entity surf.AxiLiteSaciMaster
      generic map (
         AXIL_CLK_PERIOD_G  => AXIL_CLK_PERIOD_C,  -- In units of seconds
         AXIL_TIMEOUT_G     => 1.0E-3,             -- In units of seconds
         SACI_CLK_PERIOD_G  => ite(SIMULATION_G, (4.0*AXIL_CLK_PERIOD_C), 1.0E-6),  -- In units of seconds
         SACI_CLK_FREERUN_G => false,
         SACI_RSP_BUSSED_G  => true,
         SACI_NUM_CHIPS_G   => 4)
      port map (
         -- SACI interface
         saciClk         => saciClkVec,
         saciCmd         => saciCmdVec,
         saciSelL        => saciSelSig,
         saciRsp(0)      => saciRsp,
         -- AXI-Lite Register Interface
         axilClk         => axiClk,
         axilRst         => axiRst,
         axilReadMaster  => axilReadMasters(SACI_INDEX_C),
         axilReadSlave   => axilReadSlaves(SACI_INDEX_C),
         axilWriteMaster => axilWriteMasters(SACI_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(SACI_INDEX_C));


   U_PwrCtrl : entity work.PowerCtrl
      generic map (
         TPD_G             => TPD_G
      )
      port map (
         axiClk             => axiClk,
         axiRst             => axiRst,
         axilReadMaster     => axilReadMasters(PWR_INDEX_C),
         axilReadSlave      => axilReadSlaves(PWR_INDEX_C),
         axilWriteMaster    => axilWriteMasters(PWR_INDEX_C),
         axilWriteSlave     => axilWriteSlaves(PWR_INDEX_C),
         clk6Meg            => clk6Meg,
         syncDcdc           => syncDcdc,
         pwrAnaEn           => pwrAnaEn,
         PwrSync1MHzClk     => open,
         -- pcbSync            => pcbSync,
         pwrGood            => pwrGood
      );
   
   U_Deser : entity work.AppDeser
      generic map (
         TPD_G             => TPD_G,
         SIMULATION_G      => SIMULATION_G,
         AXIL_BASE_ADDR_G  => XBAR_CONFIG_C(DESER_INDEX_C).baseAddr
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
         asicDataM       => asicDataM,
         -- ref ports
         clk250          => clk250,
         -- Streaming Interfaces (sspClk domain)
         sspClk          => sspClk,
         sspRst          => sspRst,
         sspLinkUp       => sspLinkUp,
         sspValid        => sspValid,
         sspData         => sspData,
         sspSof          => sspSof,
         sspEof          => sspEof,
         sspEofe         => sspEofe
      );

   --------------
   -- DAC Modules
   --------------
   U_Dac : entity work.Dac
      generic map(
         TPD_G            => TPD_G,
         SIMULATION_G     => SIMULATION_G,
         AXIL_BASE_ADDR_G => XBAR_CONFIG_C(DAC_INDEX_C).baseAddr)
      port map (
         dacTrig         => dacTrig,
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axiClk,
         axilRst         => axiRst,
         axilReadMaster  => axilReadMasters(DAC_INDEX_C),
         axilReadSlave   => axilReadSlaves(DAC_INDEX_C),
         axilWriteMaster => axilWriteMasters(DAC_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(DAC_INDEX_C),
         -------------------
         --  Top Level Ports
         -------------------
         -- DAC Ports
         -- Bias DAC
         biasDacDin  => biasDacDin,
         biasDacSclk => biasDacSclk,
         biasDacCsb  => biasDacCsb,
         biasDacClrb => biasDacClrb,

         -- High Speed DAC
         hsDacSclk   => hsDacSclk,
         hsDacDin    => hsDacDin,
         hsCsb       => hsCsb,
         hsLdacb     => hsLdacb
         );
   
   U_TimingRx : entity work.TimingRx
      generic map (
         TPD_G               => TPD_G,
         SIMULATION_G        => SIMULATION_G,
         AXIL_CLK_FREQ_G     => AXIL_CLK_FREQ_C,
         EVENT_AXIS_CONFIG_G => PGP4_AXIS_CONFIG_C,
         AXIL_BASE_ADDR_G    => XBAR_CONFIG_C(TIMING_INDEX_C).baseAddr)
      port map (
         -- Trigger Interface
         triggerClk           => triggerClk,
         triggerRst           => triggerRst,
         triggerData          => triggerData,
         -- L1 trigger feedback (optional)
         l1Clk                => l1Clk,
         l1Rst                => l1Rst,
         l1Feedbacks          => l1Feedbacks,
         l1Acks               => l1Acks,
         -- Event streams
         eventClk             => eventClk,
         eventRst             => eventRst,
         eventTrigMsgMasters  => eventTrigMsgMasters,
         eventTrigMsgSlaves   => eventTrigMsgSlaves,
         eventTrigMsgCtrl     => eventTrigMsgCtrl,
         eventTimingMsgMasters=> eventTimingMsgMasters,
         eventTimingMsgSlaves => eventTimingMsgSlaves,
         clearReadout         => clearReadout,
         -- AXI-Lite Interface
         axilClk              => axiClk,
         axilRst              => axiRst,
         axilReadMaster       => axilReadMasters(TIMING_INDEX_C),
         axilReadSlave        => axilReadSlaves(TIMING_INDEX_C),
         axilWriteMaster      => axilWriteMasters(TIMING_INDEX_C),
         axilWriteSlave       => axilWriteSlaves(TIMING_INDEX_C),
         -- GT Clock Ports
         gtLclsClkP           => gtLclsClkP,
         gtLclsClkN           => gtLclsClkM,
         -- LEAP Transceiver Ports
         leapTxP              => fpgaOutObTransInP(11),
         leapTxN              => fpgaOutObTransInM(11),
         leapRxP              => fpgaInObTransOutP(11),
         leapRxN              => fpgaInObTransOutM(11),
         -- Timing link up status
         v1LinkUp             => v1LinkUp,
         v2LinkUp             => v2LinkUp
      );
   
   U_TERM_GTs : entity surf.Gthe4ChannelDummy
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => 3
      )
      port map (
         refClk => axiClk,
         gtTxP  => fpgaOutObTransInP(10 downto 8),
         gtTxN  => fpgaOutObTransInM(10 downto 8),
         gtRxP  => fpgaInObTransOutP(10 downto 8),
         gtRxN  => fpgaInObTransOutM(10 downto 8)
      );
  
   U_AdcMon : entity work.AdcMon
      generic map (
         TPD_G            => TPD_G,
         AXIL_BASE_ADDR_G => XBAR_CONFIG_C(ADC_INDEX_C).baseAddr
      )
      port map (
         clk250          => clk250,
         rst250          => rst250,
         -- Trigger Interface (axilClk domain)
         oscopeAcqStart  => oscopeAcqStart,
         oscopeTrigBus   => oscopeTrigBus,
         slowAdcAcqStart => slowAdcAcqStart,
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axiClk,
         axilRst         => axiRst,
         axilReadMaster  => axilReadMasters(ADC_INDEX_C),
         axilReadSlave   => axilReadSlaves(ADC_INDEX_C),
         axilWriteMaster => axilWriteMasters(ADC_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(ADC_INDEX_C),
         -- Streaming Interfaces (axilClk domain)
         oscopeMasters   => oscopeMasters,
         oscopeSlaves    => oscopeSlaves,
         slowAdcMasters  => slowAdcMasters,
         slowAdcSlaves   => slowAdcSlaves,
         -------------------
         --  Top Level Ports
         -------------------
         -- Slow ADC Ports
         slowAdcCsL      => slowAdcCsL,
         slowAdcSclk     => slowAdcSclk,
         slowAdcDin      => slowAdcDinSig,
         slowAdcSyncL    => slowAdcSyncLSig,
         slowAdcDout     => slowAdcDout,
         slowAdcDrdyL    => slowAdcDrdyL,
         slowAdcRefClk   => slowAdcRefClkSig,
         -- ADC Monitor Ports
         adcMonSpiCsL    => adcMonSpiCsL,
         adcMonPdwn      => adcMonPdwn,
         adcMonSpiClk    => adcMonSpiClk,
         adcMonSpiData   => adcMonSpiData,
         adcMonClkOutP   => adcMonClkP,
         adcMonClkOutM   => adcMonClkM,
         adcMonDoutP     => adcMonDoutP,
         adcMonDoutM     => adcMonDoutM,
         adcMonFrameClkP => adcMonFrameClkP,
         adcMonFrameClkM => adcMonFrameClkM,
         adcMonDataClkP  => adcMonDataClkP,
         adcMonDataClkM  => adcMonDataClkM
      );

end rtl; -- rtl