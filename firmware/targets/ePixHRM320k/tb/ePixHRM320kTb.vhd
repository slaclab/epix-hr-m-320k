-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: test bench for ePixHRM320k
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

library ruckus;
use ruckus.BuildInfoPkg.all;

entity ePixHRM320kTb is
end entity ePixHRM320kTb;

architecture testbench of ePixHRM320kTb is

    constant NUM_OF_SLOW_ADCS_C: natural := 2;
    
    
    -- Transceiver high speed lanes
    signal fpgaOutObTransInP        : slv(11 downto 0)       := ( others => '0');
    signal fpgaOutObTransInM        : slv(11 downto 0)       := ( others => '1');
    signal fpgaInObTransOutP        : slv(11 downto 0)       := ( others => '0');
    signal fpgaInObTransOutM        : slv(11 downto 0)       := ( others => '1');
    -- Transceiver low speed control
    signal obTransScl               : sl                     := '1';
    signal obTransSda               : sl                     := '1';
    signal obTransResetL            : sl                     := '1';
    signal obTransIntL              : sl                     := '1';
    -- GT Clock Ports                    
    signal gtPllClkP                : slv(1 downto 0)        := (others => '0');
    signal gtPllClkM                : slv(1 downto 0)        := (others => '1');
    signal gtRefClkP                : slv(1 downto 0)        := ( others => '0');
    signal gtRefClkM                : slv(1 downto 0)        := ( others => '1');
    signal gtLclsIITimingClkP       : sl                     := '0';
    signal gtLclsIITimingClkM       : sl                     := '1';
    -- ASIC Data Outs
    signal asicDataP                : Slv24Array(3 downto 0) := ( others => ( others => '0'));
    signal asicDataM                : Slv24Array(3 downto 0) := ( others => ( others => '1'));
    -- ASIC Control Ports
    signal adcMonDoutP              : Slv8Array(1 downto 0)  := ( others => ( others => '0'));
    signal adcMonDoutM              : Slv8Array(1 downto 0)  := ( others => ( others => '0'));
    signal adcMonDataClkP                : slv(1 downto 0)   := ( others => '0');
    signal adcMonDataClkM                : slv(1 downto 0)   := ( others => '1');
    signal adcMonFrameClkP             : slv(1 downto 0)     := ( others => '0');
    signal adcMonFrameClkM             : slv(1 downto 0)     := ( others => '1');
    -- ASIC Control Ports        
    signal asicR0                   : sl                     := '1';
    signal asicGlblRst              : sl                     := '1';
    signal asicSync                 : sl                     := '1';
    signal asicAcq                  : sl                     := '1';
    signal asicRoClkP               : slv(3 downto 0)        := ( others => '0');
    signal asicRoClkN               : slv(3 downto 0)        := ( others => '0');
    signal asicSro                  : sl                     := '1';
    signal asicClkEn                : sl                     := '1';
    -- SACI Ports
    signal asicSaciCmd              : sl                     := '1';
    signal asicSaciClk              : sl                     := '1';
    signal asicSaciSel              : slv(3 downto 0)        := ( others => '1');
    signal asicSaciRsp              : sl                     := '1';
    -- Spare ports both to carrier and to p&cb
    signal pcbSpare                 : slv(5 downto 0)        := ( others => '0');
    signal spareM                   : slv(1 downto 0)        := ( others => '0');
    signal spareP                   : slv(1 downto 0)        := ( others => '0');
    -- Bias Dac
    signal biasDacDin               : sl                     := '1';
    signal biasDacSclk              : sl                     := '1';
    signal biasDacCsb               : sl                     := '1';
    signal biasDacClrb              : sl                     := '1';
    -- High speed dac                    
    signal hsDacSclk                : sl                     := '1';
    signal hsDacDin                 : sl                     := '1';
    signal hsCsb                    : sl                     := '1';
    signal hsLdacb                  : sl                     := '1';
    -- Digital Monitor
    signal digMon                   : slv(1 downto 0)        := ( others => '1');
    -- External trigger Connector
    signal runToFpga                : sl                     := '1';
    signal daqToFpga                : sl                     := '1';
    signal ttlToFpga                : sl                     := '1';
    signal fpgaTtlOut               : sl                     := '1';
    signal fpgaMps                  : sl                     := '1';
    signal fpgaTg                   : sl                     := '1';
    -- Fpga Clock IO                     
    signal fpgaClkInP               : sl                     := '1';
    signal fpgaClkInM               : sl                     := '1';
    signal fpgaClkOutP              : sl                     := '1';
    signal fpgaClkOutM              : sl                     := '1';
    -- Power and communication env Monitor
    signal pcbAdcDrdyL              : sl                     := '1';
    signal pcbAdcData               : sl                     := '1';
    signal pcbAdcCsb                : sl                     := '1';
    signal pcbAdcSclk               : sl                     := '1';
    signal pcbAdcDin                : sl                     := '1';
    signal pcbAdcSyncL              : sl                     := '1';
    signal pcbAdcRefClk             : sl                     := '1';
    -- Serial number
    signal serialNumber             : slv(2 downto 0)        := ( others => '1');
    -- Power 
    signal syncDcdc                 : slv(6 downto 0)        := ( others => '1');
    signal ldoShtdnL                : slv(1 downto 0)        := ( others => '1');
    signal dcdcSync                 : sl                     := '1';
    signal pcbSync                  : sl                     := '1';
    signal pwrGood                  : slv(1 downto 0)        := ( others => '0');
    -- Digital board env monitor                     
    signal adcMonSpiClk                : sl                     := '1';
    signal adcMonSpiData               : sl                     := '1';
    signal adcMonClkP               : sl                     := '1';
    signal adcMonClkM               : sl                     := '1';
    signal adcMonPdwn               : sl                     := '1';
    signal adcMonSpiCsb             : sl                     := '1';
    signal slowAdcDout              : slv(NUM_OF_SLOW_ADCS_C - 1 downto 0);
    signal slowAdcDrdyL             : slv(NUM_OF_SLOW_ADCS_C - 1 downto 0);
    signal slowAdcSyncL             : slv(NUM_OF_SLOW_ADCS_C - 1 downto 0);
    signal slowAdcSclk              : slv(NUM_OF_SLOW_ADCS_C - 1 downto 0);
    signal slowAdcCsL               : slv(NUM_OF_SLOW_ADCS_C - 1 downto 0);
    signal slowAdcDin               : slv(NUM_OF_SLOW_ADCS_C - 1 downto 0);
    signal slowAdcRefClk            : slv(NUM_OF_SLOW_ADCS_C - 1 downto 0);
    -- Clock Jitter Cleaner
    signal jitclnrCsL               : sl                     := '1';
    signal jitclnrIntr              : sl                     := '1';
    signal jitclnrLolL              : sl                     := '1';
    signal jitclnrOeL               : sl                     := '1';
    signal jitclnrRstL              : sl                     := '1';
    signal jitclnrSclk              : sl                     := '1';
    signal jitclnrSdio              : sl                     := '1';
    signal jitclnrSdo               : sl                     := '1';
    signal jitclnrSel               : slv(1 downto 0)        := ( others => '1');
    -- LMK61E2
    signal pllClkScl                : sl                     := '1';
    signal pllClkSda                : sl                     := '1';
    -- XADC Ports
    signal vPIn                     : sl                     := '0';
    signal vNIn                     : sl                     := '1';

    signal Clk156P : sl := '0';
    signal Clk156M : sl := '1';
 
    signal Clk250P : sl := '0';
    signal Clk250M : sl := '1';

    constant GET_BUILD_INFO_C : BuildInfoRetType := toBuildInfo(BUILD_INFO_C);
    constant MOD_BUILD_INFO_C : BuildInfoRetType := (
       buildString => GET_BUILD_INFO_C.buildString,
       fwVersion   => GET_BUILD_INFO_C.fwVersion,
       gitHash     => x"1111_2222_3333_4444_5555_6666_7777_8888_9999_AAAA");  -- Force githash for simulation testing
    constant SIM_BUILD_INFO_C : slv(2239 downto 0) := toSlv(MOD_BUILD_INFO_C);

