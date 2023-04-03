-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: top level for ePixHRM320k
-------------------------------------------------------------------------------
-- This file is part of 'ePixHRM320k firmware'.
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

use work.CorePkg.all;

entity ePixHRM320k is
   generic (
      BUILD_INFO_G         : BuildInfoType;
      TPD_G                : time            := 1 ns;
      SIMULATION_G         : boolean         := false;
      NUM_OF_ASICS_G       : integer         := 4;
      NUM_OF_SLOW_ADCS_G   : integer         := 2;
      NUM_OF_PSCOPE_G      : integer         := 4
   );
   port (
      ----------------------------------------------
      --      Top level ports shared
      ----------------------------------------------

      -- Transceiver high speed lanes
      fpgaOutObTransInP    : out slv(11 downto 0);
      fpgaOutObTransInM    : out slv(11 downto 0);
      fpgaInObTransOutP    : in  slv(11 downto 0);
      fpgaInObTransOutM    : in  slv(11 downto 0);

      -- Transceiver low speed control
      obTransScl           : inout sl;
      obTransSda           : inout sl;
      obTransResetL        : out   sl;
      obTransIntL          : in    sl;

      -- GT Clock Ports
      gtPllClkP            : in sl;
      gtPllClkM            : in sl;
      gtRefClkP            : in slv(1 downto 0);
      gtRefClkM            : in slv(1 downto 0);
      gtLclsClkP           : in sl;
      gtLclsClkM           : in sl;

      ----------------------------------------------
      --              Application Ports           --
      ----------------------------------------------
      -- ASIC Data Outs
      asicDataP            : in Slv24Array(NUM_OF_ASICS_G - 1 downto 0);
      asicDataM            : in Slv24Array(NUM_OF_ASICS_G - 1 downto 0);


      adcMonDoutP          : in Slv8Array(1 downto 0);
      adcMonDoutM          : in Slv8Array(1 downto 0);
      adcMonDataClkP       : in slv(1 downto 0);
      adcMonDataClkM       : in slv(1 downto 0);
      adcMonFrameClkP      : in slv(1 downto 0);
      adcMonFrameClkM      : in slv(1 downto 0);

      -- ASIC Control Ports
      asicR0               : out sl;
      asicGlblRst          : out sl;
      asicSync             : out sl;
      asicAcq              : out sl;
      -- asicRoClkP           : out slv(NUM_OF_ASICS_G - 1 downto 0);
      -- asicRoClkN           : out slv(NUM_OF_ASICS_G - 1 downto 0);
      asicSro              : out sl;
      asicClkEn            : out sl;
      rdClkSel             : out sl;
      fpgaRdClkP           : out sl;
      fpgaRdClkM           : out sl;

      -- SACI Ports
      saciCmd          : out sl;
      saciClk          : out sl;
      saciSel          : out slv(NUM_OF_ASICS_G - 1 downto 0);
      saciRsp          : in  sl;

      -- Spare ports both to carrier and to p&cb
      pcbSpare             : inout slv(5 downto 0);
      spareM               : inout slv(1 downto 0);
      spareP               : inout slv(1 downto 0);

      -- Bias Dac
      biasDacDin           : out sl;
      biasDacSclk          : out sl;
      biasDacCsb           : out sl;
      biasDacClrb          : out sl;

      -- High speed dac
      hsDacSclk            : out sl;
      hsDacDin             : out sl;
      hsCsb                : out sl;
      hsLdacb              : out sl;

      -- Digital Monitor
      digMon               : in slv(1 downto 0);

      -- External trigger Connector
      runToFpga            : in  sl;
      daqToFpga            : in  sl;
      ttlToFpga            : in  sl;
      fpgaTtlOut           : out sl;
      fpgaMps              : out sl;
      fpgaTg               : out sl;

      -- Fpga Clock IO
      fpgaClkInP           : in  sl;
      fpgaClkInM           : in  sl;
      fpgaClkOutP          : out sl;
      fpgaClkOutM          : out sl;

      -- Serial number
      serialNumber         : inout slv(2 downto 0);

      -- Power 
      syncDcdc             : out slv(6 downto 0);
      pwrAnaEn             : out slv(1 downto 0);
      pcbSync              : out sl;
      pwrGood              : in  slv(1 downto 0);

      -- Digital board env monitor
      adcMonSpiClk         : out sl;
      adcMonSpiData        : inout  sl;
      adcMonClkP           : out sl;
      adcMonClkM           : out sl;
      adcMonPdwn           : out sl;
      adcMonSpiCsL         : out sl;
      slowAdcDout          : in  slv(NUM_OF_SLOW_ADCS_G - 1 downto 0);
      slowAdcDrdyL         : in  slv(NUM_OF_SLOW_ADCS_G - 1 downto 0);
      slowAdcSyncL         : out slv(NUM_OF_SLOW_ADCS_G - 1 downto 0);
      slowAdcSclk          : out slv(NUM_OF_SLOW_ADCS_G - 1 downto 0);
      slowAdcCsL           : out slv(NUM_OF_SLOW_ADCS_G - 1 downto 0);
      slowAdcDin           : out slv(NUM_OF_SLOW_ADCS_G - 1 downto 0);
      slowAdcRefClk        : out slv(NUM_OF_SLOW_ADCS_G - 1 downto 0);

      ----------------------------------------------
      --               Core Ports                 --
      ----------------------------------------------
      -- Clock Jitter Cleaner
      jitclnrCsL           : out sl;
      jitclnrIntr          : in  sl;
      jitclnrLolL          : in  sl;
      jitclnrOeL           : out sl;
      jitclnrRstL          : out sl;
      jitclnrSclk          : out sl;
      jitclnrSdio          : out sl;
      jitclnrSdo           : in  sl;
      jitclnrSel           : out slv(1 downto 0);

      -- LMK61E2
      pllClkScl            : inout sl;
      pllClkSda            : inout sl;

      -- XADC Ports
      vPIn                 : in sl;
      vNIn                 : in sl
   );
