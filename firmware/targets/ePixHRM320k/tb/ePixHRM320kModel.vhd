-------------------------------------------------------------------------------
-- File       : EPixHR10kModel.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: A model for the ePixHRM320k ASIC
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

library ruckus;
use ruckus.BuildInfoPkg.all;

library STD;
use STD.textio.all;  
-------------------------------------------------------------------------------

entity ePixHRM320kModel is
     generic (
        TPD_G        : time := 1 ns;
        IDLE_PATTERN_C : slv(15 downto 0) := x"00FF"
      );
      port (

      asicR0Clk       : in    sl; 

      asicDataP       : out   slv(23 downto 0);
      asicDataN       : out   slv(23 downto 0);

      asicGr          : in    sl; 
      asicSro         : in    sl 

      );
end ePixHRM320kModel;

-------------------------------------------------------------------------------

architecture arch of ePixHRM320kModel is

      -- internal clocks
      signal dClkP     :  sl;
      signal fClkP     :  sl;
      signal dClkP2x   :  sl;

    begin

    G_LANES : for i in 23 downto 0 generate
      U_LaneModel  : entity work.ePixHRM320kLaneModel
        generic map(
          LANE_INDEX   =>  toSlv(i,15) & '0'
          )
        port map(
          dClkP       =>    dClkP,
          fClkP       =>    fClkP,
          dClkP2x     =>    dClkP2x,
          asicDataP   =>    asicDataP(i),
          asicDataN   =>    asicDataN(i),
          asicGr      =>    asicGr,
          asicSro     =>    asicSro
        );
    end generate;


    U_TB_ClockGen : entity surf.ClockManagerUltraScale 
    generic map(
      TPD_G                  => 1 ns,
      TYPE_G                 => "MMCM",  -- or "PLL"
      INPUT_BUFG_G           => true,
      FB_BUFG_G              => true,
      RST_IN_POLARITY_G      => '1',     -- '0' for active low
      NUM_CLOCKS_G           => 3,
      -- MMCM attributes
      BANDWIDTH_G            => "OPTIMIZED",
      CLKIN_PERIOD_G         => 4.000,    -- Input period in ns );
      DIVCLK_DIVIDE_G        => 4,
      CLKFBOUT_MULT_F_G      => 16.0,
      CLKFBOUT_MULT_G        => 16,
      CLKOUT0_DIVIDE_F_G     => 1.0,
      CLKOUT0_DIVIDE_G       => 4,
      CLKOUT0_PHASE_G        => 0.0,
      CLKOUT0_DUTY_CYCLE_G   => 0.5,
      CLKOUT0_RST_HOLD_G     => 3,
      CLKOUT0_RST_POLARITY_G => '1',
      CLKOUT1_DIVIDE_G       => 40,
      CLKOUT1_PHASE_G        => 0.0,
      CLKOUT1_DUTY_CYCLE_G   => 0.5,
      CLKOUT1_RST_HOLD_G     => 3,
      CLKOUT1_RST_POLARITY_G => '1',
      CLKOUT2_DIVIDE_G       => 2,
      CLKOUT2_PHASE_G        => 0.0,
      CLKOUT2_DUTY_CYCLE_G   => 0.5,
      CLKOUT2_RST_HOLD_G     => 3,
      CLKOUT2_RST_POLARITY_G => '1')
   port map(
      clkIn           => asicR0Clk, 
      rstIn           => '0',
      clkOut(0)       => dClkP,
      clkOut(1)       => fClkP,
      clkOut(2)       => dClkP2x,
      rstOut(0)       => open,
      rstOut(1)       => open,
      rstOut(2)       => open,
      locked          => open
   );
end arch;

