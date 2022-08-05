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

entity Core is 
  generic (
    TPD_G           : time := 1 ns;
    BUILD_INFO_G    : BuildInfoType;
    ROUGE_SIM_EN    : boolean := false;
    ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 10000);
  port (
    -----------------------
    -- Top Level Ports --
    -----------------------
    sysClk : in sl;
    sysRst : in sl;
    -- AXI-Lite Register Interface (sysClk domain)
    -- Register Address Range = [0x80000000:0xFFFFFFFF]
    mAxilReadMaster  : out   AxiLiteReadMasterType;
    mAxilReadSlave   : in    AxiLiteReadSlaveType;
    mAxilWriteMaster : out   AxiLiteWriteMasterType;
    mAxilWriteSlave  : in    AxiLiteWriteSlaveType;
    -- AXI Stream, one per QSFP lane (sysClk domain)
    sAxisMasters     : in    AxiStreamMasterArray(3 downto 0);
    sAxisSlaves      : out   AxiStreamSlaveArray(3 downto 0);
    -- Auxiliary AXI Stream, (sysClk domain)
    -- 0 is pseudo scope, 1 is slow adc monitoring
    sAuxAxisMasters  : in    AxiStreamMasterArray(1 downto 0);
    sAuxAxisSlaves   : out   AxiStreamSlaveArray(1 downto 0);
    -- ssi commands (Lane and Vc 0)
    ssiCmd           : out   SsiCmdMasterType;

    -----------------------
    -- Core Ports --
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


  architecture rtl of Core is
    
  begin
  
  end architecture ; -- rtl