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
use surf.Pgp2bPkg.all;

library unisim;
use unisim.vcomponents.all;

use work.AppPkg.all;

library epix_leap_core;
use epix_leap_core.CorePkg.all;

entity AsicTop is
   generic (
      TPD_G                   : time          := 1 ns;
      SIMULATION_G            : boolean       := false;
      EN_DEVICE_DNA_G         : boolean       := true;
      CLK_PERIOD_G            : real          := 10.0e-9;
      ASIC_AXIL_BASE_ADDR_G   : slv(31 downto 0);
      BUILD_INFO_G            : BuildInfoType
   );
   port (
      ----------------------------------------
      --      Interfaces to Application     --
      ----------------------------------------
      -- AXI-Lite Interface (axilClk domain): Address Range = [0x80000000:0xFFFFFFFF]
      axiClk             : in  sl;
      axiRst             : in  sl;
      axilReadMaster : in  AxiLiteReadMasterType;
      axilReadSlave  : out AxiLiteReadSlaveType;
      axilWriteMaster: in  AxiLiteWriteMasterType;
      axilWriteSlave : out AxiLiteWriteSlaveType;

      -- Streaming Interfaces (axilClk domain)
      asicDataMasters: out AxiStreamMasterArray(NUMBER_OF_ASICS_C - 1 downto 0);
      asicDataSlaves : in  AxiStreamSlaveArray(NUMBER_OF_ASICS_C - 1 downto 0);
      remoteDmaPause : in  slv(NUMBER_OF_ASICS_C - 1 downto 0);

      -- Trigger Interface (triggerClk domain)
      triggerClk           : out   sl;
      triggerRst           : out   sl;
      triggerData          : in    TriggerEventDataArray(1 downto 0);

      ----------------------------------------
      --          Top Level Ports           --
      ----------------------------------------
      -- ASIC Control Ports
      asicR0         : out sl;
      asicGlblRst    : out sl;
      asicSync       : out sl;
      asicAcq        : out sl;
      asicSro        : out sl;
      asicRdClk      : in sl;
      asicClkEn      : out sl;

      asicDataP: in Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
      asicDataM: in Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);

      -- Digital Monitor
      digMon: in slv(1 downto 0);
      
      -- Clocking ports
      refClk      : in sl;
      refRst      : in sl;
      -- appClk      : in sl;
      -- appRst      : in sl;

      -- SSI commands
      ssiCmd: in SsiCmdMasterType;

      daqToFpga: in  sl;
      ttlToFpga: in  sl

   );
end AsicTop;