begin

    U_Fpga : entity work.ePixHRM320k
    generic map (
        BUILD_INFO_G => SIM_BUILD_INFO_C,
        SIMULATION_G => true,
        NUM_OF_SLOW_ADCS_G => NUM_OF_SLOW_ADCS_C
    )
    port map (
        ----------------------------------------------
        --      Top level ports shared
        ----------------------------------------------
    
        -- Transceiver high speed lanes
        fpgaOutObTransInP   => fpgaOutObTransInP, 
        fpgaOutObTransInM   => fpgaOutObTransInM, 
        fpgaInObTransOutP   => fpgaInObTransOutP, 
        fpgaInObTransOutM   => fpgaInObTransOutM, 
    
        -- Transceiver low speed control
        obTransScl          => obTransScl   , 
        obTransSda          => obTransSda   , 
        obTransResetL       => obTransResetL, 
        obTransIntL         => obTransIntL  , 
    
        -- GT Clock Ports
        gtPllClkP          => gtPllClkP , 
        gtPllClkM          => gtPllClkM , 
        gtRefClkP          => gtRefClkP , 
        gtRefClkM          => gtRefClkM , 
        gtLclsIITimingClkP => gtLclsIITimingClkP, 
        gtLclsIITimingClkM => gtLclsIITimingClkM, 
        altTimingClkP      => '0',
        altTimingClkM      => '1',
    
        ----------------------------------------------
        --              Application Ports           --
        ----------------------------------------------
        -- ASIC Data Outs
        asicDataP           => asicDataP, 
        asicDataM           => asicDataM, 
    
        adcMonDoutP         => adcMonDoutP , 
        adcMonDoutM         => adcMonDoutM , 
        adcMonDataClkP      => adcMonDataClkP, 
        adcMonDataClkM      => adcMonDataClkM, 
        adcMonFrameClkP     => adcMonFrameClkP, 
        adcMonFrameClkM     => adcMonFrameClkM, 
    
        -- ASIC Control Ports
        asicR0              => asicR0     , 
        asicGlblRst         => asicGlblRst, 
        asicSync            => asicSync   , 
        asicAcq             => asicAcq    , 
        asicSro             => asicSro    , 
        asicClkEn           => asicClkEn  , 
    
        -- SACI Ports
        saciCmd         => asicSaciCmd, 
        saciClk         => asicSaciClk, 
        saciSel         => asicSaciSel, 
        saciRsp         => asicSaciRsp, 
    
        -- Spare ports both to carrier and to p&cb
        pcbSpare            => pcbSpare, 
        spareM              => spareM  , 
        spareP              => spareP  , 
    
        -- Bias Dac
        biasDacDin          => biasDacDin , 
        biasDacSclk         => biasDacSclk, 
        biasDacCsb          => biasDacCsb , 
        biasDacClrb         => biasDacClrb, 
    
        -- High speed dac
        hsDacSclk           => hsDacSclk, 
        hsDacDin            => hsDacDin , 
        hsCsb               => hsCsb    , 
        hsLdacb             => hsLdacb  , 
    
        -- Digital Monitor
        digMon              => digMon, 
    
        -- External trigger Connector
        runToFpga           => runToFpga , 
        daqToFpga           => daqToFpga , 
        ttlToFpga           => ttlToFpga , 
        fpgaTtlOut          => fpgaTtlOut, 
        fpgaMps             => fpgaMps   , 
        fpgaTg              => fpgaTg    , 
    
        -- Fpga Clock IO
        fpgaClkInP          => fpgaClkInP , 
        fpgaClkInM          => fpgaClkInM , 
        fpgaClkOutP         => fpgaClkOutP, 
        fpgaClkOutM         => fpgaClkOutM, 
    
        -- Serial number
        serialNumber        => serialNumber, 
    
        -- Digial board Power 
        syncDcdc            => syncDcdc          , 
        ldoShtdnL           => ldoShtdnL         , 

        -- Power and comm board power
        dcdcSync            => dcdcSync          , 
        pcbSync             => pcbSync           , 
        pwrGood             => pwrGood, 
    
        -- Digital board env monitor
        adcMonSpiClk        => adcMonSpiClk    , 
        adcMonSpiData       => adcMonSpiData   , 
        adcMonClkP          => adcMonClkP   , 
        adcMonClkM          => adcMonClkM   , 
        adcMonPdwn          => adcMonPdwn   , 
        adcMonSpiCsL        => adcMonSpiCsb , 
        slowAdcDout         => slowAdcDout  , 
        slowAdcDrdyL        => slowAdcDrdyL , 
        slowAdcSyncL        => slowAdcSyncL , 
        slowAdcSclk         => slowAdcSclk  , 
        slowAdcCsL          => slowAdcCsL   , 
        slowAdcDin          => slowAdcDin   , 
        slowAdcRefClk       => slowAdcRefClk, 
    
        ----------------------------------------------
        --               Core Ports                 --
        ----------------------------------------------
        -- Clock Jitter Cleaner
        jitclnrCsL  => jitclnrCsL , 
        jitclnrIntr => jitclnrIntr, 
        jitclnrLolL => jitclnrLolL, 
        jitclnrOeL  => jitclnrOeL , 
        jitclnrRstL => jitclnrRstL, 
        jitclnrSclk => jitclnrSclk, 
        jitclnrSdio => jitclnrSdio, 
        jitclnrSdo  => jitclnrSdo , 
        jitclnrSel  => jitclnrSel , 
    
        -- LMK61E2
        pllClkScl   => pllClkScl, 
        pllClkSda   => pllClkSda, 
    
        -- XADC Ports
        vPIn => vPIn, 
        vNIn => vNIn
   );

   fpgaClkInP <= Clk250P;
   fpgaClkInM <= Clk250M;
 
    gtPllClkP <= (others => Clk250P);
    gtPllClkM <= (others => Clk250M);

    gtRefClkP <= (others => Clk156P);
    gtRefClkM <= (others => Clk156M);
 
    U_Clk156 : entity surf.ClkRst
       generic map (
            CLK_PERIOD_G      => 6.4 ns,   -- 156.25 MHz
            RST_START_DELAY_G => 0 ns,
            RST_HOLD_TIME_G   => 1000 ns)
       port map (
            clkP => Clk156P,
            clkN => Clk156M
        );
 
    U_Clk250 : entity surf.ClkRst
       generic map (
            CLK_PERIOD_G      => 4 ns,  -- 250 MHz
            RST_START_DELAY_G => 10 ns,
            RST_HOLD_TIME_G   => 1000 ns)
       port map (
          clkP => Clk250P,
          clkN => Clk250M
        );
 
    U_Clk371 : entity surf.ClkRst
       generic map (
            CLK_PERIOD_G      => 2.690 ns,  -- 371 MHz
            RST_START_DELAY_G => 0 ns,
            RST_HOLD_TIME_G   => 1000 ns)
       port map (
            clkP => gtLclsIITimingClkP,
            clkN => gtLclsIITimingClkM
        );

end architecture;