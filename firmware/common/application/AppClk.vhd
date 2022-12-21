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
      -- AXI-Lite Register Interface (axiClk domain)
      axiReadMasters    : in  AxiLiteReadMasterType;
      axiReadSlaves      : out AxiLiteReadSlaveType;
      axiWriteMasters    : in  AxiLiteWriteMasterType;
      axiWriteSlaves     : out AxiLiteWriteSlaveType;
      axiClk            : in sl;
      axiRst            : in sl;

      -- Clock Inputs
      clkInP      : in sl;
      clkInM      : in sl;

      -- Clock Outputs
      -- Off Device
      fpgaRdClkP     : out sl;
      fpgaRdClkM     : out sl;
      fpgaToPllClkP  : out sl;
      fpgaToPllClkM  : out sl

      
   );
end entity ; -- AppClk

architecture rtl of AppClk is
   signal fabRefClk        : sl := '0';
   signal fabClock         : sl := '0';
   signal asicRefClk       : sl := '0';
   signal sysRst           : sl := '0';
   signal adcClk           : sl := '0';
   signal asicRegCtrl      : sl := '0';
   signal refRst           : sl := '0';
   signal adcRst           : sl := '0';
   signal appRst           : sl := '0';
   signal fpgaPllClk       : sl := '0';
   signal pllRst           : sl := '0';   

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
   
   U_fpgaToPllClk : entity surf.ClkOutBufDiff
      generic map(
         TPD_G        => TPD_G,
         XIL_DEVICE_G => XIL_DEVICE_C
      )
      port map (
         clkIn   => fpgaPllClk,
         clkOutP => fpgaToPllClkP,
         clkOutN => fpgaToPllClkM
      );
   
   U_fpgaToAsicRdClk : entity surf.ClkOutBufDiff
      generic map(
         TPD_G        => TPD_G,
         XIL_DEVICE_G => XIL_DEVICE_C
      )
      port map (
         clkIn   => asicRefClk,
         clkOutP => fpgaRdClkP,
         clkOutN => fpgaRdClkM
      );

   ------------------------------------------------
   --    Generate clocks from 156.25 MHz PGP     --
   ------------------------------------------------
   -- clkIn     : 156.25 MHz PGP
   -- base clk is 1000 MHz
   -- clkOut(0) : 160.00 MHz ASIC ref clock
   -- clkOut(1) : 50.00  MHz adc clock
   -- clkOut(2) : 100.00 MHz app clock
   -- clkOut(3) : 40.00 MHz pll Clk
   ------------------------------------------------
   U_CoreClockGen : entity surf.ClockManagerUltraScale
      generic map(
         TPD_G                  => 1 ns,
         TYPE_G                 => "MMCM",  -- or "PLL"
         INPUT_BUFG_G           => true,
         FB_BUFG_G              => true,
         RST_IN_POLARITY_G      => '1',     -- '0' for active low
         NUM_CLOCKS_G           => 4,
         SIMULATION_G           => SIMULATION_G,
         -- MMCM attributes
         BANDWIDTH_G            => "OPTIMIZED",
         CLKIN_PERIOD_G         => 6.4,      -- 156.25 MHz
         DIVCLK_DIVIDE_G        => 5,        -- 31.25 MHz = 156.25Mhz / 5
         CLKFBOUT_MULT_F_G      => 32.0,     -- 1.0 Ghz = 31.25 MHz * 32
         CLKFBOUT_MULT_G        => 5,
         CLKOUT0_DIVIDE_F_G     => 6.25,     -- 160 MHz = 1 GHz / 6.25
         CLKOUT0_DIVIDE_G       => 1,
         CLKOUT1_DIVIDE_G       => 20,       -- 50 Mhz = 1 GHz / 20
         CLKOUT2_DIVIDE_G       => 10,       -- 100 Mhz = 1 GHz / 10
         CLKOUT3_DIVIDE_G       => 25,       -- 40 Mhz = 1 GHz / 25
         CLKOUT0_PHASE_G        => 0.0,
         CLKOUT1_PHASE_G        => 0.0,
         CLKOUT2_PHASE_G        => 0.0,
         CLKOUT3_PHASE_G        => 0.0,
         CLKOUT0_DUTY_CYCLE_G   => 0.5,
         CLKOUT1_DUTY_CYCLE_G   => 0.5,
         CLKOUT2_DUTY_CYCLE_G   => 0.5,
         CLKOUT3_DUTY_CYCLE_G   => 0.5,
         CLKOUT0_RST_HOLD_G     => 3,
         CLKOUT1_RST_HOLD_G     => 3,
         CLKOUT2_RST_HOLD_G     => 3,
         CLKOUT3_RST_HOLD_G     => 3,
         CLKOUT0_RST_POLARITY_G => '1',
         CLKOUT1_RST_POLARITY_G => '1',
         CLKOUT2_RST_POLARITY_G => '1',
         CLKOUT3_RST_POLARITY_G => '1'
   )
      port map(
         clkIn           => fabClock,
         rstIn           => sysRst,
         clkOut(0)       => asicRefClk,
         clkOut(1)       => adcClk,
         clkOut(2)       => asicRegCtrl,
         clkOut(3)       => fpgaPllClk,
         rstOut(0)       => refRst,
         rstOut(1)       => adcRst,
         rstOut(2)       => appRst,
         rstOut(3)       => pllRst,
         locked          => open,
         -- AXI-Lite Interface
         axilClk         => axiClk,
         axilRst         => axiRst,
         axilReadMaster  => axiReadMasters,
         axilReadSlave   => axiReadSlaves,
         axilWriteMaster => axiWriteMasters,
         axilWriteSlave  => axiWriteSlaves
   );






end architecture ;