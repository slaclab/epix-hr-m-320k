-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Wrapper for DAC modules
-------------------------------------------------------------------------------
-- This file is part of 'Simple-PGPv4-KCU105-Example'.
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

library epix_hr_core;

library epix_leap_core;
use epix_leap_core.CorePkg.all;

library unisim;
use unisim.vcomponents.all;

entity Dac is
   generic (
      TPD_G            : time    := 1 ns;
      SIMULATION_G     : boolean := false;
      AXIL_BASE_ADDR_G : slv(31 downto 0));
   port (
      dacTrig         : in  sl;
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      -------------------
      --  Top Level Ports
      -------------------
      -- DAC Ports
      -- Bias DAC
      biasDacDin     : out sl;
      biasDacSclk    : out sl;
      biasDacCsb     : out sl;
      biasDacClrb    : out sl;

      -- High Speed DAC
      hsDacSclk      : out sl;
      hsDacDin       : out sl;
      hsCsb          : out sl;
      hsLdacb        : out sl
      );
end Dac;

architecture mapping of Dac is

   constant NUM_AXIL_MASTERS_C : positive := 2;
   constant HS_DAC_INDEX_C : natural   := 1;
   constant BIAS_DAC_INDEX_C : natural := 2;


   constant XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 20, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_SLVERR_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_SLVERR_C);

begin

   ---------------------------
   -- AXI-Lite Crossbar Module
   ---------------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => XBAR_CONFIG_C)
      port map (
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves,
         axiClk              => axilClk,
         axiClkRst           => axilRst);

   ----------------------------
   -- High speed DAC (DAC8812C)
   ----------------------------
   U_HS_DAC : entity epix_hr_core.DacWaveformGenAxi
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Master system clock
         sysClk           => axilClk,
         sysClkRst        => axilRst,
         -- DAC Control Signals
         dacDin           => hsDacDin,
         dacSclk          => hsDacSclk,
         dacCsL           => hsCsb,
         dacLdacL         => hsLdacb,
         dacClrL          => open,
         -- external trigger
         externalTrigger  => dacTrig,
         -- AXI lite slave port for register access
         axilClk          => axilClk,
         axilRst          => axilRst,
         sAxilWriteMaster => axilWriteMasters(HS_DAC_INDEX_C - 1 downto 0),
         sAxilWriteSlave  => axilWriteSlaves(HS_DAC_INDEX_C - 1 downto 0),
         sAxilReadMaster  => axilReadMasters(HS_DAC_INDEX_C - 1 downto 0),
         sAxilReadSlave   => axilReadSlaves(HS_DAC_INDEX_C - 1 downto 0)
      );

   --------------------------
   -- Low Speed DAC (MAX5443)
   --------------------------
   U_LS_DAC : entity surf.Max5443
      generic map (
         TPD_G        => TPD_G,
         CLK_PERIOD_G => AXIL_CLK_PERIOD_C,
         NUM_CHIPS_G  => 1)
      port map (
         -- Global Signals
         axilClk         => axilClk,
         axilRst         => axilRst,
         -- AXI-Lite Register Interface (axiClk domain)
         axilReadMaster  => axilReadMasters(BIAS_DAC_INDEX_C),
         axilReadSlave   => axilReadSlaves(BIAS_DAC_INDEX_C),
         axilWriteMaster => axilWriteMasters(BIAS_DAC_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(BIAS_DAC_INDEX_C),
         -- Guard ring DAC interfaces
         dacSclk         => biasDacSclk,
         dacDin          => biasDacDin,
         dacCsb(0)       => biasDacCsb,
         dacClrb         => biasDacClrb
      );

end mapping;
