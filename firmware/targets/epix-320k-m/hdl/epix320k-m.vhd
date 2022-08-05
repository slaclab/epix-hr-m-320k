
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

    -- Digital board env monitor
    adcMonSpiClk      : out  sl;
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

    -- Power 
    syncDcdc            : out slv(6 downto 0);
    ldoShtdnL           : out slv(1 downto 0);
    dcdcSync            : out sl;
    pcbSync             : out sl;
    pcbLocalSupplyGood  : in sl;

    -- Timing/Clocks
    lcls2TimingClkP   : in     sl;
    lcls2TimingClkM   : in     sl;
    altTimingClkP     : in     sl;
    altTimingClkM     : in     sl;
    pllClkP           : in     slv(1 downto 0);
    pllClkM           : in     slv(1 downto 0);
    refClkP           : in     slv(1 downto 0);
    refClkM           : in     slv(1 downto 0);
    fpgaClkInP        : in     sl;
    fpgaClkInM        : in     sl;
    fpgaClkOutP       : out    sl;
    fpgaClkOutM       : out    sl;
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
    jitclnrCsL        : out sl;        
    jitclnrIntrL      : in sl;
    jitclnrLolL       : in sl;
    jitclnrOeL        : out sl;
    jitclnrRstL       : out sl;
    jitclnrSclk       : out sl;
    jitclnrSdio       : inout sl;
    jitclnrSdo        : out sl;
    jitclnrSel        : out slv(1 downto 0);

    -- Serial number
    serialNumber      : inout slv(2 downto 0);

    -- Digital Monitor
    digMon            : in slv(1 downto 0);

    -- External trigger Connector
    runToFpga         : in sl;
    daqToFpga         : in sl;
    ttlToFpga         : in sl;
    fpgaTtlOut        : out sl; 
    fpgaMps           : out sl;
    fpgaTg            : out sl;
    

    -- Power and communication env Monitor
    pcbAdcDrdyL       : in sl;
    pcbAdcDout        : in sl;
    pcbAdcCsb         : out sl;
    pcbAdcSclk        : out sl;
    pcbAdcDin         : out sl;
    pcbAdcSyncL       : out sl;
    pcbAdcRefClk      : out sl;

    -----------------------
    --     Core Ports    --
    -----------------------
    -- Transceiver high speed lanes
    fpgaOutObTransInP : out slv(11 downto 0);
    fpgaInObTransOutP : in  slv(11 downto 0)

    -- Transceiver low speed control
    obTransScl        : out sl;
    obTransSda        : inout sl;
    obTransResetL     : out sl;
    obTransIntL       : out sl;

    -- Fpga Clock IO
    fpgaClkInP        : in  sl;
    fpgaClkInM        : in  sl;
    fpgaClkOutP       : out sl;
    fpgaClkOutM       : out sl
  );

architecture topLevel of Epix320kM is

  -- System Clock and Reset
  signal sysClk          : sl;
  signal sysRst          : sl;
  -- AXI-Lite Register Interface (sysClk domain)
  signal axilReadMaster  : AxiLiteReadMasterType;
  signal axilReadSlave   : AxiLiteReadSlaveType;
  signal axilWriteMaster : AxiLiteWriteMasterType;
  signal axilWriteSlave  : AxiLiteWriteSlaveType;
  -- AXI Stream, one per QSFP lane (sysClk domain)
  signal axisMasters     : AxiStreamMasterArray(3 downto 0);
  signal axisSlaves      : AxiStreamSlaveArray(3 downto 0);
  -- Auxiliary AXI Stream, (sysClk domain)
  signal sAuxAxisMasters : AxiStreamMasterArray(1 downto 0);
  signal sAuxAxisSlaves  : AxiStreamSlaveArray(1 downto 0);
  -- ssi commands (Lane and Vc 0)
  signal ssiCmd          : SsiCmdMasterType;


begin

  U_App: work.Application
    generic map (
      TPD_G                 => TPD_G,
      BUILD_INFO_G          => BUILD_INFO_G,
      ROUGE_SIM_EN          => ROUGE_SIM_EN,
      ROGUE_SIM_PORT_NUM_G  => ROGUE_SIM_PORT_NUM_G
    )
    port map (
        
    );

  U_Core: work.Core
    generic (
      TPD_G                 => TPD_G,
      BUILD_INFO_G          => BUILD_INFO_G,
      ROUGE_SIM_EN          => ROUGE_SIM_EN,
      ROGUE_SIM_PORT_NUM_G  => ROGUE_SIM_PORT_NUM_G
    )
    port map (
        
    );
    
end architecture topLevel;