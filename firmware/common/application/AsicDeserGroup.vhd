
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

entity AsicDeserGroup is
   generic (
       TPD_G            : time    := 1 ns;
       SIMULATION_G     : boolean := false;
       NUM_OF_LANES_G   : integer := 24
   );
   port (
      -- AXI-Lite Interface (axilClk domain)
      axilClk           : in  sl;
      axilRst           : in  sl;
      axilReadMaster    : in  AxiLiteReadMasterType;
      axilReadSlave     : out AxiLiteReadSlaveType;
      axilWriteMaster   : in  AxiLiteWriteMasterType;
      axilWriteSlave    : out AxiLiteWriteSlaveType;

      -- Asic Ports
      asicDataP         : in  slv(23 downto 0);
      asicDataM         : in  slv(23 downto 0);

      -- Ref Clocks MMCM Out (0)
      refClk            : in sl;
      refRst            : in sl;

      -- Selectio Deser pll clk to ASIC
      asicRdClk         : out sl;

      -- ssp outputs
      rxLinkUp          : out slv(NUM_OF_LANES_G - 1 downto 0);
      rxValid           : out slv(NUM_OF_LANES_G - 1 downto 0);
      rxData            : out Slv16Array(NUM_OF_LANES_G - 1 downto 0);
      rxSof             : out slv(NUM_OF_LANES_G - 1 downto 0);
      rxEof             : out slv(NUM_OF_LANES_G - 1 downto 0);
      rxEofe            : out slv(NUM_OF_LANES_G - 1 downto 0)

   );
end entity AsicDeserGroup;

architecture mapping of AsicDeserGroup is
   
    signal deserClk        : sl;
    signal deserRst        : sl;
    signal deserData       : Slv8Array(23 downto 0);
    signal dlyLoad         : slv(23 downto 0);
    signal dlyCfg          : Slv9Array(23 downto 0);

begin
    
   -------------------------------------------------------
   -- ASIC Deserializers
   -------------------------------------------------------
   U_Deser : entity surf.SelectioDeserUltraScale
      generic map(
         TPD_G            => TPD_G,
         SIMULATION_G     => SIMULATION_G,
         NUM_LANE_G       => 24,
         CLKIN_PERIOD_G   => 6.25,  -- 160 MHz
         DIVCLK_DIVIDE_G  => 1,
         CLKFBOUT_MULT_G  => 4,     -- 640 MHz = 160 MHz x 4 / 1
         CLKOUT0_DIVIDE_G => 2      -- 320 MHz = 640 MHz/2
      )
      port map (
         -- SELECTIO Ports
         rxP             => asicDataP,
         rxN             => asicDataM,
         pllClk          => asicRdClk,
         -- Reference Clock and Reset
         refClk          => refClk,
         refRst          => refRst,
         -- Deserialization Interface (deserClk domain)
         deserClk        => deserClk,
         deserRst        => deserRst,
         deserData       => deserData,
         dlyLoad         => dlyLoad,
         dlyCfg          => dlyCfg,
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave
      );

   -------------------------------------------------------
   -- ASIC Gearboxes and SSP decoders
   -------------------------------------------------------
   U_SspDecoder : entity surf.SspLowSpeedDecoder8b10bWrapper
      generic map (
         TPD_G            => TPD_G,
         SIMULATION_G     => SIMULATION_G,
         NUM_LANE_G       => 24
      )
      port map (
         -- Deserialization Interface (deserClk domain)
         deserClk        => deserClk,
         deserRst        => deserRst,
         deserData       => deserData,
         dlyLoad         => dlyLoad,
         dlyCfg          => dlyCfg,
         -- SSP Frame Output
         rxLinkUp        => rxLinkUp,
         rxValid         => rxValid,
         rxData          => rxData,
         rxSof           => rxSof,
         rxEof           => rxEof,
         rxEofe          => rxEofe,
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave
      );

end architecture;