-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- This file is part of LCLS2 PGP Firmware Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of LCLS2 PGP Firmware Library', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library lcls_timing_core;
use lcls_timing_core.TimingPkg.all;

library l2si_core;
use l2si_core.L2SiPkg.all;

library unisim;
use unisim.vcomponents.all;

entity TimingRx is
   generic (
      TPD_G               : time    := 1 ns;
      SIMULATION_G        : boolean := false;
      AXIL_CLK_FREQ_G     : real    := 156.25E+6;  -- units of Hz
      EVENT_AXIS_CONFIG_G : AxiStreamConfigType;
      AXIL_BASE_ADDR_G    : slv(31 downto 0);
      NUM_DETECTORS_G     : integer range 1 to 4
      );
   port (
      -- Trigger Interface
      triggerClk           : in  sl;
      triggerRst           : in  sl;
      triggerData          : out TriggerEventDataArray(NUM_DETECTORS_G - 1 downto 0);
      -- L1 trigger feedback (optional)
      l1Clk                : in  sl                    := '0';
      l1Rst                : in  sl                    := '0';
      l1Feedbacks          : in  TriggerL1FeedbackArray(NUM_DETECTORS_G - 1 downto 0):= (others => TRIGGER_L1_FEEDBACK_INIT_C);
      l1Acks               : out slv(NUM_DETECTORS_G - 1 downto 0);
      -- Event streams
      eventClk             : in  sl;
      eventRst             : in  sl;
      eventTrigMsgMasters  : out AxiStreamMasterArray(NUM_DETECTORS_G - 1 downto 0);
      eventTrigMsgSlaves   : in  AxiStreamSlaveArray(NUM_DETECTORS_G - 1 downto 0);
      eventTrigMsgCtrl     : in  AxiStreamCtrlArray(NUM_DETECTORS_G - 1 downto 0);
      eventTimingMsgMasters: out AxiStreamMasterArray(NUM_DETECTORS_G - 1 downto 0);
      eventTimingMsgSlaves : in  AxiStreamSlaveArray(NUM_DETECTORS_G - 1 downto 0);
      clearReadout         : out slv(NUM_DETECTORS_G - 1 downto 0)       := (others => '0');
      -- AXI-Lite Interface
      axilClk              : in  sl;
      axilRst              : in  sl;
      axilReadMaster       : in  AxiLiteReadMasterType;
      axilReadSlave        : out AxiLiteReadSlaveType;
      axilWriteMaster      : in  AxiLiteWriteMasterType;
      axilWriteSlave       : out AxiLiteWriteSlaveType;
      -- GT Clock Ports
      gtLclsClkP           : in  sl;
      gtLclsClkN           : in  sl;
      -- LEAP Transceiver Ports
      leapTxP              : out sl;
      leapTxN              : out sl;
      leapRxP              : in  sl;
      leapRxN              : in  sl;
      -- Timing link up status
      v1LinkUp             : out sl;
      v2LinkUp             : out sl);
end TimingRx;


