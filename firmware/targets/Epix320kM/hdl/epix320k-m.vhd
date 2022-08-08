
library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiCmdMasterPkg.all;


entity Epix320kM is 
  generic (
    TPD_G           : time := 1 ns;
    BUILD_INFO_G    : BuildInfoType;
    ROUGE_SIM_EN    : boolean := false;
    ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 10000);
  port (
    -----------------------
    -- Application Ports --
    -----------------------
    -- ASIC Data Outs
    asic3DoutP        : in    slv(23 downto 0);
    asic3DoutM        : in    slv(23 downto 0);
    asic2DoutP        : in    slv(23 downto 0);
    asic2DoutM        : in    slv(23 downto 0);
    asic1DoutP        : in    slv(23 downto 0);
    asic1DoutM        : in    slv(23 downto 0);
    asic0DoutP        : in    slv(23 downto 0);
    asic0DoutM        : in    slv(23 downto 0);

    adcMonDoutP       : in    slv(11 downto 0);
    adcMonDoutM       : in    slv(11 downto 0);
    adcDoClkP         : in    slv(1 downto 0);
    adcDoClkM         : in    slv(1 downto 0);
    adcFrameClkP      : in    slv(1 downto 0);
    adcFrameClkM      : in    slv(1 downto 0);

    -- ASIC Control Ports
    asicR0            : out   sl;
    asicGlblRst       : out   sl;
    asicSync          : out   sl;
    asicAcq           : out   sl;
    asicRoClkP        : out   slv(3 downto 0);
    asicRoClkN        : out   slv(3 downto 0);
    asicSro           : out   sl;
    asicClkEn             : out    sl;

    -- SACI Ports
    asicSaciCmd       : out   sl;
    asicSaciClk       : out   sl;
    asicSaciSel       : out   slv(3 downto 0);
    asicSaciRsp       : in    sl;

    -- Spare ports both to carrier and to p&cb
    pcbSpare          : inout slv(5 downto 0);
    spareM            : inout slv(1 downto 0);
    spareP            : inout slv(1 downto 0);

    -- Timing/Clocks
    lcls2TimingClkP   : in     sl;
    lcls2TimingClkM   : in     sl;
    altTimingClkP     : in     sl;
    altTimingClkM     : in     sl;
    pllClkP           : in     slv(1 downto 0);
    pllClkM           : in     slv(1 downto 0);
    refClkP           : in     slv(1 downto 0);
    refClkM           : in     slv(1 downto 0);
    fpgaRdClkP        : in     sl;
    fpgaRdClkM        : in     sl;
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
    
    -- Clock Jitter Cleaner
    jitclnrCsL        : out   sl;
    jitclnrIntrL      : in    sl;
    jitclnrLolL       : in    sl;
    jitclnrOeL        : out   sl;
    jitclnrRstL       : out   sl;
    jitclnrSclk       : out   sl;
    jitclnrSdio       : inout sl;
    jitclnrSdo        : out   sl;
    jitclnrSel        : out   slv(1 downto 0);

    -- Digital Monitor
    digMon            : in  slv(1 downto 0);

    -- External trigger Connector
    runToFpga         : in  sl;
    daqToFpga         : in  sl;
    ttlToFpga         : in  sl;
    fpgaTtlOut        : out sl; 
    fpgaMps           : out sl;
    fpgaTg            : out sl;
    
    -----------------------
    --     Core Ports    --
    -----------------------
    -- Transceiver high speed lanes
    fpgaOutObTransInP : out slv(11 downto 0);
    fpgaInObTransOutP : in  slv(11 downto 0);

    -- Transceiver low speed control
    obTransScl        : out sl;
    obTransSda        : inout sl;
    obTransResetL     : out sl;
    obTransIntL       : out sl;

    -- Fpga Clock IO
    fpgaClkInP        : in  sl;
    fpgaClkInM        : in  sl;
    fpgaClkOutP       : out sl;
    fpgaClkOutM       : out sl;

    -- Power and communication env Monitor
    pcbAdcDrdyL       : in  sl;
    pcbAdcDout        : in  sl;
    pcbAdcCsb         : out sl;
    pcbAdcSclk        : out sl;
    pcbAdcDin         : out sl;
    pcbAdcSyncL       : out sl;
    pcbAdcRefClk      : out sl;

    -- Serial number
    serialNumber      : inout slv(2 downto 0);

    -- Power 
    syncDcdc           : out slv(6 downto 0);
    ldoShtdnL          : out slv(1 downto 0);
    dcdcSync           : out sl;
    pcbSync            : out sl;
    pcbLocalSupplyGood : in  sl;

    -- Digital board env monitor
    adcSpiClk      : out  sl;
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
    slowAdcRefClk     : out  sl
  );
