-------------------------------------------------------------------------------
-- File       : RegControlEpixHR.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: EpixHR register controller
-------------------------------------------------------------------------------
-- This file is part of 'EpixHR Development Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'EpixHR Development Firmware', including this file, 
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

use work.AppPkg.all;

library unisim;
use unisim.vcomponents.all;

entity RegisterControl is
   generic (
      TPD_G             : time               := 1 ns;
      EN_DEVICE_DNA_G   : boolean            := true;
      CLK_PERIOD_G      : real               := 10.0e-9;
      BUILD_INFO_G      : BuildInfoType
   );
   port (
      -- Global Signals
      axiClk         : in  sl;
      axiRst         : out sl;
      sysRst         : in  sl;

      -- AXI-Lite Register Interface (axiClk domain)
      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType;

      -- ASICs acquisition signals
      acqStart       : in  sl;
      asicPPbe       : out sl;
      asicPpmat      : out sl;
      asicTpulse     : out sl;
      asicStart      : out sl;
      asicSR0        : out sl;
      asicGlblRst    : out sl;
      asicSync       : out sl;
      asicAcq        : out sl;
      asicClkEn      : out sl;
      errInhibit     : out sl
   );
end RegisterControl;

architecture rtl of RegisterControl is

   type AsicAcqType is record
      SR0               : sl;
      SR0Polarity       : sl;
      SR0Delay          : slv(31 downto 0);
      SR0Width          : slv(31 downto 0);
      SR0Delay2         : slv(31 downto 0);
      SR0Width2         : slv(31 downto 0);
      GlblRst           : sl;
      GlblRstPolarity   : sl;
      GlblRstDelay      : slv(31 downto 0);
      GlblRstWidth      : slv(31 downto 0);
      Acq               : sl;
      AcqCnt            : slv(31 downto 0);
      AcqPolarity       : sl;
      AcqDelay1         : slv(31 downto 0);
      AcqDelay2         : slv(31 downto 0);
      AcqWidth1         : slv(31 downto 0);
      AcqWidth2         : slv(31 downto 0);
      Tpulse            : sl;
      TpulsePolarity    : sl;
      TpulseDelay       : slv(31 downto 0);
      TpulseWidth       : slv(31 downto 0);
      Start             : sl;
      StartPolarity     : sl;
      StartDelay        : slv(31 downto 0);
      StartWidth        : slv(31 downto 0);
      PPbe              : sl;
      PPbePolarity      : sl;
      PPbeDelay         : slv(31 downto 0);
      PPbeWidth         : slv(31 downto 0);
      Ppmat             : sl;
      PpmatPolarity     : sl;
      PpmatDelay        : slv(31 downto 0);
      PpmatWidth        : slv(31 downto 0);
      Sync              : sl;
      SyncPolarity      : sl;
      SyncDelay         : slv(31 downto 0);
      SyncWidth         : slv(31 downto 0);
      saciSync          : sl;
      saciSyncPolarity  : sl;
      saciSyncDelay     : slv(31 downto 0);
      saciSyncWidth     : slv(31 downto 0);
      errInhibitCnt     : slv(31 downto 0);
      ePixAdcSHT        : slv(15 downto 0);
      ePixAdcSHCnt      : slv(15 downto 0);
      clkEn             : sl;
      asicAcqTimeCnt    : slv(31 downto 0);
      resetCounters     : sl;
      usrRst            : sl;
      axiReadSlave      : AxiLiteReadSlaveType;
      axiWriteSlave     : AxiLiteWriteSlaveType;
   end record AsicAcqType;
   
   constant ASICACQ_TYPE_INIT_C : AsicAcqType := (
      SR0               => '0',
      SR0Polarity       => '0',
      SR0Delay          => (others=>'0'),
      SR0Width          => (others=>'0'),
      SR0Delay2         => (others=>'0'),
      SR0Width2         => (others=>'0'),
      GlblRst           => '1',
      GlblRstPolarity   => '1',
      GlblRstDelay      => (others=>'0'),
      GlblRstWidth      => (others=>'0'),
      Acq               => '0',
      AcqCnt            => (others => '0'),
      AcqPolarity       => '0',
      AcqDelay1         => (others=>'0'),
      AcqDelay2         => (others=>'0'),
      AcqWidth1         => (others=>'0'),
      AcqWidth2         => (others=>'0'),
      Tpulse            => '0',
      TpulsePolarity    => '0',
      TpulseDelay       => (others=>'0'),
      TpulseWidth       => (others=>'0'),
      Start             => '0',
      StartPolarity     => '0',
      StartDelay        => (others=>'0'),
      StartWidth        => (others=>'0'),
      PPbe              => '0',
      PPbePolarity      => '0',
      PPbeDelay         => (others=>'0'),
      PPbeWidth         => (others=>'0'),
      Ppmat             => '0',
      PpmatPolarity     => '0',
      PpmatDelay        => (others=>'0'),
      PpmatWidth        => (others=>'0'),
      Sync              => '0',
      SyncPolarity      => '0',
      SyncDelay         => (others=>'0'),
      SyncWidth         => (others=>'0'),
      saciSync          => '0',
      saciSyncPolarity  => '0',
      saciSyncDelay     => (others=>'0'),
      saciSyncWidth     => (others=>'0'),
      ePixAdcSHT        => X"0100",
      ePixAdcSHCnt      => (others=>'0'),
      clkEn             => '0',
      asicAcqTimeCnt    => (others => '0'),
      resetCounters     => '0',
      usrRst            => '0',
      errInhibitCnt     => (others => '0'),
      axiReadSlave      => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave     => AXI_LITE_WRITE_SLAVE_INIT_C
   );
   
   signal r   : AsicAcqType := ASICACQ_TYPE_INIT_C;
   signal rin : AsicAcqType;
   
   signal axiReset : sl;
   
   constant BUILD_INFO_C       : BuildInfoRetType    := toBuildInfo(BUILD_INFO_G);
   
