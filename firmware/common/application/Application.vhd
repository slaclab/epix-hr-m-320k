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
use surf.AxiPkg.all;
use surf.I2cPkg.all;
use surf.SsiCmdMasterPkg.all;

library unisim;
use unisim.vcomponents.all;

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
      axilClk            : in sl;
      axilRst            : in sl;

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
      asicDataP          : in Slv24Array(3 downto 0);
      asicDataM          : in Slv24Array(3 downto 0);

      -- Fast ADC Ports
      adcMonDataP        : in slv(11 downto 0);
      adcMonDataM        : in slv(11 downto 0);
      adcDoClkP          : in slv(1 downto 0);
      adcDoClkM          : in slv(1 downto 0);
      adcFrameClkP       : in slv(1 downto 0);
      adcFrameClkM       : in slv(1 downto 0);

      -- ASIC Control Ports
      asicR0             : out sl;
      asicGlblRst        : out sl;
      asicSync           : out sl;
      asicAcq            : out sl;
      asicRoClkP         : out slv(3 downto 0);
      asicRoClkN         : out slv(3 downto 0);
      asicSro            : out sl;
      asicClkEn          : out sl;

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
   constant APP_CLK_INDEX_C    : natural := 0;
   constant NUM_AXIL_MASTERS_C : natural := 1;

   constant XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, APP_AXIL_BASE_ADDR_C, 28, 24);



begin
   
   -- U_XBAR : entity surf.AxiLiteCrossbar
   --    generic map (
   --       TPD_G              => TPD_G,
   --       NUM_SLAVE_SLOTS_G  => 1,
   --       NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
   --       MASTERS_CONFIG_G   => XBAR_CONFIG_C
   --    )
   --    port map (
   --       axiClk              => axilClk,
   --       axiClkRst           => axilRst,
   --       sAxiWriteMasters(0) => axilWriteMaster,
   --       sAxiWriteSlaves(0)  => axilWriteSlave,
   --       sAxiReadMasters(0)  => axilReadMaster,
   --       sAxiReadSlaves(0)   => axilReadSlave,
   --       mAxiWriteMasters    => axilWriteMasters,
   --       mAxiWriteSlaves     => axilWriteSlaves,
   --       mAxiReadMasters     => axilReadMasters,
   --       mAxiReadSlaves      => axilReadSlaves
   --    );

   end rtl; -- rtl