architecture mapping of TimingRx is

   constant RX_PHY_INDEX_C     : natural  := 0;
   constant DEBUG_INDEX_C      : natural  := 1;
   constant XPM_MINI_INDEX_C   : natural  := 2;
   constant TEM_INDEX_C        : natural  := 3;
   constant TIMING_INDEX_C     : natural  := 4;
   constant NUM_AXIL_MASTERS_C : positive := 5;

   constant AXIL_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
      RX_PHY_INDEX_C   => (
         baseAddr      => (AXIL_BASE_ADDR_G+x"0000_0000"),
         addrBits      => 16,
         connectivity  => x"FFFF"),
      DEBUG_INDEX_C    => (
         baseAddr      => (AXIL_BASE_ADDR_G+x"0001_0000"),
         addrBits      => 16,
         connectivity  => x"FFFF"),
      XPM_MINI_INDEX_C => (
         baseAddr      => (AXIL_BASE_ADDR_G+X"0003_0000"),
         addrBits      => 16,
         connectivity  => X"FFFF"),
      TEM_INDEX_C      => (
         baseAddr      => (AXIL_BASE_ADDR_G+x"0004_0000"),
         addrBits      => 16,
         connectivity  => x"FFFF"),
      TIMING_INDEX_C   => (
         baseAddr      => (AXIL_BASE_ADDR_G+x"0008_0000"),
         addrBits      => 18,
         connectivity  => x"FFFF"));

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0);

   signal gtRxData : slv(15 downto 0);
   signal rxData   : slv(15 downto 0);

   signal gtRxDataK : slv(1 downto 0);
   signal rxDataK   : slv(1 downto 0);

   signal gtRxDispErr : slv(1 downto 0);
   signal rxDispErr   : slv(1 downto 0);

   signal gtRxDecErr : slv(1 downto 0);
   signal rxDecErr   : slv(1 downto 0);

   signal gtRxStatus : TimingPhyStatusType;
   signal rxStatus   : TimingPhyStatusType;

   signal timingRxControl : TimingPhyControlType;
   signal gtRxControl     : TimingPhyControlType;

   signal gtTxStatus  : TimingPhyStatusType;
   signal gtTxControl : TimingPhyControlType;

   signal tpgMiniStreamTimingPhy : TimingPhyType;
   signal xpmMiniTimingPhy       : TimingPhyType;
   signal appTimingBus           : TimingBusType;
   signal appTimingMode          : sl;

   signal temTimingTxPhy : TimingPhyType;

   signal eventTimingMessagesValid : slv (1 downto 0);
   signal eventTimingMessage       : TimingMessageArray(1 downto 0);
   signal eventTimingMessagesRd    : slv (1 downto 0);

   signal gtLclsClkDiv2 : sl;
   signal gtRefClk      : sl;

   signal gtTxOutClk : sl;
   signal txUsrClk   : sl;
   signal txUsrRst   : sl;
   signal txUsrReset : sl;

   signal gtRxOutClk : sl;
   signal rxUsrClk   : sl;
   signal rxUsrRst   : sl;
   signal rxUsrReset : sl;

   constant NUM_WRITE_REG_C : positive := 1;
   constant NUM_READ_REG_C  : positive := 1;
   constant INI_WRITE_REG_C : Slv32Array(NUM_WRITE_REG_C-1 downto 0) := (
      0 => x"0000_0000");

   signal writeReg : Slv32Array(NUM_WRITE_REG_C-1 downto 0);
   signal readReg  : Slv32Array(NUM_READ_REG_C-1 downto 0) := (others => (others => '0'));

   signal useMiniTpg     : sl;
   signal useMiniTpgSync : sl;
   signal txDbgRst       : sl;
   signal rxDbgRst       : sl;
   signal txDbgPhyRst    : sl;
   signal txDbgPhyPllRst : sl;

