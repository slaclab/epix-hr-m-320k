-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: top level for ePix320kM
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


entity ePix320kM is 
  generic (
    TPD_G           : time := 1 ns;
    BUILD_INFO_G    : BuildInfoType;
    SIMULATION_G    : boolean := false
    );
  port (
    ----------------------------------------------
    --      Top level ports shared
    ----------------------------------------------

    -- Transceiver high speed lanes
    fpgaOutObTransInP : out slv(11 downto 0);
    fpgaOutObTransInM : out slv(11 downto 0);
    fpgaInObTransOutP : in  slv(11 downto 0);
    fpgaInObTransOutM : in  slv(11 downto 0);

    -- Transceiver low speed control
    obTransScl        : inout sl;
    obTransSda        : inout sl;
    obTransResetL     : out sl;
    obTransIntL       : in sl;

    -- GT Clock Ports
    gtPllClkP         : in  slv(2 downto 0);
    gtPllClkM         : in  slv(2 downto 0);
    gtRefClkP         : in  slv(1 downto 0);
    gtRefClkM         : in  slv(1 downto 0);
    gtLclsClkP        : in  sl;
    gtLclsClkM        : in  sl;


    ----------------------------------------------
    --              Application Ports           --
    ----------------------------------------------
    -- ASIC Data Outs
    asicDataP         : in  Slv24Array(3 downto 0);
    asicDataM         : in  Slv24Array(3 downto 0);

    adcMonDoutP       : in  slv(11 downto 0);
    adcMonDoutM       : in  slv(11 downto 0);
    adcDoClkP         : in  slv(1 downto 0);
    adcDoClkM         : in  slv(1 downto 0);
    adcFrameClkP      : in  slv(1 downto 0);
    adcFrameClkM      : in  slv(1 downto 0);

    -- ASIC Control Ports
    asicR0            : out sl;
    asicGlblRst       : out sl;
    asicSync          : out sl;
    asicAcq           : out sl;
    asicRoClkP        : out slv(3 downto 0);
    asicRoClkN        : out slv(3 downto 0);
    asicSro           : out sl;
    asicClkEn         : out sl;

    -- SACI Ports
    asicSaciCmd       : out sl;
    asicSaciClk       : out sl;
    asicSaciSel       : out slv(3 downto 0);
    asicSaciRsp       : in  sl;

    -- Spare ports both to carrier and to p&cb
    pcbSpare          : inout slv(5 downto 0);
    spareM            : inout slv(1 downto 0);
    spareP            : inout slv(1 downto 0);

    -- Timing/Clocks
    lcls2TimingClkP   : in     sl;
    lcls2TimingClkM   : in     sl;
    altTimingClkP     : in     sl;
    altTimingClkM     : in     sl;
    clkScl            : out    sl;
    clkSda            : inout  sl;
    rdClkSel          : out    sl;

    -- Bias Dac
    biasDacDin        : out sl;
    biasDacSclk       : out sl;
    biasDacCsb        : out sl;
    biasDacClrb       : out sl;

    -- High speed dac
    hsDacSclk         : out sl;
    hsDacDin          : out sl;
    hsCsb             : out sl;
    hsLdacb           : out sl; 
    
    -- Digital Monitor
    digMon            : in  slv(1 downto 0);

    -- External trigger Connector
    runToFpga         : in  sl;
    daqToFpga         : in  sl;
    ttlToFpga         : in  sl;
    fpgaTtlOut        : out sl; 
    fpgaMps           : out sl;
    fpgaTg            : out sl;

    -- Fpga Clock IO
    fpgaClkInP        : in  sl;
    fpgaClkInM        : in  sl;
    fpgaClkOutP       : out sl;
    fpgaClkOutM       : out sl;

    -- Power and communication env Monitor
    pcbAdcDrdyL       : in  sl;
    pcbAdcData        : in  sl;
    pcbAdcCsb         : out sl;
    pcbAdcSclk        : out sl;
    pcbAdcDin         : out sl;
    pcbAdcSyncL       : out sl;
    pcbAdcRefClk      : out sl;

    -- Serial number
    serialNumber      : inout slv(2 downto 0);

    -- Power 
    syncDcdc          : out slv(6 downto 0);
    ldoShtdnL         : out slv(1 downto 0);
    dcdcSync          : out sl;
    pcbSync           : out sl;
    pcbLocalSupplyGood: in  sl;

    -- Digital board env monitor
    adcSpiClk         : out  sl;
    adcSpiData        : in   sl;
    adcMonClkP        : out  sl;
    adcMonClkM        : out  sl;
    adcMonPdwn        : out  sl;
    adcMonSpiCsb      : out  sl;
    slowAdcDout       : in   sl;
    slowAdcDrdyL      : in   sl;
    slowAdcSyncL      : out  sl;
    slowAdcSclk       : out  sl;
    slowAdcCsb        : out  sl;
    slowAdcDin        : out  sl;
    slowAdcRefClk     : out  sl;

    ----------------------------------------------
    --               Core Ports                 --
    ----------------------------------------------
    -- Clock Jitter Cleaner
    jitclnrCsL        : out sl;
    jitclnrIntr       : in  sl;
    jitclnrLolL       : in  sl;
    jitclnrOeL        : out sl;
    jitclnrRstL       : out sl;
    jitclnrSclk       : out sl;
    jitclnrSdio       : out sl;
    jitclnrSdo        : in  sl;
    jitclnrSel        : out slv(1 downto 0);

    -- LMK61E2
    pllClkScl         : inout sl;
    pllClkSda         : inout sl;

    -- XADC Ports
    vPIn              : in  sl;
    vNIn              : in  sl
  );