end entity;


architecture topLevel of Epix320kM is

  -- System Clock and Reset
  signal sysClk          : sl;
  signal sysRst          : sl;
  -- AXI-Lite Register Interface (sysClk domain)
  signal axilReadMaster  : AxiLiteReadMasterType;
  signal axilReadSlave   : AxiLiteReadSlaveType;
  signal axilWriteMaster : AxiLiteWriteMasterType;
  signal axilWriteSlave  : AxiLiteWriteSlaveType;
  -- AXI Stream, one per OBT lane (sysClk domain)
  signal axisMasters     : AxiStreamMasterArray(11 downto 0);
  signal axisSlaves      : AxiStreamSlaveArray(11 downto 0);
  -- Auxiliary AXI Stream, (sysClk domain)
  signal sAuxAxisMasters : AxiStreamMasterArray(1 downto 0);
  signal sAuxAxisSlaves  : AxiStreamSlaveArray(1 downto 0);
  -- ssi commands (Lane and Vc 0)
  signal ssiCmd          : SsiCmdMasterType;


begin

  U_App: entity work.Application
    generic map (
      TPD_G                 => TPD_G,
      BUILD_INFO_G          => BUILD_INFO_G,
      ROUGE_SIM_EN          => ROUGE_SIM_EN,
      ROGUE_SIM_PORT_NUM_G  => ROGUE_SIM_PORT_NUM_G
    )
    port map (
      -- System Clock and Reset
      sysClk                => sysClk,
      sysRst                => sysRst,
      -- AXI-Lite Regis     ter Interface (sysClk domain)
      -- Register Address Range = [0x80000000:0xFFFFFFFF]
      sAxilReadMaster       => axilReadMaster,
      sAxilReadSlave        => axilReadSlave,
      sAxilWriteMaster      => axilWriteMaster,
      sAxilWriteSlave       => axilWriteSlave,
      -- AXI Stream, one per QSFP lane (sysClk domain)
      mAxisMasters          => axisMasters,
      mAxisSlaves           => axisSlaves,
      -- Auxiliary AXI Stream, (sysClk domain)
      sAuxAxisMasters       => sAuxAxisMasters,
      sAuxAxisSlaves        => sAuxAxisSlaves,
      -- ASIC Data Outs
      asic3DoutP            =>  asic3DoutP,
      asic3DoutM            =>  asic3DoutM,
      asic2DoutP            =>  asic2DoutP,
      asic2DoutM            =>  asic2DoutM,
      asic1DoutP            =>  asic1DoutP,
      asic1DoutM            =>  asic1DoutM,
      asic0DoutP            =>  asic0DoutP,
      asic0DoutM            =>  asic0DoutM,
      adcMonDoutP           =>  adcMonDoutP,
      adcMonDoutM           =>  adcMonDoutM,
      adcDoClkP             =>  adcDoClkP,
      adcDoClkM             =>  adcDoClkM,
      adcFrameClkP          =>  adcFrameClkP,
      adcFrameClkM          =>  adcFrameClkM,
      -- ASIC Control Ports
      asicR0                =>  asicR0,
      asicGlblRst           =>  asicGlblRst,
      asicSync              =>  asicSync,
      asicAcq               =>  asicAcq,
      asicRoClkP            =>  asicRoClkP,
      asicRoClkN            =>  asicRoClkN,
      asicSro               =>  asicSro,
      asicClkEn             =>  asicClkEn,
      -- SACI Ports
      asicSaciCmd           =>  asicSaciCmd,
      asicSaciClk           =>  asicSaciClk,
      asicSaciSel           =>  asicSaciSel,
      asicSaciRsp           =>  asicSaciRsp,
      -- Spare ports both to carrier and to p&cb
      pcbSpare              =>  pcbSpare,
      spareM                =>  spareM,
      spareP                =>  spareP,
      -- Timing/Clocks
      lcls2TimingClkP       => lcls2TimingClkP,
      lcls2TimingClkM       => lcls2TimingClkM,
      altTimingClkP         => altTimingClkP,
      altTimingClkM         => altTimingClkM,
      pllClkP               => pllClkP,
      pllClkM               => pllClkM,
      refClkP               => refClkP,
      refClkM               => refClkM,
      fpgaClkInP            => fpgaClkInP,
      fpgaClkInM            => fpgaClkInM,
      fpgaClkOutP           => fpgaClkOutP,
      fpgaClkOutM           => fpgaClkOutM,
      fpgaRdClkP            => fpgaRdClkP,
      fpgaRdClkM            => fpgaRdClkM,
      clkScl                => clkScl,
      clkSda                => clkSda,
      rdClkSel              => rdClkSel,
      -- Bias Dac
      biasDacDin            => biasDacDin,
      biasDacSclk           => biasDacSclk,
      biasDacCsb            => biasDacCsb,
      biasDacClrb           => biasDacClrb,
      -- High speed dac
      hsDacSclk             =>  hsDacSclk,
      hsDacDin              =>  hsDacDin,
      hsCsb                 =>  hsCsb,
      hsLdacb               =>  hsLdacb,
      -- Clock Jitter Cleaner
      jitclnrCsL            => jitclnrCsL,
      jitclnrIntrL          => jitclnrIntrL,
      jitclnrLolL           => jitclnrLolL,
      jitclnrOeL            => jitclnrOeL,
      jitclnrRstL           => jitclnrRstL,
      jitclnrSclk           => jitclnrSclk,
      jitclnrSdio           => jitclnrSdio,
      jitclnrSdo            => jitclnrSdo,
      jitclnrSel            => jitclnrSel,
      -- Digital Monitor
      digMon                => digMon,
      -- External trigger Connector
      runToFpga             => runToFpga,
      daqToFpga             => daqToFpga,
      ttlToFpga             => ttlToFpga,
      fpgaTtlOut            => fpgaTtlOut,
      fpgaMps               => fpgaMps,
      fpgaTg                => fpgaTg);

  U_Core: entity work.Core
    generic map(
      TPD_G                 => TPD_G,
      BUILD_INFO_G          => BUILD_INFO_G,
      ROUGE_SIM_EN          => ROUGE_SIM_EN,
      ROGUE_SIM_PORT_NUM_G  => ROGUE_SIM_PORT_NUM_G
    )
    port map (
      -- System Clock and Reset
      sysClk                => sysClk,
      sysRst                => sysRst,
      -- AXI-Lite Register Interface (sysClk domain)
      -- Register Address Range = [0x80000000:0xFFFFFFFF]
      sAxilReadMaster       => axilReadMaster,
      sAxilReadSlave        => axilReadSlave,
      sAxilWriteMaster      => axilWriteMaster,
      sAxilWriteSlave       => axilWriteSlave,
      -- AXI Stream, one per QSFP lane (sysClk domain)
      mAxisMasters          => axisMasters,
      mAxisSlaves           => axisSlaves,
      -- Auxiliary AXI Stream, (sysClk domain)
      sAuxAxisMasters       => sAuxAxisMasters,
      sAuxAxisSlaves        => sAuxAxisSlaves,
      -- Transceiver high speed lanes
      fpgaOutObTransInP     => fpgaOutObTransInP,
      fpgaOutObTransInM     => fpgaOutObTransInM,
      fpgaInObTransOutP     => fpgaInObTransOutP,
      fpgaInObTransOutM     => fpgaInObTransOutM,
      -- Transceiver low speed control
      obTransScl            => obTransScl,
      obTransSda            => obTransSda,
      obTransResetL         => obTransResetL,
      obTransIntL           => obTransIntL,
      fpgaClkInP            => fpgaClkInP,
      fpgaClkInM            => fpgaClkInM,
      fpgaClkOutP           => fpgaClkOutP,
      fpgaClkOutM           => fpgaClkOutM,
      -- Digital board env monitor
      adcMonSpiClk          => adcMonSpiClk,
      adcSpiData            => adcSpiData,
      adcMonClkP            => adcMonClkP,
      adcMonClkM            => adcMonClkM,
      adcMonPdwn            => adcMonPdwn,
      adcMonSpiCsb          => adcMonSpiCsb,
      slowAdcDout           => slowAdcDout,
      slowAdcDrdyL          => slowAdcDrdyL,
      slowAdcSyncL          => slowAdcSyncL,
      slowAdcSclk           => slowAdcSclk,
      slowAdcCsb            => slowAdcCsb,
      slowAdcDin            => slowAdcDin,
      slowAdcRefClk         => slowAdcRefClk,
      -- Power
      syncDcdc              => syncDcdc,
      ldoShtdnL             => ldoShtdnL,
      dcdcSync              => dcdcSync,
      pcbSync               => pcbSync,
      pcbLocalSupplyGood    => pcbLocalSupplyGood,
      -- Power and communication env Monitor
      pcbAdcDrdyL           => pcbAdcDrdyL,
      pcbAdcDout            => pcbAdcDout,
      pcbAdcCsb             => pcbAdcCsb,
      pcbAdcSclk            => pcbAdcSclk,
      pcbAdcDin             => pcbAdcDin,
      pcbAdcSyncL           => pcbAdcSyncL,
      pcbAdcRefClk          => pcbAdcRefClk,
      -- Serial number
      serialNumber          => serialNumber);
    
end topLevel;