begin

   axiReset <= sysRst or r.usrRst;
   axiRst   <= axiReset;

   -------------------------------
   -- Configuration Register
   -------------------------------  
   comb : process (axiReadMaster, axiReset, axiWriteMaster, r, acqStart) is
      variable v           : AsicAcqType;
      variable regCon      : AxiLiteEndPointType;
      
   begin
      -- Latch the current value
      v := r;
      
      -- Reset strobes
      v.resetCounters            := '0';
      
      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave);
      
      -- Map out standard registers
      axiSlaveRegister (regCon, x"0000",  0, v.usrRst );
      axiSlaveRegisterR(regCon, x"0000",  0, BUILD_INFO_C.fwVersion );
      
      axiSlaveRegister(regCon,  x"010C",  0, v.GlblRstPolarity);
      axiSlaveRegister(regCon,  x"0110",  0, v.GlblRstDelay);
      axiSlaveRegister(regCon,  x"0114",  0, v.GlblRstWidth);
      axiSlaveRegister(regCon,  x"0118",  0, v.AcqPolarity);
      axiSlaveRegister(regCon,  x"011C",  0, v.AcqDelay1);
      axiSlaveRegister(regCon,  x"0120",  0, v.AcqWidth1);
      axiSlaveRegister(regCon,  x"0124",  0, v.AcqDelay2);
      axiSlaveRegister(regCon,  x"0128",  0, v.AcqWidth2);
      axiSlaveRegister(regCon,  x"012C",  0, v.TpulsePolarity);
      axiSlaveRegister(regCon,  x"0130",  0, v.TpulseDelay);
      axiSlaveRegister(regCon,  x"0134",  0, v.TpulseWidth);
      axiSlaveRegister(regCon,  x"0138",  0, v.StartPolarity);
      axiSlaveRegister(regCon,  x"013C",  0, v.StartDelay);
      axiSlaveRegister(regCon,  x"0140",  0, v.StartWidth);
      axiSlaveRegister(regCon,  x"0144",  0, v.PPbePolarity);
      axiSlaveRegister(regCon,  x"0148",  0, v.PPbeDelay);
      axiSlaveRegister(regCon,  x"014C",  0, v.PPbeWidth);
      axiSlaveRegister(regCon,  x"0150",  0, v.PpmatPolarity);
      axiSlaveRegister(regCon,  x"0154",  0, v.PpmatDelay);
      axiSlaveRegister(regCon,  x"0158",  0, v.PpmatWidth);
      axiSlaveRegister(regCon,  x"015C",  0, v.SyncPolarity);
      axiSlaveRegister(regCon,  x"0160",  0, v.SyncDelay);
      axiSlaveRegister(regCon,  x"0164",  0, v.SyncWidth);
      axiSlaveRegister(regCon,  x"0168",  0, v.saciSyncPolarity);
      axiSlaveRegister(regCon,  x"016C",  0, v.saciSyncDelay);
      axiSlaveRegister(regCon,  x"0170",  0, v.saciSyncWidth);
      axiSlaveRegister(regCon,  x"0174",  0, v.SR0Polarity);
      axiSlaveRegister(regCon,  x"0178",  0, v.SR0Delay);
      axiSlaveRegister(regCon,  x"017C",  0, v.SR0Width);
      axiSlaveRegister(regCon,  x"01A4",  0, v.ePixAdcSHT);
      axiSlaveRegister(regCon,  x"01A8",  0, v.clkEn);

      axiSlaveRegister(regCon,  x"01AC",  0, v.SR0Delay2);
      axiSlaveRegister(regCon,  x"01B0",  0, v.SR0Width2);
      axiSlaveRegister(regCon,  x"0208",  0, v.resetCounters);

      
      -- Special reset for write to address 00
      --if regCon.axiStatus.writeEnable = '1' and axiWriteMaster.awaddr = 0 then
      --   v.usrRst := '1';
      --end if;
      
      axiSlaveDefault(regCon, v.axiWriteSlave, v.axiReadSlave, AXI_RESP_OK_C);
      
      -- ePixHrADC clock counter to mimic the SHClk and SDrst periods in the asic
      -- sync SR0 start to this period to avoid the background bounce per bank
      -- at 250MHz this should be 1.28us
      -- at 125 this should be 2.56us
      if r.ePixAdcSHCnt >= r.ePixAdcSHT - 1 then
         v.ePixAdcSHCnt := (others => '0');
      else
         v.ePixAdcSHCnt := r.ePixAdcSHCnt + 1;
      end if;
      
      -- programmable ASIC acquisition waveform
      if acqStart = '1' then
         v.acqCnt                   := r.acqCnt + 1;
         v.asicAcqTimeCnt           := (others=>'0');
         v.SR0           := r.SR0Polarity;
         v.GlblRst       := r.GlblRstPolarity;
         v.Acq           := r.AcqPolarity;
         v.Tpulse        := r.TpulsePolarity;
         v.Start         := r.StartPolarity;
         v.PPbe          := r.PPbePolarity;
         v.Ppmat         := r.PpmatPolarity;
         v.Sync          := r.SyncPolarity;
         v.saciSync      := r.saciSyncPolarity;

      else
         if r.asicAcqTimeCnt /= x"FFFFFFFF" then
            v.asicAcqTimeCnt := r.asicAcqTimeCnt + 1;
         end if;
         
         -- single pulse. zero value corresponds to infinite delay/width
         if r.SR0Delay /= 0 and r.SR0Delay <= r.asicAcqTimeCnt then
            v.SR0 := not r.SR0Polarity;
            if r.SR0Width /= 0 and (r.SR0Width + r.SR0Delay) <= r.asicAcqTimeCnt then
               v.SR0 := r.SR0Polarity;
            end if;
         end if;
         
         ---- double pulse. zero value corresponds to infinite delay/width
         --if r.asicAcqReg.SR0Delay /= 0 and r.asicAcqReg.SR0Delay <= r.asicAcqTimeCnt then
         --   v.asicAcqReg.SR0 := not r.asicAcqReg.SR0Polarity;
         --   if r.asicAcqReg.SR0Width /= 0 and (r.asicAcqReg.SR0Width + r.asicAcqReg.SR0Delay) <= r.asicAcqTimeCnt then
         --      v.asicAcqReg.SR0 := r.asicAcqReg.SR0Polarity;
         --      if r.asicAcqReg.SR0Delay2 /= 0 and (r.asicAcqReg.SR0Delay2 + r.asicAcqReg.SR0Width + r.asicAcqReg.SR0Delay) <= r.asicAcqTimeCnt then
         --         v.asicAcqReg.SR0 := not r.asicAcqReg.SR0Polarity;
         --         if r.asicAcqReg.SR0Width2 /= 0 and (r.asicAcqReg.SR0Width2 + r.asicAcqReg.SR0Delay2 + r.asicAcqReg.SR0Width + r.asicAcqReg.SR0Delay) <= r.asicAcqTimeCnt then
         --            v.asicAcqReg.SR0 := r.asicAcqReg.SR0Polarity;
         --         end if;
         --      end if;
         --   end if;
         --end if;
         
         -- single pulse. zero value corresponds to infinite delay/width
         --if r.asicAcqReg.GlblRstDelay /= 0 and r.asicAcqReg.GlblRstDelay <= r.asicAcqTimeCnt then
         --   v.asicAcqReg.GlblRst := not r.asicAcqReg.GlblRstPolarity;
         --   if r.asicAcqReg.GlblRstWidth /= 0 and (r.asicAcqReg.GlblRstWidth + r.asicAcqReg.GlblRstDelay) <= r.asicAcqTimeCnt then
               v.GlblRst := r.GlblRstPolarity;
         --   end if;
         --end if;
         
         -- double pulse. zero value corresponds to infinite delay/width
         if r.AcqDelay1 /= 0 and r.AcqDelay1 <= r.asicAcqTimeCnt then
            v.Acq := not r.AcqPolarity;
            if r.AcqWidth1 /= 0 and (r.AcqWidth1 + r.AcqDelay1) <= r.asicAcqTimeCnt then
               v.Acq := r.AcqPolarity;
               if r.AcqDelay2 /= 0 and (r.AcqDelay2 + r.AcqWidth1 + r.AcqDelay1) <= r.asicAcqTimeCnt then
                  v.Acq := not r.AcqPolarity;
                  if r.AcqWidth2 /= 0 and (r.AcqWidth2 + r.AcqDelay2 + r.AcqWidth1 + r.AcqDelay1) <= r.asicAcqTimeCnt then
                     v.Acq := r.AcqPolarity;
                  end if;
               end if;
            end if;
         end if;
         
         -- single pulse. zero value corresponds to infinite delay/width
         if r.TpulseDelay /= 0 and r.TpulseDelay <= r.asicAcqTimeCnt then
            v.Tpulse := not r.TpulsePolarity;
            if r.TpulseWidth /= 0 and (r.TpulseWidth + r.TpulseDelay) <= r.asicAcqTimeCnt then
               v.Tpulse := r.TpulsePolarity;
            end if;
         end if;
         
         -- single pulse. zero value corresponds to infinite delay/width
         if r.StartDelay /= 0 and r.StartDelay <= r.asicAcqTimeCnt then
            v.Start := not r.StartPolarity;
            if r.StartWidth /= 0 and (r.StartWidth + r.StartDelay) <= r.asicAcqTimeCnt then
               v.Start := r.StartPolarity;
            end if;
         end if;
         
         -- single pulse. zero value corresponds to infinite delay/width
         if r.PPbeDelay /= 0 and r.PPbeDelay <= r.asicAcqTimeCnt then
            v.PPbe := not r.PPbePolarity;
            if r.PPbeWidth /= 0 and (r.PPbeWidth + r.PPbeDelay) <= r.asicAcqTimeCnt then
               v.PPbe := r.PPbePolarity;
            end if;
         end if;
         
         -- single pulse. zero value corresponds to infinite delay/width
         if r.PpmatDelay /= 0 and r.PpmatDelay <= r.asicAcqTimeCnt then
            v.Ppmat := not r.PpmatPolarity;
            if r.PpmatWidth /= 0 and (r.PpmatWidth + r.PpmatDelay) <= r.asicAcqTimeCnt then
               v.Ppmat := r.PpmatPolarity;
            end if;
         end if;
         
         -- single pulse. zero value corresponds to infinite delay/width
         if r.SyncDelay /= 0 and r.SyncDelay <= r.asicAcqTimeCnt then
            v.Sync := not r.SyncPolarity;
            if r.SyncWidth /= 0 and (r.SyncWidth + r.SyncDelay) <= r.asicAcqTimeCnt then
               v.Sync := r.SyncPolarity;
            end if;
         end if;
         
         -- single pulse. zero value corresponds to infinite delay/width
         if r.saciSyncDelay /= 0 and r.saciSyncDelay <= r.asicAcqTimeCnt then
            v.saciSync := not r.saciSyncPolarity;
            if r.saciSyncWidth /= 0 and (r.saciSyncWidth + r.saciSyncDelay) <= r.asicAcqTimeCnt then
               v.saciSync := r.saciSyncPolarity;
            end if;
         end if;
         
      end if;
            
      -- reset counters
      if r.resetCounters = '1' then
         v.acqCnt := (others=>'0');
      end if;
      
      -- epixhr bug workaround
      -- for a number of clock cycles
      -- data link is dropped after R0 
      if r.SR0 = not r.SR0Polarity then
         v.errInhibitCnt := (others=>'0');
         errInhibit <= '1';

      elsif r.errInhibitCnt <= 5000 then    -- inhibit for 50 us
         v.errInhibitCnt := r.errInhibitCnt + 1;
         errInhibit <= '1';
      else
         errInhibit <= '0';
      end if;
      
      -- Synchronous Reset
      if axiReset = '1' then
         v := ASICACQ_TYPE_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      --------------------------
      -- Outputs 
      --------------------------
      axiReadSlave   <= r.axiReadSlave;
      axiWriteSlave  <= r.axiWriteSlave;
      asicPPbe       <= r.PPbe;
      asicPpmat      <= r.Ppmat;
      asicTpulse     <= r.Tpulse;
      asicStart      <= r.Start;
      asicSR0        <= r.SR0;
      asicGlblRst    <= r.GlblRst;
      asicSync       <= r.Sync;
      asicAcq        <= r.Acq;
      asicClkEn      <= r.clkEn;
      
   end process comb;

   seq : process (axiClk) is
   begin
      if rising_edge(axiClk) then
         r <= rin after TPD_G;
      end if;
   end process seq;
end rtl;
