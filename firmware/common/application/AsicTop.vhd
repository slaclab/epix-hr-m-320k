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
use surf.SsiPkg.all;
use surf.Pgp2bPkg.all;

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;

library l2si_core;
use l2si_core.L2SiPkg.all;

library unisim;
use unisim.vcomponents.all;

use work.AppPkg.all;

library epix_leap_core;
use epix_leap_core.CorePkg.all;

library epix_hr_core;

entity AsicTop is
   generic (
      TPD_G                   : time          := 1 ns;
      SIMULATION_G            : boolean       := false;
      EN_DEVICE_DNA_G         : boolean       := true;
      CLK_PERIOD_G            : real          := 156.25E+6;
      AXIL_BASE_ADDR_G        : slv(31 downto 0);
      NUM_OF_PSCOPE_G         : integer       := 4;
      NUM_OF_SLOW_ADCS_G      : integer       := 2;
      BUILD_INFO_G            : BuildInfoType
   );
   port (
      ----------------------------------------
      --      Interfaces to Application     --
      ----------------------------------------
      -- AXI-Lite Interface (axilClk domain): Address Range = [0x80000000:0xFFFFFFFF]
      axiClk             : in  sl;
      axiRst             : in  sl;
      axilReadMaster     : in  AxiLiteReadMasterType;
      axilReadSlave      : out AxiLiteReadSlaveType;
      axilWriteMaster    : in  AxiLiteWriteMasterType;
      axilWriteSlave     : out AxiLiteWriteSlaveType;

      -- Streaming Interfaces (axilClk domain)
      asicDataMasters    : out AxiStreamMasterArray(NUMBER_OF_ASICS_C - 1 downto 0);
      asicDataSlaves     : in  AxiStreamSlaveArray(NUMBER_OF_ASICS_C - 1 downto 0);
      remoteDmaPause     : in  slv(NUMBER_OF_ASICS_C - 1 downto 0);

      -- Trigger Interface (triggerClk domain)
      triggerClk         : out   sl;
      triggerRst         : out   sl;
      triggerData        : in    TriggerEventDataArray(1 downto 0);

      -- Optional: L1 trigger feedback (eventClk domain)
      l1Clk                : out   sl                    := '0';
      l1Rst                : out   sl                    := '0';
      l1Feedbacks          : out   TriggerL1FeedbackArray(1 downto 0):= (others => TRIGGER_L1_FEEDBACK_INIT_C);
      l1Acks               : in    slv(1 downto 0);

      -- Event streams (eventClk domain)
      eventClk             : out   sl;
      eventRst             : out   sl;
      eventTrigMsgMasters  : in    AxiStreamMasterArray(1 downto 0);
      eventTrigMsgSlaves   : out   AxiStreamSlaveArray(1 downto 0);
      eventTrigMsgCtrl     : out   AxiStreamCtrlArray(1 downto 0) := (others => AXI_STREAM_CTRL_UNUSED_C);
      eventTimingMsgMasters: in    AxiStreamMasterArray(1 downto 0);
      eventTimingMsgSlaves : out   AxiStreamSlaveArray(1 downto 0);
      clearReadout         : in    slv(1 downto 0);
      
      -- ADC/DAC Debug Trigger Interface (axilClk domain)
      oscopeAcqStart       : out   slv(NUM_OF_PSCOPE_G - 1 downto 0);
      oscopeTrigBus        : out   slv(11 downto 0);
      slowAdcAcqStart      : out   slv(NUM_OF_SLOW_ADCS_G - 1 downto 0);
      dacTrig              : out   sl;

      -- SSP Interfaces (sspClk domain)
      sspClk         : in sl;
      sspRst         : in sl;
      sspLinkUp      : in Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
      sspValid       : in Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
      sspData        : in Slv16Array((NUMBER_OF_ASICS_C * 24)-1 downto 0);
      sspSof         : in Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
      sspEof         : in Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
      sspEofe        : in Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);

      ----------------------------------------
      --          Top Level Ports           --
      ----------------------------------------
      -- ASIC Control Ports
      asicR0         : out sl;
      asicGlblRst    : out sl;
      asicDigRst     : out sl;
      asicSync       : out sl;
      asicAcq        : out sl;
      asicSro        : out sl;
      asicClkEn      : out sl;
      rdClkSel       : out sl;
      asicClkSyncEn  : out sl;

      -- Digital Monitor
      digMon   : in slv(1 downto 0);
      
      -- Clocking ports
      sysClk      : in sl;
      sysRst      : in sl;

      -- SSI commands
      ssiCmd      : in SsiCmdMasterType;

      -- TTL external input triggers
      daqToFpga      : in  sl;
      ttlToFpga      : in  sl;

      serialNumber         : inout slv(2 downto 0);

      -- Timing link up
      v1LinkUp             : in    sl;
      v2LinkUp             : in    sl;
      boardConfig          : out   AppConfigType
   );
end AsicTop;