architecture rtl of AsicTop is
   constant NUM_ASIC_AXIL_SLAVES_C        : natural := 1;
   constant NUM_ASIC_AXIL_MASTERS_C       : natural := 15;

   constant REGCTRL_AXI_INDEX_C           : natural := 0;
   constant TRIGCTRL_AXI_INDEX_C          : natural := 1;

   constant DIG_ASIC_STREAM_AXI_INDEX_C   : natural := 8; 
   constant AXI_STREAM_MON_INDEX_C        : natural := 12;

   signal ASIC_AXIL_CONFIG_G     : AxiLiteCrossbarMasterConfigArray(NUM_ASIC_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_ASIC_AXIL_MASTERS_C, ASIC_AXIL_BASE_ADDR_G, 24, 20);

   -- Master AXI-Lite Signals
   signal axilWriteMasters   : AxiLiteWriteMasterArray(NUM_ASIC_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves    : AxiLiteWriteSlaveArray(NUM_ASIC_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_SLVERR_C);
   signal axilReadMasters    : AxiLiteReadMasterArray(NUM_ASIC_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves     : AxiLiteReadSlaveArray(NUM_ASIC_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_READ_SLAVE_EMPTY_SLVERR_C);
   
   signal dataSend             : sl;
   signal dataSendStreched     : sl;
   signal acqStart             : sl;

   signal timingRunTrigger     : sl;
   signal timingDaqTrigger     : sl;
   signal errInhibit           : sl;


begin

   timingRunTrigger <= triggerData(0).valid and triggerData(0).l0Accept;
   timingDaqTrigger <= triggerData(1).valid and triggerData(1).l0Accept;

   U_AxiLiteCrossbar : entity surf.AxiLiteCrossbar
      generic map (
         NUM_SLAVE_SLOTS_G  => NUM_ASIC_AXIL_SLAVES_C,
         NUM_MASTER_SLOTS_G => NUM_ASIC_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => ASIC_AXIL_CONFIG_G
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

   U_RegCtrl : entity work.RegisterControl
      generic map (
         TPD_G           => TPD_G,
         EN_DEVICE_DNA_G => EN_DEVICE_DNA_G,
         CLK_PERIOD_G    => CLK_PERIOD_G,
         BUILD_INFO_G    => BUILD_INFO_G
      )
      port map (
         axiClk          => axiClk,
         axiRst          => axiRst,
         axiReadMaster   => axilReadMasters(REGCTRL_AXI_INDEX_C),
         axiReadSlave    => axilReadSlaves(REGCTRL_AXI_INDEX_C),
         axiWriteMaster  => axilWriteMasters(REGCTRL_AXI_INDEX_C),
         axiWriteSlave   => axilWriteSlaves(REGCTRL_AXI_INDEX_C),

         -- ASICs acquisition signals
         acqStart    => acqStart,
         asicPPbe    => iAsicPpbe,
         asicPpmat   => iAsicPpmat,
         asicTpulse  => open,
         asicStart   => asicR0,
         asicSR0     => asicSro,
         asicGlblRst => asicGlblRst,
         asicSync    => asicSync,
         asicAcq     => asicAcq,
         asicClkEn   => asicClkEn,
         errInhibit  => errInhibit
      );

   ------------------------------------------
   --             Trig control             --
   ------------------------------------------ 
   U_TrigControl : entity epix_hr_core.TrigControlAxi
      port map (
         -- Trigger outputs
         appClk            => axiClk,
         appRst            => axiRst,
         acqStart          => acqStart,
         dataSend          => dataSend,

         -- External trigger inputs
         runTrigger        => ttlToFpga,
         daqTrigger        => daqToFpga,

         -- PGP clocks and reset
         sysClk            => axiClk,
         sysRst            => axiRst,

         -- SW trigger in (from VC)
         ssiCmd            => ssiCmd,

         -- Fiber optic trigger (axilClk domain)
         pgpRxOut          => PGP2B_RX_OUT_INIT_C,
         -- Fiducial code output
         opCodeOut         => open,
         -- Timing Triggers
         timingRunTrigger  => timingRunTrigger,
         timingDaqTrigger  => timingDaqTrigger,
         -- AXI lite slave port for register access
         axilClk           => axiClk,
         axilRst           => axiRst,
         sAxilWriteMaster  => axilWriteMasters(TRIGCTRL_AXI_INDEX_C),
         sAxilWriteSlave   => axilWriteSlaves(TRIGCTRL_AXI_INDEX_C),
         sAxilReadMaster   => axilReadMasters(TRIGCTRL_AXI_INDEX_C),
         sAxilReadSlave    => axilReadSlaves(TRIGCTRL_AXI_INDEX_C)
      );
   
   
      U_DataSendStretcher : entity surf.SynchronizerOneShot 
         generic map(
            TPD_G          => TPD_G,
            RST_ASYNC_G    => false,
            RST_POLARITY_G => '1',    -- '1' for active HIGH reset, '0' for active LOW reset
            BYPASS_SYNC_G  => false,  -- Bypass RstSync module for synchronous data configuration
            IN_POLARITY_G  => '1',    -- 0 for active LOW, 1 for active HIGH
            OUT_POLARITY_G => '1',    -- 0 for active LOW, 1 for active HIGH
            OUT_DELAY_G    => 3,      -- Stages in output sync chain
            PULSE_WIDTH_G  => 4       -- one-shot pulse width duration (units of clk cycles)
         )
         port map(
            clk     => refClk,
            rst     => refRst,
            dataIn  => dataSend,
            dataOut => dataSendStreched
         );

   
      -----------------------------------------------------------------------------
      -- generate stream frames
      -----------------------------------------------------------------------------
      G_ASICS : for i in NUMBER_OF_ASICS_C - 1 downto 0 generate
         U_Framers : entity work.DigitalAsicStreamAxiV2
            generic map(
               TPD_G               => TPD_G,
               VC_NO_G             => "0000",
               LANE_NO_G           => toSlv(i, 4),
               ASIC_NO_G           => toSlv(i, 3),
               LANES_NO_G          => 24
               )
            port map(
               -- Deserialized data port
               deserClk          => asicRdClk,
               deserRst          => deserRst,
               rxValid           => rxValid,
               rxData            => rxData,
               rxSof             => rxSof,
               rxEof             => rxEof,
               rxEofe            => rxEofe,
            
               -- AXI lite slave port for register access
               axilClk           => appClk,
               axilRst           => appRst,
               sAxilWriteMaster  => axilWriteMaster,
               sAxilWriteSlave   => axilWriteSlave,
               sAxilReadMaster   => axilReadMaster,
               sAxilReadSlave    => axilReadSlave,
            
               -- AXI data stream output
               axisClk           => sysClk,
               axisRst           => sysRst,
               mAxisMaster       => mAxisMastersASIC(0),
               mAxisSlave        => mAxisSlavesASIC(0),
            
               -- acquisition number input to the header
               acqNo             => boardConfig.acqCnt
            );
      end generate;
      
      
      -------------------------------------------------------
      -- AXI stream monitoring                             --
      -------------------------------------------------------
      U_AxiSMonitor : entity surf.AxiStreamMonAxiL
         generic map(
            TPD_G           => 1 ns,
            COMMON_CLK_G    => false,  -- true if axisClk = statusClk
            AXIS_CLK_FREQ_G => 156.25E+6,  -- units of Hz
            AXIS_NUM_SLOTS_G=> NUMBER_OF_LANES_C,
            AXIS_CONFIG_G   => COMM_AXIS_CONFIG_C
            )
         port map(
            -- AXIS Stream Interface
            axisClk         => sysClk,
            axisRst         => sysRst,
            axisMasters(0)  => imAxisMasters(0),
            axisSlaves(0)   => mAxisSlaves(0),
            -- AXI lite slave port for register access
            axilClk         => axilClk,
            axilRst         => axilRst,
            sAxilWriteMaster=> axilWriteMaster,
            sAxilWriteSlave => axilWriteSlave,
            sAxilReadMaster => axilReadMaster,
            sAxilReadSlave  => axilReadSlave
         );  

end architecture;