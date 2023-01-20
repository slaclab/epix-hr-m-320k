
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

entity AppDeser is
   generic (
      TPD_G            : time    := 1 ns;
      SIMULATION_G     : boolean := false;
      AXIL_BASE_ADDR_G : slv(31 downto 0)
   );
   port(
      -- AXI-Lite Interface (axilClk domain)
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- ASIC Ports
      asicDataP       : in    Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
      asicDataM       : in    Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);

      -- SSP Interfaces (sspClk domain)
      clk250          : in sl;
      sspClk          : in  sl;
      sspRst          : in  sl;

      -- Ssp data outputs
      sspLinkUp       : out Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
      sspValid        : out Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
      sspData         : out Slv16Array((NUMBER_OF_ASICS_C * 24)-1 downto 0);
      sspSof          : out Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
      sspEof          : out Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0);
      sspEofe         : out Slv24Array(NUMBER_OF_ASICS_C - 1 downto 0)
   );
end AppDeser;


architecture mapping of AppDeser is
  
   constant XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUMBER_OF_ASICS_C-1 downto 0) := genAxiLiteConfig(NUMBER_OF_ASICS_C, AXIL_BASE_ADDR_G, 16, 12);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUMBER_OF_ASICS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUMBER_OF_ASICS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_SLVERR_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUMBER_OF_ASICS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUMBER_OF_ASICS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_SLVERR_C);
   signal sspReset         : slv(NUMBER_OF_ASICS_C-1 downto 0);
begin

   ---------------------------
   -- AXI-Lite Crossbar Module
   ---------------------------
   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUMBER_OF_ASICS_C,
         MASTERS_CONFIG_G   => XBAR_CONFIG_C
      )
      port map (
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves,
         axiClk              => axilClk,
         axiClkRst           => axilRst
      );

   U_ASICS : for i in NUMBER_OF_ASICS_C - 1 downto 0 generate 
      U_Deser_Group : entity work.AppDeserGroup
         generic map (
            TPD_G          => TPD_G,
            SIMULATION_G   => SIMULATION_G
         )
         port map (
            -- AXI-Lite Interface (axilClk domain)
            axilClk          => axilClk,
            axilRst          => axilRst,
            axilReadMaster   => axilReadMasters(i),
            axilReadSlave    => axilReadSlaves(i),
            axilWriteMaster  => axilWriteMasters(i),
            axilWriteSlave   => axilWriteSlaves(i),
            
            -- Asic Ports
            asicDataP        => asicDataP(i),
            asicDataM        => asicDataM(i),

            clk250           => clk250,
            sspClk           => sspClk,
            sspRst           => sspReset(i),

            sspLinkUp         => sspLinkUp(i),
            sspValid          => sspValid(i),
            sspData           => sspData(24*i+23 downto 24*i),
            sspSof            => sspSof(i),
            sspEof            => sspEof(i),
            sspEofe           => sspEofe(i)
         );

      U_reset80 : entity surf.RstPipeline
         generic map (
            TPD_G => TPD_G
         )
         port map (
            clk    => sspClk,
            rstIn  => sspRst,
            rstOut => sspReset(i)
         );

   end generate;

 end architecture;