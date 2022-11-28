library ieee;
use ieee.std_logic_1164.all;

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
      axilClk         : out   sl;
      axilRst         : out   sl;
      ----------------------
      -- Top Level Ports --
      ----------------------
      -- AXI-Lite Register Interface (sysClk domain)
      -- Register Address Range = [0x80000000:0xFFFFFFFF]
      AxilReadMaster  : out   AxiLiteReadMasterType;
      AxilReadSlave   : in    AxiLiteReadSlaveType;
      AxilWriteMaster : out   AxiLiteWriteMasterType;
      AxilWriteSlave  : in    AxiLiteWriteSlaveType;
      -- Streaming Interfaces (axilClk domain)
      asicDataMasters : in    AxiStreamMasterArray(3 downto 0);
      asicDataSlaves  : out   AxiStreamSlaveArray(3 downto 0);
      remoteDmaPause  : out   slv(4 downto 0);
      oscopeMasters   : in    AxiStreamMasterArray(3 downto 0);
      oscopeSlaves    : out   AxiStreamSlaveArray(3 downto 0);
      slowAdcMasters  : in    AxiStreamMasterArray(3 downto 0);
      slowAdcSlaves   : out   AxiStreamSlaveArray(3 downto 0);

      -----------------------
      -- Core Ports --
      -----------------------
      -- Transceiver high speed lanes
      fpgaOutObTransInP : out slv(7 downto 0);
      fpgaOutObTransInM : out slv(7 downto 0);
      fpgaInObTransOutP : in  slv(7 downto 0);
      fpgaInObTransOutM : in  slv(7 downto 0);

      -- Transceiver low speed control
      obTransScl        : out sl;
      obTransSda        : inout sl;
      obTransResetL     : out sl;
      obTransIntL       : out sl;

      -- Jitter Cleaner PLL Ports
      jitclnrCsL     : out sl;
      jitclnrIntr    : in sl;
      jitclnrLolL    : in sl;
      jitclnrOeL     : out sl;
      jitclnrRstL    : out sl;
      jitclnrSclk    : out sl;
      jitclnrSdio    : out sl;
      jitclnrSdo     : in sl;
      jitclnrSel     : out slv(1 downto 0)

  );
end entity;

architecture rtl of Core is

   constant SYSDEV_INDEX_C     : natural  := 0;
   constant PGP_INDEX_C        : natural  := 1;
   constant APP_INDEX_C        : natural  := 2;
   constant NUM_AXIL_MASTERS_C : positive := 3; 
   
   constant XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
      SYSDEV_INDEX_C => (baseAddr => x"0000_0000", addrBits => 24, connectivity => x"FFFF"),
      PGP_INDEX_C    => (baseAddr => x"0100_0000", addrBits => 24, connectivity => x"FFFF"),
      APP_INDEX_C    => (baseAddr => x"8000_0000", addrBits => 31, connectivity => x"FFFF"));

   signal mAxilWriteMaster : AxiLiteWriteMasterType;
   signal mAxilWriteSlave  : AxiLiteWriteSlaveType;
   signal mAxilReadMaster  : AxiLiteReadMasterType;
   signal mAxilReadSlave   : AxiLiteReadSlaveType;

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_SLVERR_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_SLVERR_C);

   signal axilClock : sl;
   signal axilReset : sl;
   signal fabRefClk : sl;
   signal gtRefClk  : sl;
   signal fabClock  : sl;
   signal fabReset  : sl;

  begin
    

  -----------------
   -- System Devices
   -----------------
   U_SysDev : entity work.SystemDevices
      generic map (
         TPD_G            => TPD_G,
         SIMULATION_G     => SIMULATION_G,
         BUILD_INFO_G     => BUILD_INFO_G,
         AXIL_BASE_ADDR_G => XBAR_CONFIG_C(SYSDEV_INDEX_C).baseAddr)
      port map(
         -- AXI-Lite Interface
         axilClk         => axilClock,
         axilRst         => axilReset,
         axilReadMaster  => axilReadMasters(SYSDEV_INDEX_C),
         axilReadSlave   => axilReadSlaves(SYSDEV_INDEX_C),
         axilWriteMaster => axilWriteMasters(SYSDEV_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(SYSDEV_INDEX_C),
         -------------------
         --  Top Level Ports
         -------------------
         -- Jitter Cleaner PLL Ports
         jitclnrCsL  => jitclnrCsL, 
         jitclnrIntr => jitclnrIntr,
         jitclnrLolL => jitclnrLolL,
         jitclnrOeL  => jitclnrOeL, 
         jitclnrRstL => jitclnrRstL,
         jitclnrSclk => jitclnrSclk,
         jitclnrSdio => jitclnrSdio,
         jitclnrSdo  => jitclnrSdo, 
         jitclnrSel  => jitclnrSel, 

         -- LEAP Transceiver Ports
         obTransScl      => obTransScl,
         obTransSda      => obTransSda,
         obTransResetL   => obTransResetL,
         obTransIntL     => obTransIntL,
         -- SYSMON Ports
         vPIn            => vPIn,
         vNIn            => vNIn);

end rtl ; -- rtl