architecture rtl of AsicTop is
   constant NUM_ASIC_AXIL_SLAVES_C        : natural := 1;
   constant NUM_ASIC_AXIL_MASTERS_C       : natural := 10;

   constant REGCTRL_AXI_INDEX_C           : natural := 0;
   constant TRIGCTRL_AXI_INDEX_C          : natural := 1;
   constant DIG_ASIC_STREAM_AXI_INDEX_C   : natural := 2; 
   constant EVENTBUILDER0_INDEX_C         : natural := 6;

   signal ASIC_AXIL_CONFIG_G            : AxiLiteCrossbarMasterConfigArray(NUM_ASIC_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_ASIC_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 24, 20);

   -- Master AXI-Lite Signals
   signal axilWriteMasters             : AxiLiteWriteMasterArray(NUM_ASIC_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves              : AxiLiteWriteSlaveArray(NUM_ASIC_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_WRITE_SLAVE_EMPTY_SLVERR_C);
   signal axilReadMasters              : AxiLiteReadMasterArray(NUM_ASIC_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves               : AxiLiteReadSlaveArray(NUM_ASIC_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_READ_SLAVE_EMPTY_SLVERR_C);
   
   -- AXI/PRBS Streams, one per carrier
   signal mAxisMastersASIC             : AxiStreamMasterArray(NUMBER_OF_ASICS_C - 1 downto 0);
   signal mAxisSlavesASIC              : AxiStreamSlaveArray(NUMBER_OF_ASICS_C - 1 downto 0);
   
   -- duplicated timing information
   signal eventTimingMsgMasterArray  : AxiStreamMasterArray(NUMBER_OF_ASICS_C - 1 downto 0);
   signal eventTimingMsgSlaveArray   : AxiStreamSlaveArray(NUMBER_OF_ASICS_C - 1 downto 0);
   
   -- AXI-Lite batcher
   signal axilBatcherReadMaster  : AxiLiteReadMasterArray(NUMBER_OF_ASICS_C - 1 downto 0);
   signal axilBatcherReadSlave   : AxiLiteReadSlaveArray(NUMBER_OF_ASICS_C - 1 downto 0);
   signal axilBatcherWriteMaster : AxiLiteWriteMasterArray(NUMBER_OF_ASICS_C - 1 downto 0);
   signal axilBatcherWriteSlave  : AxiLiteWriteSlaveArray(NUMBER_OF_ASICS_C - 1 downto 0);

   -- Timing info synched to axilClk
   signal eventTimingMsgMasterAxiLSync  : AxiStreamMasterType;
   signal eventTimingMsgSlaveAxiLSync   : AxiStreamSlaveType;

   signal boardConfigSig                  : AppConfigType;

   -- External Signals 
   signal serialIdIo                   : slv(2 downto 0) := (others => '0');
   signal snCardId                     : Slv64Array(2 downto 0) := (others => (others => '0'));

   signal dataSend                     : sl;
   signal dataSendStreched             : sl;
   signal acqStart                     : sl;

   signal timingRunTrigger             : sl;
   signal timingDaqTrigger             : sl;
   signal errInhibit                   : sl;

   signal iAsicPpmat                   : sl;
   signal iAsicR0                      : sl;
   signal iAsicAcq                     : sl;
   signal iAsicPPbe                    : sl;
   signal iAsicDigRst                  : sl;
   signal iAsicSRO                     : sl;
   signal saciPrepReadoutAck           : sl;

   signal iAsicClkSyncEn               : sl;
   signal iAsicGlblRst                 : sl;
   signal iAsicSync                    : sl;

begin

   triggerClk       <= axiClk;
   triggerRst       <= axiRst;

   eventClk         <= axiClk;
   eventRst         <= axiRst;

   oscopeAcqStart   <= (others => '0');
   oscopeTrigBus    <= (others => '0');
   slowAdcAcqStart  <= (others => '0');
   dacTrig          <= '0';

   timingRunTrigger <= triggerData(0).valid and triggerData(0).l0Accept;
   timingDaqTrigger <= triggerData(1).valid and triggerData(1).l0Accept;

   boardConfig      <= boardConfigSig;

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

   U_RegCtrl : entity work.RegisterControlDualClock
      generic map (
         TPD_G           => TPD_G,
         EN_DEVICE_DNA_G => EN_DEVICE_DNA_G,
         CLK_PERIOD_G    => CLK_PERIOD_G,
         BUILD_INFO_G    => BUILD_INFO_G
      )
      port map (
         axilClk          => axiClk,
         axilRst          => axiRst,
         axiReadMaster   => axilReadMasters(REGCTRL_AXI_INDEX_C),
         axiReadSlave    => axilReadSlaves(REGCTRL_AXI_INDEX_C),
         axiWriteMaster  => axilWriteMasters(REGCTRL_AXI_INDEX_C),
         axiWriteSlave   => axilWriteSlaves(REGCTRL_AXI_INDEX_C),

         -- Register Inputs/Outputs (axiClk domain)
         boardConfig    => boardConfigSig,

         -- 1-wire board ID interfaces
         serialIdIo     => serialIdIo,

         -- sys clock signals (ASIC RD clock domain)
         sysRst         => sysRst,
         sysClk         => sysClk,

         -- ASICs acquisition signals
         acqStart       => acqStart,
         asicR0         => iAsicR0,
         asicAcq        => iAsicAcq,
         asicPPbe       => iAsicPPbe,
         asicDigRst     => iAsicDigRst,
         saciReadoutReq => open,
         saciReadoutAck => saciPrepReadoutAck,
         errInhibit     => open,
         rdClkSel       => rdClkSel,

         asicSRO        => iAsicSRO,
         asicClkSyncEn  => iAsicClkSyncEn,
         asicGlblRst    => iAsicGlblRst,
         asicSync       => iAsicSync,

         v1LinkUp => v1LinkUp,
         v2LinkUp => v2LinkUp
      );

   ------------------------------------------
   --             Trig control             --
   ------------------------------------------ 
   U_TrigControl : entity work.TrigControlAxi
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
   
   -------------------------------------------------
   -- AxiStream repeater
   -------------------------------------------------
   U_AxiStreamRepeater_timing : entity surf.AxiStreamRepeater
      generic map(
         TPD_G                => TPD_G,
         NUM_MASTERS_G        => NUMBER_OF_ASICS_C,
         INCR_AXIS_ID_G       => false,
         INPUT_PIPE_STAGES_G  => 0,
         OUTPUT_PIPE_STAGES_G => 0
         )
      port map(
         -- Clock and reset
         axisClk      => axiClk,
         axisRst      => axiRst,
         -- Slave
         sAxisMaster  => eventTimingMsgMasters(1),
         sAxisSlave   => eventTimingMsgSlaves(1),
         -- Masters
         mAxisMasters => eventTimingMsgMasterArray,
         mAxisSlaves  => eventTimingMsgSlaveArray
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
            clk     => axiClk,
            rst     => axiRst,
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
               deserClk          => sspClk,
               deserRst          => sspRst,
               rxValid           => sspValid(i),
               rxData            => sspData(24*i+23 downto 24*i),
               rxSof             => sspSof(i),
               rxEof             => sspEof(i),
               rxEofe            => sspEofe(i),
            
               -- AXI lite slave port for register access
               axilClk           => axiClk,
               axilRst           => axiRst,
               sAxilWriteMaster  => axilWriteMasters(DIG_ASIC_STREAM_AXI_INDEX_C + i),
               sAxilWriteSlave   => axilWriteSlaves(DIG_ASIC_STREAM_AXI_INDEX_C + i),
               sAxilReadMaster   => axilReadMasters(DIG_ASIC_STREAM_AXI_INDEX_C + i),
               sAxilReadSlave    => axilReadSlaves(DIG_ASIC_STREAM_AXI_INDEX_C + i),
            
               -- AXI data stream output
               axisClk           => axiClk,
               axisRst           => axiRst,
               mAxisMaster       => mAxisMastersASIC(i),
               mAxisSlave        => mAxisSlavesASIC(i),
            
               -- acquisition number input to the header
               acqNo             => boardConfigSig.acqCnt,
               startRdout        => dataSendStreched
            );
      
      U_EventBuilder : entity surf.AxiStreamBatcherEventBuilder
         generic map (
              TPD_G          => TPD_G,
              NUM_SLAVES_G   => 2,
              MODE_G         => "ROUTED",
              TDEST_ROUTES_G => (
                0           => "0000000-",
                1           => "00000010"),
              TRANS_TDEST_G  => X"01",
              AXIS_CONFIG_G  => SSI_CONFIG_INIT_C
              )
            port map (
              -- Clock and Reset
              axisClk                    => axiClk,
              axisRst                    => axiRst,
              -- AXI-Lite Interface (axisClk domain)
              axilReadMaster             => axilReadMasters(EVENTBUILDER0_INDEX_C + i),
              axilReadSlave              => axilReadSlaves(EVENTBUILDER0_INDEX_C + i),
              axilWriteMaster            => axilWriteMasters(EVENTBUILDER0_INDEX_C + i),
              axilWriteSlave             => axilWriteSlaves(EVENTBUILDER0_INDEX_C + i),
              -- Inbound Master AXIS Interfaces
              sAxisMasters(0)            => eventTimingMsgMasterArray(i),
              sAxisMasters(1)            => mAxisMastersASIC(i),
              -- Inbound Slave AXIS Interfaces
              sAxisSlaves(0)             => eventTimingMsgSlaveArray(i),
              sAxisSlaves(1)             => mAxisSlavesASIC(i),
              -- Outbound AXIS
              mAxisMaster                => asicDataMasters(i), --to core
              mAxisSlave                 => asicDataSlaves(i)   --to core
              );
      end generate;
   
   asicAcq <= iAsicAcq;
   asicR0 <= iAsicSRO;
   asicGlblRst <= iAsicGlblRst;
   asicSync <= iAsicSync;
   asicDigRst <= iAsicDigRst;

end architecture;