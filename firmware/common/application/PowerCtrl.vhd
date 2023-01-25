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

library epix_leap_core;
use epix_leap_core.CorePkg.all;

library unisim;
use unisim.vcomponents.all;

entity PowerCtrl is
    generic (
        TPD_G  : time      := 1 ns
    );
    port (
      -- Global Signals
      axiClk         : in  sl;
      axiRst         : in  sl;
      
      -- AXI-Lite Register Interface (axiClk domain)
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -------------------
      --  Top Level Ports
      -------------------
      -- Power Ports
      clk6Meg          : in sl;
      syncDcdc         : out slv(6 downto 0);
      pwrGood          : in  slv(1 downto 0);
      pwrAnaEn         : out slv(1 downto 0);
      PwrSync1MHzClk   : out sl;
      PwrEnable6V      : out sl;
      pwrEnAna         : out slv(1 downto 0);
      pwrEnDig         : out slv(4 downto 0)
    );
end entity PowerCtrl;

architecture rtl of PowerCtrl is

   type RegType is record
      pwrEnable6V    : sl;
      pwrEnAna       : slv(1 downto 0);
      pwrEnDig       : slv(4 downto 0);
      axilReadSlave  : AxiLiteReadSlaveType;
      axilWriteSlave : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      pwrEnable6V    => '0',
      pwrEnAna       => (others => '0'),
      pwrEnDig       => (others => '0'),
      axilReadSlave  => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   constant COUNT_WIDTH_C  : natural := 3;

begin

   DCDC_CLK_U : entity surf.ClockDivider
      generic map(
         TPD_G             => TPD_G,   
         COUNT_WIDTH_G     => COUNT_WIDTH_C 
      )
      port map(
         clk        => clk6Meg,
         rst        => axiRst,
         highCount  => toslv(3, COUNT_WIDTH_C),
         lowCount   => toslv(3, COUNT_WIDTH_C),
         delayCount => toslv(0, COUNT_WIDTH_C),
         divClk     => PwrSync1MHzClk,
         preRise    => open,
         preFall    => open
         );

   comb : process (axilReadMaster, axiRst, axilWriteMaster, pwrGood, r) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- Register Mapping
      axiSlaveRegister (axilEp, x"0", 0, v.pwrEnable6V);
      axiSlaveRegister (axilEp, x"4", 0, v.pwrEnAna);
      axiSlaveRegister (axilEp, x"8", 0, v.pwrEnDig);
      axiSlaveRegisterR(axilEp, x"C", 0, pwrGood);

      -- Closeout the transaction
      axiSlaveDefault(axilEp, v.axilWriteSlave, v.axilReadSlave, AXI_RESP_DECERR_C);

      -- Synchronous Reset
      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axilReadSlave  <= r.axilReadSlave;
      axilWriteSlave <= r.axilWriteSlave;
      syncDcdc        <= (others => '0');
      -- pwrSync1MHzClk <= '0';
      pwrEnable6V    <= r.pwrEnable6V;
      pwrEnAna       <= r.pwrEnAna;
      pwrEnDig       <= r.pwrEnDig;

   end process comb;

   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;
end architecture;