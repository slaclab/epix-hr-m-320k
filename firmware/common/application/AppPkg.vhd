
library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

-------------------------------------------------------------------------------
-- File       : AppPkg.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Application's Package File
-------------------------------------------------------------------------------
-- This file is part of 'EPIX HR Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'EPIX HR Firmware', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

package AppPkg is


   constant NUMBER_OF_ASICS_C               : natural := 4;   
   constant NUMBER_OF_LANES_C               : natural := 1;   
   
   constant NUM_AXIL_MASTERS_C              : natural := 20;
   constant NUM_AXIL_SLAVES_C               : natural := 1;
   
   constant PLLREGS_AXI_INDEX_C             : natural := 0;

   
   constant PLLREGS_AXI_BASE_ADDR_C         : slv(31 downto 0) := X"80000000";--0

   
   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := (
         PLLREGS_AXI_INDEX_C     => (
         baseAddr                => PLLREGS_AXI_BASE_ADDR_C,
         addrBits                => 24,
         connectivity            => x"FFFF")
   );


   type AppConfigType is record
      AppVersion           : slv(31 downto 0);
      powerEnable          : slv(3 downto 0);
      asicMask             : slv(NUMBER_OF_ASICS_C-1 downto 0);
      acqCnt               : slv(31 downto 0);
      requestStartupCal    : sl;
      startupAck           : sl;
      startupFail          : sl;
      epixhrDbgSel1        : slv(4 downto 0);
      epixhrDbgSel2        : slv(4 downto 0);
      epixhrDbgSel3        : slv(3 downto 0);
   end record;


   constant APP_CONFIG_INIT_C : AppConfigType := (
      AppVersion           => (others => '0'),
      powerEnable          => (others => '0'),
      asicMask             => (others => '0'),
      acqCnt               => (others => '0'),
      requestStartupCal    => '1',
      startupAck           => '0',
      startupFail          => '0',
      epixhrDbgSel1        => (others => '0'),
      epixhrDbgSel2        => (others => '0'),
      epixhrDbgSel3        => (others => '0')
   );
   
   type HR_FDConfigType is record
      pwrEnableReq         : sl;
   end record;

   constant HR_FD_CONFIG_INIT_C : HR_FDConfigType := (
      pwrEnableReq         => '0'
   );
   

end package AppPkg;

package body AppPkg is

end package body AppPkg;
