library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiPkg.all;
use surf.I2cPkg.all;
use surf.SsiCmdMasterPkg.all;

library unisim;
use unisim.vcomponents.all;

entity Application is
  generic (
    TPD_G           : time := 1 ns;
    BUILD_INFO_G    : BuildInfoType;
    SIMULATION_G    : boolean := false
    );
  port (
		-----------------------
  	-- Top Level Ports --
  	-----------------------
  	sysClk : in sl;
  	sysRst : in sl;
	  -- AXI-Lite Register Interface (sysClk domain)
    -- Register Address Range = [0x80000000:0xFFFFFFFF]
    sAxilReadMaster  : in    AxiLiteReadMasterType;
    sAxilReadSlave   : out   AxiLiteReadSlaveType;
    sAxilWriteMaster : in    AxiLiteWriteMasterType;
    sAxilWriteSlave  : out   AxiLiteWriteSlaveType;
    -- AXI Stream, one per QSFP lane (sysClk domain)
    mAxisMasters     : out   AxiStreamMasterArray(3 downto 0) := (others=>AXI_STREAM_MASTER_INIT_C);
    mAxisSlaves      : in    AxiStreamSlaveArray(3 downto 0);
    -- Auxiliary AXI Stream, (sysClk domain)
    -- 0 is pseudo scope, 1 is slow adc monitoring
    sAuxAxisMasters  : out   AxiStreamMasterArray(1 downto 0) := (others=>AXI_STREAM_MASTER_INIT_C);
    sAuxAxisSlaves   : in    AxiStreamSlaveArray(1 downto 0);
    -- ssi commands (Lane and Vc 0)
    ssiCmd           : in    SsiCmdMasterType;

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

	);
end entity;


architecture rtl of Application is

begin

end rtl; -- rtl