end entity;


architecture topLevel of ePixHRM320k is

   -- Clock and Reset
   signal axiClk : sl;
   signal axiRst : sl;

   -- AXI-Stream: Stream Interface
   signal asicDataMasters : AxiStreamMasterArray(NUM_OF_ASICS_G - 1 downto 0);
   signal asicDataSlaves  : AxiStreamSlaveArray(NUM_OF_ASICS_G - 1 downto 0);
   signal remoteDmaPause  : slv(NUM_OF_ASICS_G - 1 downto 0);
   signal oscopeMasters   : AxiStreamMasterArray(NUM_OF_PSCOPE_G - 1 downto 0);
   signal oscopeSlaves    : AxiStreamSlaveArray(NUM_OF_PSCOPE_G - 1 downto 0);
   signal slowAdcMasters  : AxiStreamMasterArray(NUM_OF_SLOW_ADCS_G - 1 downto 0);
   signal slowAdcSlaves   : AxiStreamSlaveArray(NUM_OF_SLOW_ADCS_G - 1 downto 0);

   -- AXI-Lite: Register Access
   signal axilReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

   signal ssiCmd          : SsiCmdMasterType := SSI_CMD_MASTER_INIT_C;

begin

   U_App : entity work.Application
      generic map (
         TPD_G            => TPD_G,
         BUILD_INFO_G     => BUILD_INFO_G,
         SIMULATION_G     => SIMULATION_G,
         NUM_OF_PSCOPE_G   => NUM_OF_PSCOPE_G,
         NUM_OF_SLOW_ADCS_G   => NUM_OF_SLOW_ADCS_G
      )
      port map (
         -- AXI-Lite Register Interface (sysClk domain)
         -- Register Address Range = [0x80000000:0xFFFFFFFF]
         axiClk          => axiClk,
         axiRst          => axiRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,

         -- Streaming Interfaces (axilClk domain)
         asicDataMasters => asicDataMasters,
         asicDataSlaves  => asicDataSlaves,
         remoteDmaPause  => remoteDmaPause,
         oscopeMasters   => oscopeMasters,
         oscopeSlaves    => oscopeSlaves,
         slowAdcMasters  => slowAdcMasters,
         slowAdcSlaves   => slowAdcSlaves,

         -- ASIC Data Ports
         asicDataP => asicDataP,
         asicDataM => asicDataM,

         -- ASIC Control Ports
         asicR0      => asicR0,
         asicGlblRst => asicGlblRst,
         asicSync    => asicSync,
         asicAcq     => asicAcq,
         asicSro     => asicSro,
         asicClkEn   => asicClkEn,
         fpgaRdClkP  => fpgaRdClkP,
         fpgaRdClkM  => fpgaRdClkM,
         rdClkSel    => rdClkSel,

         -- Bias Dac
         biasDacDin  => biasDacDin,
         biasDacSclk => biasDacSclk,
         biasDacCsb  => biasDacCsb,
         biasDacClrb => biasDacClrb,

         -- High speed dac
         hsDacSclk => hsDacSclk,
         hsDacDin  => hsDacDin,
         hsCsb     => hsCsb,
         hsLdacb   => hsLdacb,

         -- Digital Monitor
         digMon => digMon,

         -- SACI Ports
         saciCmd => saciCmd,
         saciClk => saciClk,
         saciSel => saciSel,
         saciRsp => saciRsp,

         -- GT Clock Ports
         gtPllClkP => gtPllClkP,
         gtPllClkM => gtPllClkM,
         gtRefClkP => gtRefClkP(1),
         gtRefClkM => gtRefClkM(1),

         fpgaClkInP => fpgaClkInP,
         fpgaClkInM => fpgaClkInM,

         gtLclsClkP => gtLclsClkP,
         gtLclsClkM => gtLclsClkM,

         -- syncDcdc => syncDcdc,
         pwrAnaEn => pwrAnaEn,
         syncDcdc => syncDcdc,
         pcbSync  => pcbSync ,
         pwrGood  => pwrGood ,

         -- Serial number
         serialNumber => serialNumber,

         -- External trigger Connector
         runToFpga  => runToFpga,
         daqToFpga  => daqToFpga,
         ttlToFpga  => ttlToFpga,
         fpgaTtlOut => fpgaTtlOut,
         fpgaMps    => fpgaMps,
         fpgaTg     => fpgaTg,

         -- Digital board env monitor
         adcMonSpiClk     => adcMonSpiClk,
         adcMonSpiData    => adcMonSpiData,
         adcMonClkP    => adcMonClkP,
         adcMonClkM    => adcMonClkM,
         adcMonPdwn    => adcMonPdwn,
         adcMonSpiCsL  => adcMonSpiCsL,
         slowAdcDout   => slowAdcDout,
         slowAdcDrdyL  => slowAdcDrdyL,
         slowAdcSyncL  => slowAdcSyncL,
         slowAdcSclk   => slowAdcSclk,
         slowAdcCsL    => slowAdcCsL,
         slowAdcDin    => slowAdcDin,
         slowAdcRefClk => slowAdcRefClk,

         -- Fast ADC Ports
         adcMonDoutP  => adcMonDoutP,
         adcMonDoutM  => adcMonDoutM,
         adcMonDataClkP    => adcMonDataClkP,
         adcMonDataClkM    => adcMonDataClkM,
         adcMonFrameClkP => adcMonFrameClkP,
         adcMonFrameClkM => adcMonFrameClkM,

         -- Transceiver high speed lanes
         fpgaOutObTransInP => fpgaOutObTransInP(11 downto 8),
         fpgaOutObTransInM => fpgaOutObTransInM(11 downto 8),
         fpgaInObTransOutP => fpgaInObTransOutP(11 downto 8),
         fpgaInObTransOutM => fpgaInObTransOutM(11 downto 8),

         -- ssi commands
         ssiCmd            => ssiCmd,

         jitclnrLolL       => jitclnrLolL
      );

   U_Core : entity work.Core
      generic map(
         TPD_G          => TPD_G,
         BUILD_INFO_G   => BUILD_INFO_G,
         SIMULATION_G   => SIMULATION_G,
         NUM_OF_ASICS_G => NUM_OF_ASICS_G,
         NUM_OF_PSCOPE_G => NUM_OF_PSCOPE_G,
         NUM_OF_SLOW_ADCS_G   => NUM_OF_SLOW_ADCS_G
      )
      port map (
         -- AXI-Lite Register Interface (sysClk domain)
         -- Register Address Range = [0x00000000:0x80000000]
         axilClk         => axiClk,
         axilRst         => axiRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave,

         -- Streaming Interfaces (axilClk domain)
         asicDataMasters => asicDataMasters,
         asicDataSlaves  => asicDataSlaves,
         remoteDmaPause  => remoteDmaPause,
         oscopeMasters   => oscopeMasters,
         oscopeSlaves    => oscopeSlaves,
         slowAdcMasters  => slowAdcMasters,
         slowAdcSlaves   => slowAdcSlaves,

         -- Transceiver high speed lanes
         fpgaOutObTransInP => fpgaOutObTransInP(7 downto 0),
         fpgaOutObTransInM => fpgaOutObTransInM(7 downto 0),
         fpgaInObTransOutP => fpgaInObTransOutP(7 downto 0),
         fpgaInObTransOutM => fpgaInObTransOutM(7 downto 0),

         -- Transceiver low speed control
         obTransScl    => obTransScl,
         obTransSda    => obTransSda,
         obTransResetL => obTransResetL,
         obTransIntL   => obTransIntL,

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

         -- LMK61E2
         pllClkScl => pllClkScl,
         pllClkSda => pllClkSda,

         -- GT Clock Ports
         gtPllClkP => '0',
         gtPllClkM => '0',
         gtRefClkP => gtRefClkP(0),
         gtRefClkM => gtRefClkM(0),

         -- XADC Ports
         vPIn        => vPIn,
         vNIn        => vNIn,

         -- ssi commands
         ssiCmd            => ssiCmd
      );

end topLevel;
