-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: PGP Wrapper
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
use surf.EthMacPkg.all;
use surf.Pgp4Pkg.all;
use surf.SsiPkg.all;
use surf.SsiCmdMasterPkg.all;

library work;
use work.ePix320kMPkg.all;

entity PgpWrapper is
   generic (
      TPD_G            : time             := 1 ns;
      SIMULATION_G     : boolean          := false;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- Clock and Reset
      axilClk          : in  sl;
      axilRst          : in  sl;
      -- Master AXI-Lite Interface
      mAxilReadMaster  : out AxiLiteReadMasterType;
      mAxilReadSlave   : in  AxiLiteReadSlaveType;
      mAxilWriteMaster : out AxiLiteWriteMasterType;
      mAxilWriteSlave  : in  AxiLiteWriteSlaveType;
      -- Slave AXI-Lite Interfaces
      sAxilReadMaster  : in  AxiLiteReadMasterType;
      sAxilReadSlave   : out AxiLiteReadSlaveType;
      sAxilWriteMaster : in  AxiLiteWriteMasterType;
      sAxilWriteSlave  : out AxiLiteWriteSlaveType;
      -- Streaming Interfaces
      asicDataMasters  : in  AxiStreamMasterArray(3 downto 0);
      asicDataSlaves   : out AxiStreamSlaveArray(3 downto 0);
      remoteDmaPause   : out slv(3 downto 0);
      oscopeMasters    : in  AxiStreamMasterArray(3 downto 0);
      oscopeSlaves     : out AxiStreamSlaveArray(3 downto 0);
      slowAdcMasters   : in  AxiStreamMasterArray(3 downto 0);
      slowAdcSlaves    : out AxiStreamSlaveArray(3 downto 0);
      -- LEAP Transceiver Ports
      gtRefClk         : in  sl;
      leapTxP          : out slv(7 downto 0);
      leapTxN          : out slv(7 downto 0);
      leapRxP          : in  slv(7 downto 0);
      leapRxN          : in  slv(7 downto 0);
      -- ssi commands
      ssiCmd          : out    SsiCmdMasterType);
end PgpWrapper;

