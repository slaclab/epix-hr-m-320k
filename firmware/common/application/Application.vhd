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
      rdClkSel           : out sl;

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
      pwrGood            : in  slv(1 downto 0);

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
      slowAdcRefClk      : out sl;
   
      jitclnrLolL        : in sl
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

   signal clk156           : sl;
   signal rst156           : sl;
   signal clk250           : sl;
   signal clk100           : sl;
   signal rst250           : sl;
   signal sspClk           : sl;
   signal sspRst           : sl;
   
   signal sspLinkUp        : Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
   signal sspValid         : Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
   signal sspData          : Slv16Array((NUMBER_OF_ASICS_C * 24)-1 downto 0);
   signal sspSof           : Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
   signal sspEof           : Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
   signal sspEofe          : Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);

begin
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

   U_ClkGen : entity work.appClk
      generic map (
         TPD_G          => TPD_G,
         SIMULATION_G   => SIMULATION_G
         )
      port map (
         -- 156.25 MHz Clock input
         gtRefClkP     =>  gtRefClkP,
         gtRefClkM     =>  gtRefClkM,
         -- 250 Mhz Pll Output
         gtPllClkP     => gtPllClkP,
         gtPllClkM     => gtPllClkM,
         -- 40 Mhz clock output to pll(2)
         fpgaClkOutP   => fpgaClkOutP, 
         fpgaClkOutM   => fpgaClkOutM, 
         adcClk        => open,

         jitclnLolL    => jitclnrLolL,
         clk156        => clk156,
         rst156        => rst156,
         clk250        => clk250,
         rst250        => rst250,
         sspClk        => sspClk,
         sspRst        => sspRst
      
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
         rdClkSel        => rdClkSel,

         -- SSI commands
         ssiCmd         => ssiCmd,

         -- External trigger inputs
         daqToFpga      => daqToFpga,
         ttlToFpga      => ttlToFpga
      );

   -- U_PwrCtrl : entity work.PowerCtrl
   --    generic map (
   --       TPD_G             => TPD_G,
   --       EN_DEVICE_DNA_G   => EN_DEVICE_DNA_G
   --    )
   --    port map (
   --       axiClk             => axiClk,
   --       axiRst             => axiRst,
   --       axilReadMaster     => axilReadMasters(POWER_CONTROL_INDEX_C),
   --       axilReadSlave      => axilReadSlaves(POWER_CONTROL_INDEX_C),
   --       axilWriteMaster    => axilWriteMasters(POWER_CONTROL_INDEX_C),
   --       axilWriteSlave     => axilWriteSlaves(POWER_CONTROL_INDEX_C),
   --       syncDcdc           => syncDcdc,
   --       ldoShtdnL          => ldoShtdnL,
   --       dcdcSync           => dcdcSync,
   --       pcbSync            => pcbSync,
   --       pcbLocalSupplyGood => pcbLocalSupplyGood
   --    );
   
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
   end rtl; -- rtl