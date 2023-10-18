-------------------------------------------------------------------------------
-- Title      : ADS1217 ADC Controller
-- Project    : EPIX Detector
-------------------------------------------------------------------------------
-- File       : SlowAdcCntrlAxi.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:
-- This block is responsible for reading the voltages, currents and strongback
-- temperatures from the ADS1217 on the generation 2 EPIX analog board.
-- The ADS1217 is an 8 channel ADC.
-------------------------------------------------------------------------------
-- This file is part of 'EPIX Development Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'EPIX Development Firmware', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use ieee.math_real.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;
use surf.SsiPkg.all;
use surf.Pgp4Pkg.all;

library epix_hr_core;

library work;
use work.AppPkg.all;

library unisim;
use unisim.vcomponents.all;

entity SlowADCMon is
   generic (
      SIMULATION_G           : boolean := FALSE;
      TPD_G           	     : time := 1 ns;
      SYS_CLK_PERIOD_G       : real := 10.0E-9;   -- 100MHz
      ADC_CLK_PERIOD_G       : real := 200.0E-9;  -- 5MHz
      SPI_SCLK_PERIOD_G      : real := 1.0E-6;    -- 1MHz
      AXIL_ERR_RESP_G        : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      DEVICE_COUNT           : integer range 1 to 15:= 1
   );
   port (
      -- Master system clock
      sysClk            : in  sl;
      sysClkRst         : in  sl;

      -- Trigger Control
      adcStart          : in  sl;

      -- AXI lite slave port for register access
      axilClk           : in  sl;
      axilRst           : in  sl;
      sAxilWriteMaster  : in  AxiLiteWriteMasterType;
      sAxilWriteSlave   : out AxiLiteWriteSlaveType;
      sAxilReadMaster   : in  AxiLiteReadMasterType;
      sAxilReadSlave    : out AxiLiteReadSlaveType;

      -- AXI Stream
      slowAdcMasters    : out   AxiStreamMasterArray(DEVICE_COUNT-1 downto 0);
      slowAdcSlaves     : in    AxiStreamSlaveArray(DEVICE_COUNT-1 downto 0);

      -- ADC Control Signals
      adcRefClk         : out sl;
      adcDrdy           : in  sl;
      adcSclk           : out sl;
      adcDout           : in  sl;
      adcCsL            : out sl;
      adcDin            : out sl
   );
end SlowADCMon;


-- Define architecture
architecture RTL of SlowADCMon is

   type adc_data_type is array (natural range <>) of Slv24Array(8 downto 0);
   

   TYPE state_type IS (IDLE_S,WAIT_INITDONE_S,  WAIT_ADCISREADING_S, ADCRD_S, SELNEXTDEVICE_S);

   type RegType is record
      enableADC_r         : sl;
      adcCoreRst_r        : sl;
      adcCoreStart_r      : sl;
      adcDeviceSel_r      : integer range 0 to DEVICE_COUNT-1;
      adcData_r           : adc_data_type(DEVICE_COUNT-1 downto 0);

      state               : state_type;
      tick                : unsigned(31 downto 0);
      delaycnter          : unsigned(7 downto 0);
      autoTrig            : slv(15 downto 0);
      doutreg             : slv(7 downto 0);

      selectedCh          : slv(31 downto 0);

      sAxilWriteSlave     : AxiLiteWriteSlaveType;
      sAxilReadSlave      : AxiLiteReadSlaveType;
      txMaster            : AxiStreamMasterArray(DEVICE_COUNT-1 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      enableADC_r         => '0',
      adcCoreRst_r        => '1',
      adcCoreStart_r      => '0',
      adcDeviceSel_r      => 0,
      adcData_r           => (others=>(others=>(others=>'0'))),

      state               => IDLE_S, --RESET_S,
      tick                => x"00000000",
      autoTrig            => x"1000",
      doutreg             => x"00",
      delaycnter          => x"00",
      selectedCh          => x"00000000",

      sAxilWriteSlave     => AXI_LITE_WRITE_SLAVE_INIT_C,
      sAxilReadSlave      => AXI_LITE_READ_SLAVE_INIT_C,
      txMaster            => (others => axiStreamMasterInit(PGP4_AXIS_CONFIG_C))
   );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal adcData       : Slv24Array(8 downto 0);
   signal adcDataSync   : Slv24Array(8 downto 0);
   signal adcRdDone     : sl;
   signal adcCoreRst    : sl;
   signal adcCoreStart  : sl;
   signal adcCsLR       : sl;

   signal adcDrdySync   : sl;
   signal adcRdDoneSync : sl;
   signal adcDoutRegSync: slv(7 downto 0);

   signal dbg           : slv(31 downto 0);

   signal newDataSync     : sl;
   signal channelSync     : slv(3 downto 0);
   signal channelDataSync : slv(23 downto 0);

   signal newData         : sl;
   signal channel         : slv(3 downto 0);
   signal channelData     : slv(23 downto 0);