architecture mapping of PgpWrapper is

   constant STATUS_CNT_WIDTH_C : positive := 12;
   constant ERROR_CNT_WIDTH_C  : positive := 8;

   constant NUM_AXIL_MASTERS_C : positive := 8;

   constant XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 20, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_SLVERR_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_SLVERR_C);

   signal ibXvcMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal ibXvcSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;
   signal obXvcMaster : AxiStreamMasterType := AXI_STREAM_MASTER_INIT_C;
   signal obXvcSlave  : AxiStreamSlaveType  := AXI_STREAM_SLAVE_FORCE_C;

   signal qpllLock   : Slv2Array(7 downto 0) := (others => "00");
   signal qpllClk    : Slv2Array(7 downto 0) := (others => "00");
   signal qpllRefclk : Slv2Array(7 downto 0) := (others => "00");
   signal qpllRst    : Slv2Array(7 downto 0) := (others => "00");

   signal pgpTxIn  : Pgp4TxInArray(7 downto 0) := (others => PGP4_TX_IN_INIT_C);
   signal pgpTxOut : Pgp4TxOutArray(7 downto 0);

   signal pgpRxIn  : Pgp4RxInArray(7 downto 0) := (others => PGP4_RX_IN_INIT_C);
   signal pgpRxOut : Pgp4RxOutArray(7 downto 0);

   signal pgpClk : slv(7 downto 0);
   signal pgpRst : slv(7 downto 0);

   -- these are unidirectional lanes to transmit data out on a single VC (lanes 0 - 4)
   signal dataTxMasters  : AxiStreamMasterArray(4 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal dataTxSlaves   : AxiStreamSlaveArray(4 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);
   signal removePauseVec : slv(4 downto 0);

   -- These are the buses for lane 5 only. Each index here is a VC
   signal pgpTxMasters : AxiStreamMasterArray(2 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpTxSlaves  : AxiStreamSlaveArray(2 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal pgpRxMasters : AxiStreamMasterArray(2 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal pgpRxCtrl    : AxiStreamCtrlArray(2 downto 0)   := (others => AXI_STREAM_CTRL_UNUSED_C);

   signal slowMonTxMasters : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal slowMonTxSlaves  : AxiStreamSlaveArray(3 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

   signal oscopeTxMasters : AxiStreamMasterArray(3 downto 0) := (others => AXI_STREAM_MASTER_INIT_C);
   signal oscopeTxSlaves  : AxiStreamSlaveArray(3 downto 0)  := (others => AXI_STREAM_SLAVE_FORCE_C);

begin

   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => XBAR_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => sAxilWriteMaster,
         sAxiWriteSlaves(0)  => sAxilWriteSlave,
         sAxiReadMasters(0)  => sAxilReadMaster,
         sAxiReadSlaves(0)   => sAxilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   GEN_QPLL :
   for i in 1 downto 0 generate
      U_QPLL : entity surf.Pgp3GthUsQpll  -- Same IP core for both PGPv3 and PGPv4
         generic map (
            TPD_G    => TPD_G,
            RATE_G   => PGP_RATE_C,
            EN_DRP_G => false)
         port map (
            -- Stable Clock and Reset
            stableClk  => axilClk,
            stableRst  => axilRst,
            -- QPLL Clocking
            pgpRefClk  => gtRefClk,
            qpllLock   => qpllLock(4*i+3 downto 4*i),
            qpllClk    => qpllClk(4*i+3 downto 4*i),
            qpllRefclk => qpllRefclk(4*i+3 downto 4*i),
            qpllRst    => qpllRst(4*i+3 downto 4*i),
            axilClk    => axilClk,
            axilRst    => axilRst);
   end generate GEN_QPLL;

   GEN_PGP_DATA :
   for i in 3 downto 0 generate

      U_Pgp : entity surf.Pgp4GthUs
         generic map (
            TPD_G              => TPD_G,
            RATE_G             => PGP_RATE_C,
            NUM_VC_G           => 1,
            EN_PGP_MON_G       => true,
            WRITE_EN_G         => false,
            EN_DRP_G           => false,
            AXIL_BASE_ADDR_G   => XBAR_CONFIG_C(i).baseAddr,
            STATUS_CNT_WIDTH_G => STATUS_CNT_WIDTH_C,
            ERROR_CNT_WIDTH_G  => ERROR_CNT_WIDTH_C,
            AXIL_CLK_FREQ_G    => AXIL_CLK_FREQ_C)
         port map (
            -- Stable Clock and Reset
            stableClk       => axilClk,
            stableRst       => axilRst,
            -- QPLL Interface
            qpllLock        => qpllLock(i),
            qpllClk         => qpllClk(i),
            qpllRefclk      => qpllRefclk(i),
            qpllRst         => qpllRst(i),
            -- Gt Serial IO
            pgpGtTxP        => leapTxP(i),
            pgpGtTxN        => leapTxN(i),
            pgpGtRxP        => leapRxP(i),
            pgpGtRxN        => leapRxN(i),
            -- Clocking
            pgpClk          => pgpClk(i),
            pgpClkRst       => pgpRst(i),
            -- Non VC Rx Signals
            pgpRxIn         => pgpRxIn(i),
            pgpRxOut        => pgpRxOut(i),
            -- Non VC Tx Signals
            pgpTxIn         => pgpTxIn(i),
            pgpTxOut        => pgpTxOut(i),
            -- Frame Transmit Interface
            pgpTxMasters(0) => dataTxMasters(i),
            pgpTxSlaves(0)  => dataTxSlaves(i),
            -- Frame Receive Interface
            pgpRxMasters    => open,
            pgpRxCtrl(0)    => AXI_STREAM_CTRL_UNUSED_C,
            -- AXI-Lite Register Interface (axilClk domain)
            axilClk         => axilClk,
            axilRst         => axilRst,
            axilReadMaster  => axilReadMasters(i),
            axilReadSlave   => axilReadSlaves(i),
            axilWriteMaster => axilWriteMasters(i),
            axilWriteSlave  => axilWriteSlaves(i));

      U_TX_FIFO : entity surf.PgpTxVcFifo
         generic map (
            TPD_G            => TPD_G,
            APP_AXI_CONFIG_G => APP_AXIS_CONFIG_C,
            PHY_AXI_CONFIG_G => PGP4_AXIS_CONFIG_C)
         port map (
            -- AXIS Interface (axisClk domain)
            axisClk     => axilClk,
            axisRst     => axilRst,
            axisMaster  => asicDataMasters(i),
            axisSlave   => asicDataSlaves(i),
            -- PGP Interface (pgpClk domain)
            pgpClk      => pgpClk(i),
            pgpRst      => pgpRst(i),
            rxlinkReady => pgpRxOut(i).linkReady,
            txlinkReady => pgpTxOut(i).linkReady,
            pgpTxMaster => dataTxMasters(i),
            pgpTxSlave  => dataTxSlaves(i));

      U_remoteDmaPause : entity surf.Synchronizer
         generic map (
            TPD_G => TPD_G)
         port map (
            clk     => axilClk,
            dataIn  => removePauseVec(i),
            dataOut => remoteDmaPause(i));

      -- On the PCIe card, remLinkData[0] is mapped to the large DDR/HBM memory buffer's pause
      removePauseVec(i) <= pgpRxOut(i).remLinkData(0) or not(pgpRxOut(i).linkReady) or not(pgpTxOut(i).linkReady);

   end generate GEN_PGP_DATA;

   U_Pgp_RegAccess : entity surf.Pgp4GthUs
      generic map (
         TPD_G              => TPD_G,
         RATE_G             => PGP_RATE_C,
         NUM_VC_G           => 3,
         EN_PGP_MON_G       => true,
         WRITE_EN_G         => false,
         EN_DRP_G           => false,
         AXIL_BASE_ADDR_G   => XBAR_CONFIG_C(5).baseAddr,
         STATUS_CNT_WIDTH_G => STATUS_CNT_WIDTH_C,
         ERROR_CNT_WIDTH_G  => ERROR_CNT_WIDTH_C,
         AXIL_CLK_FREQ_G    => AXIL_CLK_FREQ_C)
      port map (
         -- Stable Clock and Reset
         stableClk       => axilClk,
         stableRst       => axilRst,
         -- QPLL Interface
         qpllLock        => qpllLock(5),
         qpllClk         => qpllClk(5),
         qpllRefclk      => qpllRefclk(5),
         qpllRst         => qpllRst(5),
         -- Gt Serial IO
         pgpGtTxP        => leapTxP(5),
         pgpGtTxN        => leapTxN(5),
         pgpGtRxP        => leapRxP(5),
         pgpGtRxN        => leapRxN(5),
         -- Clocking
         pgpClk          => pgpClk(5),
         pgpClkRst       => pgpRst(5),
         -- Non VC Rx Signals
         pgpRxIn         => pgpRxIn(5),
         pgpRxOut        => pgpRxOut(5),
         -- Non VC Tx Signals
         pgpTxIn         => pgpTxIn(5),
         pgpTxOut        => pgpTxOut(5),
         -- Frame Transmit Interface
         pgpTxMasters    => pgpTxMasters,
         pgpTxSlaves     => pgpTxSlaves,
         -- Frame Receive Interface
         pgpRxMasters    => pgpRxMasters,
         pgpRxCtrl       => pgpRxCtrl,
         -- AXI-Lite Register Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(5),
         axilReadSlave   => axilReadSlaves(5),
         axilWriteMaster => axilWriteMasters(5),
         axilWriteSlave  => axilWriteSlaves(5));

   U_VC0 : entity surf.SrpV3AxiLite
      generic map (
         TPD_G               => TPD_G,
         GEN_SYNC_FIFO_G     => false,
         AXI_STREAM_CONFIG_G => PGP4_AXIS_CONFIG_C)
      port map (
         -- Streaming Slave (Rx) Interface (sAxisClk domain)
         sAxisClk         => pgpClk(5),
         sAxisRst         => pgpRst(5),
         sAxisMaster      => pgpRxMasters(0),
         sAxisCtrl        => pgpRxCtrl(0),
         -- Streaming Master (Tx) Data Interface (mAxisClk domain)
         mAxisClk         => pgpClk(5),
         mAxisRst         => pgpRst(5),
         mAxisMaster      => pgpTxMasters(0),
         mAxisSlave       => pgpTxSlaves(0),
         -- Master AXI-Lite Interface (axilClk domain)
         axilClk          => axilClk,
         axilRst          => axilRst,
         mAxilReadMaster  => mAxilReadMaster,
         mAxilReadSlave   => mAxilReadSlave,
         mAxilWriteMaster => mAxilWriteMaster,
         mAxilWriteSlave  => mAxilWriteSlave);

   U_SsiCmdMaster : entity surf.SsiCmdMaster
      generic map (
         TPD_G               => TPD_G,
         AXI_STREAM_CONFIG_G => PGP4_AXIS_CONFIG_C,
         SLAVE_READY_EN_G    => SIMULATION_G)
      port map (
         -- Streaming Data Interface - WHICH LANE? 0?
         axisClk     => pgpClk(5),
         axisRst     => pgpRst(5),
         sAxisMaster => pgpRxMasters(1),
         sAxisSlave  => open,
         sAxisCtrl   => pgpRxCtrl(1),
         -- Command signals
         cmdClk      => axilClk,
         cmdRst      => axilRst,
         cmdMaster   => ssiCmd);
                  
   U_VC2_RX : entity surf.PgpRxVcFifo
      generic map (
         TPD_G            => TPD_G,
         GEN_SYNC_FIFO_G  => true,      -- same clock domain
         PHY_AXI_CONFIG_G => PGP4_AXIS_CONFIG_C,
         APP_AXI_CONFIG_G => EMAC_AXIS_CONFIG_C)
      port map (
         -- PGP Interface (pgpClk domain)
         pgpClk      => pgpClk(5),
         pgpRst      => pgpRst(5),
         rxlinkReady => pgpRxOut(5).linkReady,
         pgpRxMaster => pgpRxMasters(2),
         pgpRxCtrl   => pgpRxCtrl(2),
         -- AXIS Interface (axisClk domain)
         axisClk     => pgpClk(5),
         axisRst     => pgpRst(5),
         axisMaster  => ibXvcMaster,
         axisSlave   => ibXvcSlave);

   -----------------------------------------------------------------
   -- Xilinx Virtual Cable (XVC)
   -- https://www.xilinx.com/products/intellectual-property/xvc.html
   -----------------------------------------------------------------
   U_XVC : entity surf.UdpDebugBridgeWrapper
      generic map (
         TPD_G => TPD_G)
      port map (
         -- Clock and Reset
         clk            => pgpClk(5),
         rst            => pgpRst(5),
         -- UDP XVC Interface
         obServerMaster => ibXvcMaster,
         obServerSlave  => ibXvcSlave,
         ibServerMaster => obXvcMaster,
         ibServerSlave  => obXvcSlave);

   U_VC1_TX : entity surf.PgpTxVcFifo
      generic map (
         TPD_G            => TPD_G,
         GEN_SYNC_FIFO_G  => true,      -- same clock domain
         APP_AXI_CONFIG_G => EMAC_AXIS_CONFIG_C,
         PHY_AXI_CONFIG_G => PGP4_AXIS_CONFIG_C)
      port map (
         -- AXIS Interface (axisClk domain)
         axisClk     => pgpClk(5),
         axisRst     => pgpRst(5),
         axisMaster  => obXvcMaster,
         axisSlave   => obXvcSlave,
         -- PGP Interface (pgpClk domain)
         pgpClk      => pgpClk(5),
         pgpRst      => pgpRst(5),
         rxlinkReady => pgpRxOut(5).linkReady,
         txlinkReady => pgpTxOut(5).linkReady,
         pgpTxMaster => pgpTxMasters(2),
         pgpTxSlave  => pgpTxSlaves(2));

   U_Pgp_Lane6 : entity surf.Pgp4GthUs
      generic map (
         TPD_G              => TPD_G,
         RATE_G             => PGP_RATE_C,
         NUM_VC_G           => 4,
         EN_PGP_MON_G       => true,
         WRITE_EN_G         => false,
         EN_DRP_G           => false,
         AXIL_BASE_ADDR_G   => XBAR_CONFIG_C(6).baseAddr,
         STATUS_CNT_WIDTH_G => STATUS_CNT_WIDTH_C,
         ERROR_CNT_WIDTH_G  => ERROR_CNT_WIDTH_C,
         AXIL_CLK_FREQ_G    => AXIL_CLK_FREQ_C)
      port map (
         -- Stable Clock and Reset
         stableClk       => axilClk,
         stableRst       => axilRst,
         -- QPLL Interface
         qpllLock        => qpllLock(6),
         qpllClk         => qpllClk(6),
         qpllRefclk      => qpllRefclk(6),
         qpllRst         => qpllRst(6),
         -- Gt Serial IO
         pgpGtTxP        => leapTxP(6),
         pgpGtTxN        => leapTxN(6),
         pgpGtRxP        => leapRxP(6),
         pgpGtRxN        => leapRxN(6),
         -- Clocking
         pgpClk          => pgpClk(6),
         pgpClkRst       => pgpRst(6),
         -- Non VC Rx Signals
         pgpRxIn         => pgpRxIn(6),
         pgpRxOut        => pgpRxOut(6),
         -- Non VC Tx Signals
         pgpTxIn         => pgpTxIn(6),
         pgpTxOut        => pgpTxOut(6),
         -- Frame Transmit Interface
         pgpTxMasters    => slowMonTxMasters,
         pgpTxSlaves     => slowMonTxSlaves,
         -- Frame Receive Interface
         pgpRxMasters    => open,
         pgpRxCtrl       => (others => AXI_STREAM_CTRL_UNUSED_C),
         -- AXI-Lite Register Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(6),
         axilReadSlave   => axilReadSlaves(6),
         axilWriteMaster => axilWriteMasters(6),
         axilWriteSlave  => axilWriteSlaves(6));

   GEN_PGP_LANE6 :
   for i in 3 downto 0 generate
      U_TX_FIFO : entity surf.PgpTxVcFifo
         generic map (
            TPD_G            => TPD_G,
            APP_AXI_CONFIG_G => ssiAxiStreamConfig(4),
            PHY_AXI_CONFIG_G => PGP4_AXIS_CONFIG_C)
         port map (
            -- AXIS Interface (axisClk domain)
            axisClk     => axilClk,
            axisRst     => axilRst,
            axisMaster  => slowAdcMasters(i),
            axisSlave   => slowAdcSlaves(i),
            -- PGP Interface (pgpClk domain)
            pgpClk      => pgpClk(6),
            pgpRst      => pgpRst(6),
            rxlinkReady => pgpRxOut(6).linkReady,
            txlinkReady => pgpTxOut(6).linkReady,
            pgpTxMaster => slowMonTxMasters(i),
            pgpTxSlave  => slowMonTxSlaves(i));
   end generate GEN_PGP_LANE6;

   U_Pgp_Lane7 : entity surf.Pgp4GthUs
      generic map (
         TPD_G              => TPD_G,
         RATE_G             => PGP_RATE_C,
         NUM_VC_G           => 4,
         EN_PGP_MON_G       => true,
         WRITE_EN_G         => false,
         EN_DRP_G           => false,
         AXIL_BASE_ADDR_G   => XBAR_CONFIG_C(7).baseAddr,
         STATUS_CNT_WIDTH_G => STATUS_CNT_WIDTH_C,
         ERROR_CNT_WIDTH_G  => ERROR_CNT_WIDTH_C,
         AXIL_CLK_FREQ_G    => AXIL_CLK_FREQ_C)
      port map (
         -- Stable Clock and Reset
         stableClk       => axilClk,
         stableRst       => axilRst,
         -- QPLL Interface
         qpllLock        => qpllLock(7),
         qpllClk         => qpllClk(7),
         qpllRefclk      => qpllRefclk(7),
         qpllRst         => qpllRst(7),
         -- Gt Serial IO
         pgpGtTxP        => leapTxP(7),
         pgpGtTxN        => leapTxN(7),
         pgpGtRxP        => leapRxP(7),
         pgpGtRxN        => leapRxN(7),
         -- Clocking
         pgpClk          => pgpClk(7),
         pgpClkRst       => pgpRst(7),
         -- Non VC Rx Signals
         pgpRxIn         => pgpRxIn(7),
         pgpRxOut        => pgpRxOut(7),
         -- Non VC Tx Signals
         pgpTxIn         => pgpTxIn(7),
         pgpTxOut        => pgpTxOut(7),
         -- Frame Transmit Interface
         pgpTxMasters    => oscopeTxMasters,
         pgpTxSlaves     => oscopeTxSlaves,
         -- Frame Receive Interface
         pgpRxMasters    => open,
         pgpRxCtrl       => (others => AXI_STREAM_CTRL_UNUSED_C),
         -- AXI-Lite Register Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(7),
         axilReadSlave   => axilReadSlaves(7),
         axilWriteMaster => axilWriteMasters(7),
         axilWriteSlave  => axilWriteSlaves(7));

   GEN_PGP_LANE7 :
   for i in 3 downto 0 generate
      U_TX_FIFO : entity surf.PgpTxVcFifo
         generic map (
            TPD_G            => TPD_G,
            APP_AXI_CONFIG_G => ssiAxiStreamConfig(4, TKEEP_COMP_C),
            PHY_AXI_CONFIG_G => PGP4_AXIS_CONFIG_C)
         port map (
            -- AXIS Interface (axisClk domain)
            axisClk     => axilClk,
            axisRst     => axilRst,
            axisMaster  => oscopeMasters(i),
            axisSlave   => oscopeSlaves(i),
            -- PGP Interface (pgpClk domain)
            pgpClk      => pgpClk(7),
            pgpRst      => pgpRst(7),
            rxlinkReady => pgpRxOut(7).linkReady,
            txlinkReady => pgpTxOut(7).linkReady,
            pgpTxMaster => oscopeTxMasters(i),
            pgpTxSlave  => oscopeTxSlaves(i));
   end generate GEN_PGP_LANE7;

end mapping;
