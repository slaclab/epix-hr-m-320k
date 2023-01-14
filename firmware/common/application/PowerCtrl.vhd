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

entity PowerCtrl is
    generic (
        TPD_G             : time               := 1 ns;
        SIMULATION_G        : boolean   := false
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

      -- 1-wire board ID interfaces
      serialIdIo     : inout slv(1 downto 0)
        
    );
end entity PowerCtrl;

architecture rtl of PowerCtrl is
    signal idValues : Slv64Array(2 downto 0);
    signal idValids : slv(2 downto 0);
    signal dummyIdValues : slv(63 downto 0);

    type PowerControlType is record
      
    end record;

begin

    conb: process (axiReadMaster, axiWriteMaster, r, idValids, idValues)
        variable v           : PowerControlType;
        variable regCon      : AxiLiteEndPointType;
    begin

        -- Determine the transaction type
        axiSlaveWaitTxn(regCon, axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave);

        axiSlaveRegisterR(regCon, x"0004",  0, ite(idValids(0) = '1',idValues(0)(31 downto  0), x"00000000")); --Digital card ID low
        axiSlaveRegisterR(regCon, x"0008",  0, ite(idValids(0) = '1',idValues(0)(63 downto 32), x"00000000")); --Digital card ID high
        axiSlaveRegisterR(regCon, x"000C",  0, ite(idValids(1) = '1',idValues(1)(31 downto  0), x"00000000")); --Analog card ID low
        axiSlaveRegisterR(regCon, x"0010",  0, ite(idValids(1) = '1',idValues(1)(63 downto 32), x"00000000")); --Analog card ID high
        axiSlaveRegisterR(regCon, x"0014",  0, ite(idValids(2) = '1',idValues(2)(31 downto  0), x"00000000")); --Carrier card ID low
        axiSlaveRegisterR(regCon, x"0018",  0, ite(idValids(2) = '1',idValues(2)(63 downto 32), x"00000000")); --Carrier card ID high
    end process;

       -----------------------------------------------
   -- Serial IDs: FPGA Device DNA + DS2411's
   -----------------------------------------------  
   GEN_DEVICE_DNA : if (EN_DEVICE_DNA_G = true) generate
    G_DEVICE_DNA : entity surf.DeviceDna
       generic map (
          TPD_G        => TPD_G,
          XIL_DEVICE_G => "ULTRASCALE")
       port map (
          clk      => axiClk,
          rst      => axiReset,
          dnaValue(127 downto 64) => dummyIdValues,
          dnaValue( 63 downto  0) => idValues(0),
          dnaValid => idValids(0)
       );
    G_DS2411 : for i in 0 to 1 generate
      U_DS2411_N : entity surf.DS2411Core
        generic map (
          TPD_G        => TPD_G,
          CLK_PERIOD_G => CLK_PERIOD_G
          )
        port map (
          clk       => axiClk,
          rst       => chipIdRst,
          fdSerSdio => serialIdIo(i),
          fdValue   => idValues(i+1),
          fdValid   => idValids(i+1)
        );
    end generate;
 end generate GEN_DEVICE_DNA;
 
 BYP_DEVICE_DNA : if (EN_DEVICE_DNA_G = false) generate
    idValids(0) <= '1';
    idValues(0) <= (others=>'0');
 end generate BYP_DEVICE_DNA;   

    
  GEN_VEC : for i in 1 downto 0 generate
    U_snAdcCard : entity surf.DS2411Core
       generic map (
          TPD_G        => TPD_G,
          SIMULATION_G => SIMULATION_G,
          CLK_PERIOD_G => AXIL_CLK_PERIOD_C
      )
       port map (
          clk       => axiClk,
          rst       => axiRst,
          fdSerSdio => serialNumber(i),
          fdValue   => snCardId(i)
      );
 end generate GEN_VEC;

end architecture;