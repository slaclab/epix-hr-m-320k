library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.AppPkg.all;

entity AppClk is
   generic (
     TPD_G        : time    := 1 ns;
     SIMULATION_G : boolean := false
   );
   port (
      -- 156.25 MHz Clock input
      gtRefClkP     : in sl;
      gtRefClkM     : in sl;

      -- 250 Mhz Pll Output
      gtPllClkP     : in sl;
      gtPllClkM     : in sl;

      -- 40 Mhz clock output to pll(2)
      fpgaClkOutP   : out sl;
      fpgaClkOutM   : out sl;
      
      -- fpga generated asic rdout clk, 
      -- Ctrl is in registerControl.vhd
      fpgaRdClkP    : out sl;
      fpgaRdClkM    : out sl;

      -- logic Clocks
      clk156        : out sl;
      rst156        : out sl;
      clk250        : out sl;
      rst250        : out sl;
      sspClk        : out sl;
      sspRst        : out sl;

      jitclnLolL    : in sl
      
   );
end entity AppClk;

architecture rtl of AppClk is
   signal fabRefClk        : sl;
   signal fabClock         : sl;
   signal fabReset         : sl;
   signal fpgaToPllClk     : sl;
   signal pllToFpgaClk     : sl;
   signal clk62p5            : sl;
   signal rst62p5            : sl;
   signal iClk250          : sl;
   signal adcClk           : sl;

begin

   sspClk <= clk62p5;
   clk156 <= fabClock;
   rst156 <= fabReset;
   rst250 <= rst62p5;
   clk250 <= iClk250;

   U_IBUFDS_GT : IBUFDS_GTE4
      generic map (
         REFCLK_EN_TX_PATH  => '0',
         REFCLK_HROW_CK_SEL => "00",  -- 2'b00: ODIV2 = O
         REFCLK_ICNTL_RX    => "00"
      )
      port map (
         I     => gtRefClkP,
         IB    => gtRefClkM,
         CEB   => '0',
         ODIV2 => open,
         O     => fabRefClk
      );

   U_BUFG_GT : BUFG_GT
      port map (
        I       => fabRefClk,
        CE      => '1',
        CEMASK  => '1',
        CLR     => '0',
        CLRMASK => '1',
        DIV     => "000",              -- Divide by 1
        O       => fabClock
      );
      
    U_PwrUpRst : entity surf.PwrUpRst
      generic map(
         TPD_G         => TPD_G,
         SIM_SPEEDUP_G => SIMULATION_G)
      port map(
         clk    => fabClock,
         rstOut => fabReset
      );

   ------------------------------------------------
   --    Generate clocks from 156.25 MHz PGP     --
   ------------------------------------------------
   -- clkIn     : 156.25 MHz PGP
   -- base clk is 1.2500 GHz
   -- clkOut(0) : 50.00 MHz Pll Clk output
   ------------------------------------------------
   U_CoreClockGen : entity surf.ClockManagerUltraScale
     generic map(
        TPD_G                  => TPD_G,
        TYPE_G                 => "MMCM",  -- or "PLL"
        INPUT_BUFG_G           => false,
        FB_BUFG_G              => true,
        RST_IN_POLARITY_G      => '1',     -- '0' for active low
        NUM_CLOCKS_G           => 1,
        SIMULATION_G           => SIMULATION_G,
        -- MMCM attributes
        BANDWIDTH_G            => "OPTIMIZED",
        CLKIN_PERIOD_G         => 6.4,      -- 156.25 MHz
        CLKFBOUT_MULT_F_G      => 8.0,      -- 1.25 Ghz = 31.25 MHz * 32
        CLKOUT0_DIVIDE_F_G     => 25.0      -- 40 MHz = 1.25 GHz / 25
     )
     port map(
        clkIn           => fabClock,
        rstIn           => fabReset,
        clkOut(0)       => fpgaToPllClk
     );
  
   U_fpgaToPllClk : entity surf.ClkOutBufDiff
      generic map(
         TPD_G        => TPD_G,
         XIL_DEVICE_G => XIL_DEVICE_C
         )
      port map (
         clkIn   => fpgaToPllClk,
         clkOutP => fpgaClkOutP,
         clkOutN => fpgaClkOutM
         );
   
   U_fpgaRdClk : entity surf.ClkOutBufDiff
      generic map(
         TPD_G        => TPD_G,
         XIL_DEVICE_G => XIL_DEVICE_C
         )
      port map (
         clkIn   => iClk250,
         clkOutP => fpgaRdClkP,
         clkOutN => fpgaRdClkM
         );
   
   U_IBUFDS : IBUFDS
      port map (
         I  => gtPllClkP,
         IB => gtPllClkM,
         O  => pllToFpgaClk
      );
   
   U_clk250 : BUFG
      port map (
         I => pllToFpgaClk,
         O => iClk250
      );
   
   U_clk62p5 : BUFGCE_DIV
      generic map (
         BUFGCE_DIVIDE => 4
      )
      port map (
         I   => iClk250,
         CE  => '1',
         CLR => '0',
         O   => clk62p5
      );
   
   U_rst62p5 : entity surf.RstSync
      generic map (
         TPD_G          => TPD_G,
         IN_POLARITY_G  => '0',         -- active LOW
         OUT_POLARITY_G => '1'
      )
      port map (
         clk      => clk62p5,
         asyncRst => jitclnLolL,
         syncRst  => rst62p5
      );
   
   U_sspRst : entity surf.RstPipeline
      generic map (
         TPD_G => TPD_G
      )
      port map (
         clk    => clk62p5,
         rstIn  => rst62p5,
         rstOut => sspRst
      );


end architecture;