end entity;


architecture topLevel of ePix320kM is

  -- Clock and Reset
  signal axilClk : sl;
  signal axilRst : sl;

  -- AXI-Stream: Stream Interface
  signal asicDataMasters : AxiStreamMasterArray(3 downto 0);
  signal asicDataSlaves  : AxiStreamSlaveArray(3 downto 0);
  signal remoteDmaPause  : slv(3 downto 0);
  signal oscopeMasters   : AxiStreamMasterArray(3 downto 0);
  signal oscopeSlaves    : AxiStreamSlaveArray(3 downto 0);
  signal slowAdcMasters  : AxiStreamMasterArray(3 downto 0);
  signal slowAdcSlaves   : AxiStreamSlaveArray(3 downto 0);

  -- AXI-Lite: Register Access
  signal axilReadMaster  : AxiLiteReadMasterType;
  signal axilReadSlave   : AxiLiteReadSlaveType;
  signal axilWriteMaster : AxiLiteWriteMasterType;
  signal axilWriteSlave  : AxiLiteWriteSlaveType;

begin

  U_App: entity work.Application
    generic map (
      TPD_G                 => TPD_G,
      BUILD_INFO_G          => BUILD_INFO_G,
      SIMULATION_G          => SIMULATION_G
    )
    port map (
      
        -- ASIC Data Ports
        asicDataP             => asicDataP,
        asicDataM             => asicDataM,
  --    adcMonDoutP           =>  adcMonDoutP,
  --    adcMonDoutM           =>  adcMonDoutM,
  --    adcDoClkP             =>  adcDoClkP,
  --    adcDoClkM             =>  adcDoClkM,
  --    adcFrameClkP          =>  adcFrameClkP,
  --    adcFrameClkM          =>  adcFrameClkM,
  --    -- ASIC Control Ports
  --    asicR0                =>  asicR0,
  --    asicGlblRst           =>  asicGlblRst,
  --    asicSync              =>  asicSync,
  --    asicAcq               =>  asicAcq,
  --    asicRoClkP            =>  asicRoClkP,
  --    asicRoClkN            =>  asicRoClkN,
  --    asicSro               =>  asicSro,
  --    asicClkEn             =>  asicClkEn,
  --    -- SACI Ports
  --    asicSaciCmd           =>  asicSaciCmd,
  --    asicSaciClk           =>  asicSaciClk,
  --    asicSaciSel           =>  asicSaciSel,
  --    asicSaciRsp           =>  asicSaciRsp,
  --    -- Spare ports both to carrier and to p&cb
  --    pcbSpare              =>  pcbSpare,
  --    spareM                =>  spareM,
  --    spareP                =>  spareP,
  --    -- Timing/Clocks
  --    --lcls2TimingClkP       => lcls2TimingClkP,
  --    --lcls2TimingClkM       => lcls2TimingClkM,
  --    --altTimingClkP         => altTimingClkP,
  --    --altTimingClkM         => altTimingClkM,
  --    --pllClkP               => pllClkP,
  --    --pllClkM               => pllClkM,
  --    --refClkP               => refClkP,
  --    --refClkM               => refClkM,
  --    --fpgaClkInP            => fpgaClkInP,
  --    --fpgaClkInM            => fpgaClkInM,
  --    --fpgaClkOutP           => fpgaClkOutP,
  --    --fpgaClkOutM           => fpgaClkOutM,
  --    fpgaRdClkP            => fpgaRdClkP,
  --    fpgaRdClkM            => fpgaRdClkM,
  --    clkScl                => clkScl,
  --    clkSda                => clkSda,
  --    rdClkSel              => rdClkSel,
  --    -- Bias Dac
  --    biasDacDin            => biasDacDin,
  --    biasDacSclk           => biasDacSclk,
  --    biasDacCsb            => biasDacCsb,
  --    biasDacClrb           => biasDacClrb,
  --    -- High speed dac
  --    hsDacSclk             =>  hsDacSclk,
  --    hsDacDin              =>  hsDacDin,
  --    hsCsb                 =>  hsCsb,
  --    hsLdacb               =>  hsLdacb,
  --    -- Digital Monitor
  --    digMon                => digMon,
  --    -- External trigger Connector
  --    runToFpga             => runToFpga,
  --    daqToFpga             => daqToFpga,
  --    ttlToFpga             => ttlToFpga,
  --    fpgaTtlOut            => fpgaTtlOut,
  --    fpgaMps               => fpgaMps,
  --    fpgaTg                => fpgaTg,
      -- Transceiver high speed lanes
      fpgaOutObTransInP     => fpgaOutObTransInP(11 downto 8),
      fpgaOutObTransInM     => fpgaOutObTransInM(11 downto 8),
      fpgaInObTransOutP     => fpgaInObTransOutP(11 downto 8),
      fpgaInObTransOutM     => fpgaInObTransOutM(11 downto 8)
  );

  U_Core: entity work.Core
    generic map(
      TPD_G                 => TPD_G,
      BUILD_INFO_G          => BUILD_INFO_G,
      SIMULATION_G          => SIMULATION_G
    )
    port map (
      -- AXI-Lite Register Interface (sysClk domain)
      -- Register Address Range = [0x80000000:0xFFFFFFFF]
      axilClk             => axilClk,
      axilRst             => axilRst,
      axilReadMaster      => axilReadMaster,
      axilReadSlave       => axilReadSlave,
      axilWriteMaster     => axilWriteMaster,
      axilWriteSlave      => axilWriteSlave,

      -- Streaming Interfaces (axilClk domain)
      asicDataMasters     => asicDataMasters,
      asicDataSlaves      => asicDataSlaves,
      remoteDmaPause      => remoteDmaPause,
      oscopeMasters       => oscopeMasters,
      oscopeSlaves        => oscopeSlaves,
      slowAdcMasters      => slowAdcMasters,
      slowAdcSlaves       => slowAdcSlaves,

      -- Transceiver high speed lanes
      fpgaOutObTransInP   => fpgaOutObTransInP(7 downto 0),
      fpgaOutObTransInM   => fpgaOutObTransInM(7 downto 0),
      fpgaInObTransOutP   => fpgaInObTransOutP(7 downto 0),
      fpgaInObTransOutM   => fpgaInObTransOutM(7 downto 0),

      -- Transceiver low speed control
      obTransScl          => obTransScl,
      obTransSda          => obTransSda,
      obTransResetL       => obTransResetL,
      obTransIntL         => obTransIntL,

      -- Jitter Cleaner PLL Ports
      jitclnrCsL          => jitclnrCsL,
      jitclnrIntr         => jitclnrIntr,
      jitclnrLolL         => jitclnrLolL,
      jitclnrOeL          => jitclnrOeL,
      jitclnrRstL         => jitclnrRstL,
      jitclnrSclk         => jitclnrSclk,
      jitclnrSdio         => jitclnrSdio,
      jitclnrSdo          => jitclnrSdo,
      jitclnrSel          => jitclnrSel,

      -- LMK61E2
      pllClkScl           => pllClkScl,
      pllClkSda           => pllClkSda,

      -- GT Clock Ports
      gtPllClkP           => gtPllClkP(0),
      gtPllClkM           => gtPllClkM(0),
      gtRefClkP           => gtRefClkP(0),
      gtRefClkM           => gtRefClkM(0),

      -- XADC Ports
      vPIn                => vPIn,
      vNIn                => vNIn
      );
    
end topLevel;