begin

   ---------------------------------------------------------------------------
   -----------   AXI LIte register readout logic  ----------------------------
   ---------------------------------------------------------------------------
   comb : process (axilRst, sAxilReadMaster, sAxilWriteMaster, r, axilClk, adcRdDoneSync, adcDrdySync, dbg, adcStart, slowAdcSlaves, newDataSync, channelSync, channelDataSync, adcDataSync) is
      variable v        : RegType;
      variable regCon   : AxiLiteEndPointType;
   begin
      v := r;

      axiSlaveWaitTxn(regCon, sAxilWriteMaster, sAxilReadMaster, v.sAxilWriteSlave, v.sAxilReadSlave);

      axiSlaveRegister(regCon, x"00", 0, v.enableADC_r); -- unused
      axiSlaveRegisterR(regCon, x"00", 1, r.adcCoreRst_r);
      axiSlaveRegisterR(regCon, x"00", 2, r.adcCoreStart_r);
      axiSlaveRegisterR(regCon, x"00", 3, adcRdDoneSync);
      axiSlaveRegisterR(regCon, x"00", 4, adcDrdySync);
      axiSlaveRegisterR(regCon, x"00", 16, std_logic_vector(to_unsigned(r.adcDeviceSel_r, 16)));
      axiSlaveRegister(regCon, x"04", 0, v.selectedCh);
      axiSlaveRegister(regCon, x"08", 0, v.autoTrig);
      axiSlaveRegister(regCon, x"10", 0, v.doutreg);

      for i in 1 to DEVICE_COUNT loop
        axiSlaveRegisterR(regCon, std_logic_vector(to_unsigned((32*i+0), 8)), 0, r.adcData_r(i-1)(0));
        axiSlaveRegisterR(regCon, std_logic_vector(to_unsigned((32*i+4), 8)), 0, r.adcData_r(i-1)(1));
        axiSlaveRegisterR(regCon, std_logic_vector(to_unsigned((32*i+8), 8)), 0, r.adcData_r(i-1)(2));
        axiSlaveRegisterR(regCon, std_logic_vector(to_unsigned((32*i+12), 8)), 0, r.adcData_r(i-1)(3));
        axiSlaveRegisterR(regCon, std_logic_vector(to_unsigned((32*i+16), 8)), 0, r.adcData_r(i-1)(4));
        axiSlaveRegisterR(regCon, std_logic_vector(to_unsigned((32*i+20), 8)), 0, r.adcData_r(i-1)(5));
        axiSlaveRegisterR(regCon, std_logic_vector(to_unsigned((32*i+24), 8)), 0, r.adcData_r(i-1)(6));
        axiSlaveRegisterR(regCon, std_logic_vector(to_unsigned((32*i+28), 8)), 0, r.adcData_r(i-1)(7));
      end loop;
      
      axiSlaveRegisterR(regCon, x"14", 0, dbg);

      axiSlaveDefault(regCon, v.sAxilWriteSlave, v.sAxilReadSlave, AXIL_ERR_RESP_G);

      v.tick  := r.tick + 1;
      
      for i in 0 to DEVICE_COUNT-1 loop
        v.txMaster(i).tValid := '0';
      end loop;

      -- Readout process
      case r.state is

        when IDLE_S =>
            v.adcCoreStart_r  := '0';
            v.adcCoreRst_r    := '1';
            
            if r.adcDeviceSel_r > 0 then
                v.delaycnter      := x"00";
                v.state           := WAIT_INITDONE_S;
                
            elsif adcStart = '1' then
                v.delaycnter      := x"00";
                v.state           := WAIT_INITDONE_S;
            
            elsif v.autoTrig /= x"00000000" and v.tick(31 downto 16) = unsigned(v.autoTrig) then
                v.delaycnter      := x"00";
                v.state           := WAIT_INITDONE_S;
            end if;

        when WAIT_INITDONE_S =>
            v.adcCoreStart_r  := '0';
            v.adcCoreRst_r    := '0';
            
            if r.delaycnter(7) = '1' then
                v.adcCoreStart_r  := '1';
                v.state           := WAIT_ADCISREADING_S;
            else
                v.delaycnter      := r.delaycnter + 1;
            end if;
            

        when WAIT_ADCISREADING_S =>
            if adcRdDoneSync = '0' then
                v.state := ADCRD_S;
                if (slowAdcSlaves(r.adcDeviceSel_r).tReady = '1') then
                   v.txMaster(r.adcDeviceSel_r) := axiStreamMasterInit(PGP4_AXIS_CONFIG_C);
                end if;
                
                ssiSetUserSof(PGP4_AXIS_CONFIG_C, v.txMaster(0), '1');
                v.txMaster(r.adcDeviceSel_r).tLast              := '0';
                v.txMaster(r.adcDeviceSel_r).tData(31 downto 0) := "1111" & std_logic_vector(r.tick(31 downto 4));
                v.txMaster(r.adcDeviceSel_r).tValid             := '1';
                
            end if;

        when ADCRD_S =>
            v.adcCoreStart_r  := '0';
            
            if newDataSync = '1' then
                if (slowAdcSlaves(r.adcDeviceSel_r).tReady = '1') then
                   v.txMaster(r.adcDeviceSel_r) := axiStreamMasterInit(PGP4_AXIS_CONFIG_C);
                end if;
                
                v.txMaster(r.adcDeviceSel_r).tData(31 downto 0) := "0000" & channelSync & channelDataSync;
                v.txMaster(r.adcDeviceSel_r).tValid             := '1';
                
                if adcRdDoneSync = '1' then                
                    v.txMaster(r.adcDeviceSel_r).tLast              := '1';
                else
                    v.txMaster(r.adcDeviceSel_r).tLast              := '0';
                end if;
            end if;
            

            if adcRdDoneSync = '1' then
                -- Register data:
                v.adcData_r(r.adcDeviceSel_r)(0) := adcDataSync(0);
                v.adcData_r(r.adcDeviceSel_r)(1) := adcDataSync(1);
                v.adcData_r(r.adcDeviceSel_r)(2) := adcDataSync(2);
                v.adcData_r(r.adcDeviceSel_r)(3) := adcDataSync(3);
                v.adcData_r(r.adcDeviceSel_r)(4) := adcDataSync(4);
                v.adcData_r(r.adcDeviceSel_r)(5) := adcDataSync(5);
                v.adcData_r(r.adcDeviceSel_r)(6) := adcDataSync(6);
                v.adcData_r(r.adcDeviceSel_r)(7) := adcDataSync(7);
                v.adcData_r(r.adcDeviceSel_r)(8) := adcDataSync(8);
                
                v.adcCoreRst_r   := '1';
                v.state          := SELNEXTDEVICE_S;

            end if;

        when SELNEXTDEVICE_S =>
            if v.adcDeviceSel_r = DEVICE_COUNT-1 then
                v.adcDeviceSel_r :=  0;
                v.tick           :=  x"00000000";
            else
                v.adcDeviceSel_r  := r.adcDeviceSel_r + 1;
            end if;
            
            v.state          := IDLE_S;

      end case;

      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

      sAxilWriteSlave   <= r.sAxilWriteSlave;
      sAxilReadSlave    <= r.sAxilReadSlave;
      slowAdcMasters    <= r.txMaster;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   -----------------------------------------------------------------
   -----------------   ADC signal synch. logic ---------------------
   -----------------------------------------------------------------
   -- Syncrhonize trigger, channel selection and reset (from axiClk to sysClk)
   rstSync_U: entity surf.Synchronizer
   port map (
      clk     => sysClk,
      rst     => sysClkRst,
      dataIn  => r.adcCoreRst_r,
      dataOut => adcCoreRst
   );

   startSync_U: entity surf.Synchronizer
   port map (
      clk     => sysClk,
      rst     => sysClkRst,
      dataIn  => r.adcCoreStart_r,
      dataOut => adcCoreStart
   );
   
   DIOSync_U: entity surf.SynchronizerVector
   generic map (
      WIDTH_G  => 8
   )
   port map (
      clk     => sysClk,
      rst     => sysClkRst,
      dataIn  => r.doutreg,
      dataOut => adcDoutRegSync
   );


   -- Syncrhonize read done signal (from sysClk to axiClk)
   rdDoneSync_U: entity surf.Synchronizer
   port map (
      clk     => axilClk,
      rst     => axilRst,
      dataIn  => adcRdDone,
      dataOut => adcRdDoneSync
   );

   adcDrdySync_U: entity surf.Synchronizer
   port map (
      clk     => axilClk,
      rst     => axilRst,
      dataIn  => adcDrdy,
      dataOut => adcDrdySync
   );

   -- Synchronize ADC data (from sysclk to axiclk)
   ChDataSync_G : for i in 0 to 8 generate
      DaSync_U: entity surf.SynchronizerVector
      generic map (
         WIDTH_G  => 24
      )
      port map (
         clk     => axilClk,
         rst     => axilRst,
         dataIn  => adcData(i),
         dataOut => adcDataSync(i)
      );
   end generate;
   
   ChSync_U: entity surf.SynchronizerVector
   generic map (
      WIDTH_G  => 4
   )
   port map (
      clk     => axilClk,
      rst     => axilRst,
      dataIn  => channel,
      dataOut => channelSync
   );
   
   ChDataSync_U: entity surf.SynchronizerVector
   generic map (
      WIDTH_G  => 24
   )
   port map (
      clk     => axilClk,
      rst     => axilRst,
      dataIn  => channelData,
      dataOut => channelDataSync
   );

   newDataSync_U: entity surf.Synchronizer
   port map (
      clk     => axilClk,
      rst     => axilRst,
      dataIn  => newData,
      dataOut => newDataSync
   );

   -----------------------------------------------------------------
   -----------------   ADC data readout logic ----------------------
   -----------------------------------------------------------------
   ADC_U: entity epix_hr_core.ads1217
       generic map(
          SIMULATION_G      => SIMULATION_G,
          TPD_G           	=> TPD_G,
          SYS_CLK_PERIOD_G  => SYS_CLK_PERIOD_G,
          ADC_CLK_PERIOD_G  => ADC_CLK_PERIOD_G,
          SPI_SCLK_PERIOD_G => SPI_SCLK_PERIOD_G,
          
          VREF_G            => '0',
          IDAC1_RANGE_G     => "01",
          IDAC2_RANGE_G     => "01",
          IDAC1_G           => x"66",
          IDAC2_G           => x"66"
       )
       port map(
          -- Master system clock
          sysClk          => sysClk,
          sysClkRst       => adcCoreRst,

          -- Operation Control
          adcStart        => adcCoreStart,
          adcData         => adcData,
          allChRd         => adcRdDone,
          dout            => adcDoutRegSync,

          -- Data stream
          channel         => channel,
          data            => channelData,
          newdata         => newData,
      
          -- ADC Control Signals
          adcRefClk       => adcRefClk,
          adcSclk         => adcSclk,
          adcDout         => adcDout,
          adcCsL          => adcCsLR,
          adcDin          => adcDin,

          dbg_cmdcnter    => dbg
       );

   adcDout <= std_logic_vector(to_unsigned(r.adcDeviceSel_r, 8));
   adcCsL  <=  adcCsLR;

end RTL;
