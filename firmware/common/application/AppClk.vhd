library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;

library work;
use work.AppPkg.all;

library unisim;
use unisim.vcomponents.all;

entity AppClk is
   generic(
      TPD_G           : time := 1 ns;
      SIMULATION_G    : boolean := false
   );
   port (
      clkInP      : in sl;
      clkInM      : in sl;
   );
end entity ; -- AppClk

architecture rtl of AppClk is



begin
   U_IBUFDS_GT : IBUFDS_GTE4
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00"
      )
      port map (
         I     => clkInP,
         IB    => clkInM,
         CEB   => '0',
         ODIV2 => fabRefClk,
         O     => gtRefClk
      );

   ------------------------------------------
   -- Generate clocks from 156.25 MHz PGP  --
   ------------------------------------------
   -- clkIn     : 156.25 MHz PGP
   -- base clk is 1000 MHz
   -- clkOut(0) : 160.00 MHz ASIC ref clock
   -- clkOut(1) : 50.00  MHz adc clock
   -- clkOut(2) : 100.00 MHz app clock
   U_CoreClockGen : entity surf.ClockManagerUltraScale
      generic map(
         TPD_G                  => 1 ns,
         TYPE_G                 => "MMCM",  -- or "PLL"
         INPUT_BUFG_G           => true,
         FB_BUFG_G              => true,
         RST_IN_POLARITY_G      => '1',     -- '0' for active low
         NUM_CLOCKS_G           => 3,
         SIMULATION_G           => SIMULATION_G,
         -- MMCM attributes
         BANDWIDTH_G            => "OPTIMIZED",
         CLKIN_PERIOD_G         => 6.4,    -- Input period in ns );
         DIVCLK_DIVIDE_G        => 5,        -- 1000 Base clk
         CLKFBOUT_MULT_F_G      => 32.0,     -- 1000 Base clk
         CLKFBOUT_MULT_G        => 5,
         CLKOUT0_DIVIDE_F_G     => 6.25,     -- 1000 Base clk
         CLKOUT0_DIVIDE_G       => 1,
         CLKOUT1_DIVIDE_G       => 20,       -- 1000 Base clk
         CLKOUT2_DIVIDE_G       => 10,       -- 1000 Base clk
         CLKOUT0_PHASE_G        => 0.0,
         CLKOUT1_PHASE_G        => 0.0,
         CLKOUT2_PHASE_G        => 0.0,
         CLKOUT0_DUTY_CYCLE_G   => 0.5,
         CLKOUT1_DUTY_CYCLE_G   => 0.5,
         CLKOUT2_DUTY_CYCLE_G   => 0.5,
         CLKOUT0_RST_HOLD_G     => 3,
         CLKOUT1_RST_HOLD_G     => 3,
         CLKOUT2_RST_HOLD_G     => 3,
         CLKOUT0_RST_POLARITY_G => '1',
         CLKOUT1_RST_POLARITY_G => '1',
         CLKOUT2_RST_POLARITY_G => '1'
      )
      port map(
         clkIn           => gtRefClk,
         rstIn           => sysRst,
         clkOut(0)       => refClk,
         clkOut(1)       => adcClk,
         clkOut(2)       => appClk,
         rstOut(0)       => refRst,
         rstOut(1)       => adcRst,
         rstOut(2)       => appRst,
         locked          => open,
         -- AXI-Lite Interface
         axilClk         => appClk,
         axilRst         => appRst,
         axilReadMaster  => mAxiReadMasters(PLLREGS_AXI_INDEX_C),
         axilReadSlave   => mAxiReadSlaves(PLLREGS_AXI_INDEX_C),
         axilWriteMaster => mAxiWriteMasters(PLLREGS_AXI_INDEX_C),
         axilWriteSlave  => mAxiWriteSlaves(PLLREGS_AXI_INDEX_C)
      );



end architecture ;