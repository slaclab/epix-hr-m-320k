-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: EPixHR10k2M VHDL package
-------------------------------------------------------------------------------
-- This file is part of 'ATLAS ATCA LINK AGG DEV'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'ATLAS ATCA LINK AGG DEV', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.Pgp4Pkg.all;

package CorePkg is

   constant XIL_DEVICE_C : string := "ULTRASCALE_PLUS";

   constant AXIL_CLK_FREQ_C   : real     := 156.25E+6;  -- In units of Hz
   constant AXIL_CLK_PERIOD_C : real     := (1.0/AXIL_CLK_FREQ_C);  -- In units of seconds

   constant APP_AXIL_BASE_ADDR_C : slv(31 downto 0) := x"80000000";

   constant APP_AXIS_CONFIG_C : AxiStreamConfigType := PGP4_AXIS_CONFIG_C;

   constant PGP_RATE_C : string := "10.3125Gbps";

end package CorePkg;