begin

   U_gtRefClk : IBUFDS_GTE4
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "01",  -- 2'b01: ODIV2 = Divide-by-2 version of O
         REFCLK_ICNTL_RX    => "00")
      port map (
         I     => gtLclsClkP,
         IB    => gtLclsClkN,
         CEB   => '0',
         ODIV2 => gtLclsClkDiv2,
         O     => gtRefClk);

   U_txUsrClk : BUFG_GT
      port map (
         I       => gtLclsClkDiv2,
         CE      => '1',
         CEMASK  => '1',
         CLR     => '0',
         CLRMASK => '1',
         DIV     => "000",              -- Divide by 1
         O       => txUsrClk);

   U_txUsrRst : entity surf.RstSync
      generic map (
         TPD_G => TPD_G)
      port map (
         clk      => txUsrClk,
         asyncRst => txUsrReset,
         syncRst  => txUsrRst);

   U_rxUsrRst : entity surf.RstSync
      generic map (
         TPD_G => TPD_G)
      port map (
         clk      => rxUsrClk,
         asyncRst => rxUsrReset,
         syncRst  => rxUsrRst);

   U_rxUsrClk : BUFGMUX
      generic map (
         CLK_SEL_TYPE => "ASYNC")       -- ASYNC, SYNC
      port map (
         O  => rxUsrClk,                -- 1-bit output: Clock output
         I0 => gtRxOutClk,              -- 1-bit input: Clock input (S=0)
         I1 => txUsrClk,                -- 1-bit input: Clock input (S=1)
         S  => useMiniTpg);             -- 1-bit input: Clock select

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   U_AxiLiteRegs : entity surf.AxiLiteRegs
      generic map (
         TPD_G           => TPD_G,
         NUM_WRITE_REG_G => NUM_WRITE_REG_C,
         INI_WRITE_REG_G => INI_WRITE_REG_C,
         NUM_READ_REG_G  => NUM_READ_REG_C)
      port map (
         -- AXI-Lite Bus
         axiClk         => axilClk,
         axiClkRst      => axilRst,
         axiReadMaster  => axilReadMasters(DEBUG_INDEX_C),
         axiReadSlave   => axilReadSlaves(DEBUG_INDEX_C),
         axiWriteMaster => axilWriteMasters(DEBUG_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(DEBUG_INDEX_C),
         -- User Read/Write registers
         writeRegister  => writeReg,
         readRegister   => readReg);

   useMiniTpg     <= writeReg(0)(0);
   rxDbgRst       <= writeReg(0)(1) or axilRst;
   txDbgRst       <= writeReg(0)(2) or axilRst;
   txDbgPhyRst    <= writeReg(0)(3) or axilRst;
   txDbgPhyPllRst <= writeReg(0)(4) or axilRst;

   rxUsrReset     <= rxDbgRst or not rxStatus.resetDone;

   v1LinkUp       <= appTimingBus.v1.linkUp;
   v2LinkUp       <= appTimingBus.v2.linkUp;

   U_useMiniTpgSync : entity surf.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => rxUsrClk,
         dataIn  => useMiniTpg,
         dataOut => useMiniTpgSync);

   -------------
   -- GTH Module
   -------------
   GEN_GT : if (not SIMULATION_G) generate
      U_GTH : entity lcls_timing_core.TimingGthCoreWrapper
         generic map (
            TPD_G            => TPD_G,
            EXTREF_G         => false,
            AXIL_BASE_ADDR_G => AXIL_CONFIG_C(RX_PHY_INDEX_C).baseAddr,
            ADDR_BITS_G      => 12,
            GTH_DRP_OFFSET_G => x"00001000")
         port map (
            -- AXI-Lite Port
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMasters(RX_PHY_INDEX_C),
            axilReadSlave   => axilReadSlaves(RX_PHY_INDEX_C),
            axilWriteMaster => axilWriteMasters(RX_PHY_INDEX_C),
            axilWriteSlave  => axilWriteSlaves(RX_PHY_INDEX_C),
            stableClk       => axilClk,
            stableRst       => axilRst,
            -- GTH FPGA IO
            gtRefClk        => gtRefClk,
            gtRefClkDiv2    => txUsrClk,
            gtRxP           => leapRxP,
            gtRxN           => leapRxN,
            gtTxP           => leapTxP,
            gtTxN           => leapTxN,
            -- Rx ports
            rxControl       => gtRxControl,
            rxStatus        => gtRxStatus,
            rxUsrClkActive  => '1',
            rxUsrClk        => rxUsrClk,
            rxData          => gtRxData,
            rxDataK         => gtRxDataK,
            rxDispErr       => gtRxDispErr,
            rxDecErr        => gtRxDecErr,
            rxOutClk        => gtRxOutClk,
            -- Tx Ports
            txControl       => gtTxControl,
            txStatus        => gtTxStatus,
            txUsrClk        => txUsrClk,
            txUsrClkActive  => '1',
            txData          => temTimingTxPhy.data,
            txDataK         => temTimingTxPhy.dataK,
            txOutClk        => gtTxOutClk,
            -- Misc.
            loopback        => "000");
   end generate;

   BYP_GT : if (SIMULATION_G) generate

      axilReadSlaves(RX_PHY_INDEX_C)  <= AXI_LITE_READ_SLAVE_EMPTY_OK_C;
      axilWriteSlaves(RX_PHY_INDEX_C) <= AXI_LITE_WRITE_SLAVE_EMPTY_OK_C;

      gtRxOutClk <= txUsrClk;
      gtTxOutClk <= txUsrClk;

      gtTxStatus  <= TIMING_PHY_STATUS_FORCE_C;
      gtRxStatus  <= TIMING_PHY_STATUS_FORCE_C;
      gtRxData    <= (others => '0');   --temTimingTxPhy.data;
      gtRxDataK   <= (others => '0');   --temTimingTxPhy.dataK;
      gtRxDispErr <= "00";
      gtRxDecErr  <= "00";

   end generate;

   process(rxUsrClk)
   begin
      -- Register to help meet timing
      if rising_edge(rxUsrClk) then
         if (useMiniTpgSync = '1') then
            rxStatus  <= TIMING_PHY_STATUS_FORCE_C after TPD_G;
            rxData    <= xpmMiniTimingPhy.data     after TPD_G;
            rxDataK   <= xpmMiniTimingPhy.dataK    after TPD_G;
            rxDispErr <= "00"                      after TPD_G;
            rxDecErr  <= "00"                      after TPD_G;
         else
            rxStatus  <= gtRxStatus  after TPD_G;
            rxData    <= gtRxData    after TPD_G;
            rxDataK   <= gtRxDataK   after TPD_G;
            rxDispErr <= gtRxDispErr after TPD_G;
            rxDecErr  <= gtRxDecErr  after TPD_G;
         end if;
      end if;
   end process;

   -----------------------
   -- Insert user RX reset
   -----------------------
   gtRxControl.reset       <= timingRxControl.reset or rxDbgRst;
   gtRxControl.inhibit     <= timingRxControl.inhibit;
   gtRxControl.polarity    <= timingRxControl.polarity;
   gtRxControl.bufferByRst <= timingRxControl.bufferByRst;
   gtRxControl.pllReset    <= timingRxControl.pllReset or rxDbgRst;

   gtTxControl.reset       <= temTimingTxPhy.control.reset or txDbgPhyRst;
   gtTxControl.pllReset    <= temTimingTxPhy.control.pllReset or txDbgPhyPllRst;
   gtTxControl.inhibit     <= temTimingTxPhy.control.inhibit;
   gtTxControl.polarity    <= temTimingTxPhy.control.polarity;
   gtTxControl.bufferByRst <= temTimingTxPhy.control.bufferByRst;

   --------------
   -- Timing Core
   --------------
   U_TimingCore : entity lcls_timing_core.TimingCore
      generic map (
         TPD_G             => TPD_G,
         DEFAULT_CLK_SEL_G => '1',      --  '1': default LCLS-II
         TPGEN_G           => false,
         AXIL_RINGB_G      => false,
         ASYNC_G           => true,
         AXIL_BASE_ADDR_G  => AXIL_CONFIG_C(TIMING_INDEX_C).baseAddr)
      port map (
         -- GT Interface
         gtTxUsrClk      => txUsrClk,
         gtTxUsrRst      => txUsrRst,
         gtRxRecClk      => rxUsrClk,
         gtRxData        => rxData,
         gtRxDataK       => rxDataK,
         gtRxDispErr     => rxDispErr,
         gtRxDecErr      => rxDecErr,
         gtRxControl     => timingRxControl,
         gtRxStatus      => rxStatus,
         -- Decoded timing message interface
         appTimingClk    => rxUsrClk,
         appTimingRst    => rxUsrRst,
         appTimingMode   => appTimingMode,
         appTimingBus    => appTimingBus,
         -- AXI Lite interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(TIMING_INDEX_C),
         axilReadSlave   => axilReadSlaves(TIMING_INDEX_C),
         axilWriteMaster => axilWriteMasters(TIMING_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(TIMING_INDEX_C));

   ---------------------
   -- XPM Mini Wrapper
   -- Simulates a timing/xpm stream
   ---------------------
   U_XpmMiniWrapper_1 : entity l2si_core.XpmMiniWrapper
      generic map (
         TPD_G           => TPD_G,
         NUM_DS_LINKS_G  => 1,
         AXIL_BASEADDR_G => AXIL_CONFIG_C(XPM_MINI_INDEX_C).baseAddr)
      port map (
         timingClk => rxUsrClk,          -- [in]
         timingRst => rxUsrRst,          -- [in]
         dsTx(0)   => xpmMiniTimingPhy,  -- [out]

         dsRxClk(0)     => txUsrClk,              -- [in]
         dsRxRst(0)     => txUsrRst,              -- [in]
         dsRx(0).data   => temTimingTxPhy.data,   -- [in]
         dsRx(0).dataK  => temTimingTxPhy.dataK,  -- [in]
         dsRx(0).decErr => (others => '0'),       -- [in]
         dsRx(0).dspErr => (others => '0'),       -- [in]

         tpgMiniStream => tpgMiniStreamTimingPhy,  -- [out]

         axilClk         => axilClk,                             -- [in]
         axilRst         => axilRst,                             -- [in]
         axilReadMaster  => axilReadMasters(XPM_MINI_INDEX_C),   -- [in]
         axilReadSlave   => axilReadSlaves(XPM_MINI_INDEX_C),    -- [out]
         axilWriteMaster => axilWriteMasters(XPM_MINI_INDEX_C),  -- [in]
         axilWriteSlave  => axilWriteSlaves(XPM_MINI_INDEX_C));  -- [out]

   ---------------------------------------------------------------
   -- Decode events and buffer them for the application
   ---------------------------------------------------------------
   U_TriggerEventManager_1 : entity l2si_core.TriggerEventManager
      generic map (
         TPD_G                          => TPD_G,
         EN_LCLS_I_TIMING_G             => false,
         EN_LCLS_II_TIMING_G            => true,
         NUM_DETECTORS_G                => NUM_DETECTORS_G,
         AXIL_BASE_ADDR_G               => AXIL_CONFIG_C(TEM_INDEX_C).baseAddr,
         EVENT_AXIS_CONFIG_G            => EVENT_AXIS_CONFIG_G,
         L1_CLK_IS_TIMING_TX_CLK_G      => false,
         TRIGGER_CLK_IS_TIMING_RX_CLK_G => false,
         EVENT_CLK_IS_TIMING_RX_CLK_G   => false)
      port map (
         timingRxClk                 => rxUsrClk,                     -- [in]
         timingRxRst                 => rxUsrRst,                     -- [in]
         timingBus                   => appTimingBus,                 -- [in]
         timingMode                  => appTimingMode,                -- [in]
         timingTxClk                 => txUsrClk,                     -- [in]
         timingTxRst                 => txUsrRst,                     -- [in]
         timingTxPhy                 => temTimingTxPhy,               -- [out]
         triggerClk                  => triggerClk,                   -- [in]
         triggerRst                  => triggerRst,                   -- [in]
         triggerData                 => triggerData,                  -- [out]
         clearReadout                => clearReadout,                 -- [out]
         l1Clk                       => l1Clk,                        -- [in]
         l1Rst                       => l1Rst,                        -- [in]
         l1Feedbacks                 => l1Feedbacks,                   -- [in]
         l1Acks                      => l1Acks,                        -- [out]
         eventClk                    => eventClk,                     -- [in]
         eventRst                    => eventRst,                     -- [in]
         eventTimingMessagesValid    => eventTimingMessagesValid,     -- [out]
         eventTimingMessages         => eventTimingMessage,           -- [out]
         eventTimingMessagesRd       => eventTimingMessagesRd,        -- [in]
         eventAxisMasters            => eventTrigMsgMasters,           -- [out]
         eventAxisSlaves             => eventTrigMsgSlaves,            -- [in]
         eventAxisCtrl               => eventTrigMsgCtrl,             -- [in]
         axilClk                     => axilClk,                      -- [in]
         axilRst                     => axilRst,                      -- [in]
         axilReadMaster              => axilReadMasters(TEM_INDEX_C),   -- [in]
         axilReadSlave               => axilReadSlaves(TEM_INDEX_C),  -- [out]
         axilWriteMaster             => axilWriteMasters(TEM_INDEX_C),  -- [in]
         axilWriteSlave              => axilWriteSlaves(TEM_INDEX_C));  -- [out]

   U_EventTimingMessage : entity l2si_core.EventTimingMessage
      generic map (
         TPD_G               => TPD_G,
         NUM_DETECTORS_G     => 2,
         EVENT_AXIS_CONFIG_G => EVENT_AXIS_CONFIG_G)
      port map (
         -- Clock and Reset
         eventClk                    => eventClk,                  -- [in]
         eventRst                    => eventRst,                  -- [in]
         -- Input Streams
         eventTimingMessagesValid    => eventTimingMessagesValid,  -- [in]
         eventTimingMessages         => eventTimingMessage,        -- [in]
         eventTimingMessagesRd       => eventTimingMessagesRd,     -- [out]
         -- Output Streams
         eventTimingMsgMasters       => eventTimingMsgMasters,      -- [out]
         eventTimingMsgSlaves        => eventTimingMsgSlaves);      -- [in]

end mapping;
