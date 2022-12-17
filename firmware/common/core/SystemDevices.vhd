-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: RX PHY Core module
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.I2cPkg.all;

library work;
use work.CorePkg.all;

library unisim;
use unisim.vcomponents.all;

entity SystemDevices is
   generic (
      TPD_G            : time             := 1 ns;
      SIMULATION_G     : boolean          := false;
      BUILD_INFO_G     : BuildInfoType;
      AXIL_BASE_ADDR_G : slv(31 downto 0) := (others => '0'));
   port (
      -- AXI-Lite Interface
      axilClk         : in    sl;
      axilRst         : in    sl;
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;
      --------------------------------------
      --          Top Level Ports
      --------------------------------------
      -- Jitter Cleaner PLL Ports
      jitclnrCsL     : out   sl;
      jitclnrIntr    : in    sl;
      jitclnrLolL    : in    sl;
      jitclnrOeL     : out   sl;
      jitclnrRstL    : out   sl;
      jitclnrSclk    : out   sl;
      jitclnrSdio    : out   sl;
      jitclnrSdo     : in    sl;
      jitclnrSel     : out slv(1 downto 0) := "00";

      -- LMK61E2
      pllClkScl       : inout sl;
      pllClkSda       : inout sl;

      -- LEAP Transceiver Ports
      obTransScl     : inout  sl;
      obTransSda     : inout  sl;
      obTransResetL  : out sl;
      obTransIntL    : in sl;

      -- SYSMON Ports
      vPIn            : in    sl;
      vNIn            : in    sl);
end SystemDevices;

architecture mapping of SystemDevices is

   constant PLL_I2C_CONFIG_C : I2cAxiLiteDevArray(0 downto 0) := (
         0           => MakeI2cAxiLiteDevType(
         i2cAddress  => "1011000",      -- LMK61E2
         dataSize    => 8,              -- in units of bits
         addrSize    => 8,              -- in units of bits
         endianness  => '0',            -- Little endian
         repeatStart => '1'));          -- Repeat Start

   constant VERSION_INDEX_C    : natural  := 0;
   constant SYSMON_INDEX_C     : natural  := 1;
   constant BOOT_MEM_INDEX_C   : natural  := 2;
   constant LEAP_XCVR_INDEX_C  : natural  := 3;
   constant PLL_SPI_INDEX_C    : natural  := 4;
   constant PLL_I2C_INDEX_C    : natural  := 5;
   constant NUM_AXIL_MASTERS_C : positive := 6;

   constant XBAR_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXIL_MASTERS_C, AXIL_BASE_ADDR_G, 20, 16);

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0) := (others => AXI_LITE_WRITE_SLAVE_EMPTY_SLVERR_C);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXIL_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXIL_MASTERS_C-1 downto 0)  := (others => AXI_LITE_READ_SLAVE_EMPTY_SLVERR_C);

   signal axilRstL : sl;
   signal bootCsL  : sl;
   signal bootSck  : sl;
   signal bootMosi : sl;
   signal bootMiso : sl;
   signal di       : slv(3 downto 0);
   signal do       : slv(3 downto 0);

begin

   U_XBAR : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
         MASTERS_CONFIG_G   => XBAR_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   ----------------------------------------------------
   --          AXI-Lite Version Module
   ----------------------------------------------------
   U_AxiVersion : entity surf.AxiVersion
      generic map (
         TPD_G           => TPD_G,
         BUILD_INFO_G    => BUILD_INFO_G,
         CLK_PERIOD_G    => AXIL_CLK_PERIOD_C,
         XIL_DEVICE_G    => XIL_DEVICE_C,
         USE_SLOWCLK_G   => true,
         EN_DEVICE_DNA_G => true,
         EN_ICAP_G       => true)
      port map (
         slowClk        => axilClk,
         -- AXI-Lite Interface
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => axilReadMasters(VERSION_INDEX_C),
         axiReadSlave   => axilReadSlaves(VERSION_INDEX_C),
         axiWriteMaster => axilWriteMasters(VERSION_INDEX_C),
         axiWriteSlave  => axilWriteSlaves(VERSION_INDEX_C));

   NOT_SIM : if (SIMULATION_G = false) generate

      U_SysMon : entity work.SysMonWrapper
         generic map (
            TPD_G => TPD_G)
         port map (
            -- SYSMON Ports
            vPIn            => vPIn,
            vNIn            => vNIn,
            -- AXI-Lite Register Interface
            axilReadMaster  => axilReadMasters(SYSMON_INDEX_C),
            axilReadSlave   => axilReadSlaves(SYSMON_INDEX_C),
            axilWriteMaster => axilWriteMasters(SYSMON_INDEX_C),
            axilWriteSlave  => axilWriteSlaves(SYSMON_INDEX_C),
            -- Clocks and Resets
            axilClk         => axilClk,
            axilRst         => axilRst);

      U_BootProm : entity surf.AxiMicronN25QCore
         generic map (
            TPD_G          => TPD_G,
            AXI_CLK_FREQ_G => AXIL_CLK_FREQ_C,        -- units of Hz
            SPI_CLK_FREQ_G => (AXIL_CLK_FREQ_C/4.0))  -- units of Hz
         port map (
            -- FLASH Memory Ports
            csL            => bootCsL,
            sck            => bootSck,
            mosi           => bootMosi,
            miso           => bootMiso,
            -- AXI-Lite Register Interface
            axiReadMaster  => axilReadMasters(BOOT_MEM_INDEX_C),
            axiReadSlave   => axilReadSlaves(BOOT_MEM_INDEX_C),
            axiWriteMaster => axilWriteMasters(BOOT_MEM_INDEX_C),
            axiWriteSlave  => axilWriteSlaves(BOOT_MEM_INDEX_C),
            -- Clocks and Resets
            axiClk         => axilClk,
            axiRst         => axilRst);

      U_STARTUPE3 : STARTUPE3
         generic map (
            PROG_USR      => "FALSE",  -- Activate program event security feature. Requires encrypted bitstreams.
            SIM_CCLK_FREQ => 0.0)      -- Set the Configuration Clock Frequency(ns) for simulation
         port map (
            CFGCLK    => open,         -- 1-bit output: Configuration main clock output
            CFGMCLK   => open,         -- 1-bit output: Configuration internal oscillator clock output
            DI        => di,           -- 4-bit output: Allow receiving on the D[3:0] input pins
            EOS       => open,         -- 1-bit output: Active high output signal indicating the End Of Startup.
            PREQ      => open,         -- 1-bit output: PROGRAM request to fabric output
            DO        => do,           -- 4-bit input: Allows control of the D[3:0] pin outputs
            DTS       => "1110",       -- 4-bit input: Allows tristate of the D[3:0] pins
            FCSBO     => bootCsL,      -- 1-bit input: Contols the FCS_B pin for flash access
            FCSBTS    => '0',          -- 1-bit input: Tristate the FCS_B pin
            GSR       => '0',          -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
            GTS       => '0',          -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
            KEYCLEARB => '0',          -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
            PACK      => '0',          -- 1-bit input: PROGRAM acknowledge input
            USRCCLKO  => bootSck,      -- 1-bit input: User CCLK input
            USRCCLKTS => '0',          -- 1-bit input: User CCLK 3-state enable input
            USRDONEO  => axilRstL,     -- 1-bit input: User DONE pin output control
            USRDONETS => '0');         -- 1-bit input: User DONE 3-state enable output

      axilRstL <= not(axilRst);  -- IPMC uses DONE to determine if FPGA is ready
      do       <= "111" & bootMosi;
      bootMiso <= di(1);

      U_LeapXcvr : entity surf.LeapXcvr
         generic map (
            TPD_G           => TPD_G,
            AXIL_CLK_FREQ_G => AXIL_CLK_FREQ_C)
         port map (
            -- I2C Ports
            scl             => obTransScl,
            sda             => obTransSda,
            -- Optional I/O Ports
            intL            => obTransIntL,
            rstL            => obTransResetL,
            -- AXI-Lite Register Interface
            axilReadMaster  => axilReadMasters(LEAP_XCVR_INDEX_C),
            axilReadSlave   => axilReadSlaves(LEAP_XCVR_INDEX_C),
            axilWriteMaster => axilWriteMasters(LEAP_XCVR_INDEX_C),
            axilWriteSlave  => axilWriteSlaves(LEAP_XCVR_INDEX_C),
            -- Clocks and Resets
            axilClk         => axilClk,
            axilRst         => axilRst);

      U_PLL_SPI : entity surf.Si5345
         generic map (
            TPD_G              => TPD_G,
            MEMORY_INIT_FILE_G => "ePix320kMPllConfig.mem",
            CLK_PERIOD_G       => AXIL_CLK_PERIOD_C,
            SPI_SCLK_PERIOD_G  => (1/10.0E+6))  -- 1/(10 MHz SCLK)
         port map (
            -- AXI-Lite Register Interface
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => axilReadMasters(PLL_SPI_INDEX_C),
            axiReadSlave   => axilReadSlaves(PLL_SPI_INDEX_C),
            axiWriteMaster => axilWriteMasters(PLL_SPI_INDEX_C),
            axiWriteSlave  => axilWriteSlaves(PLL_SPI_INDEX_C),
            -- SPI Ports
            coreSclk       => jitclnrSclk,
            coreSDin       => jitclnrSdo,
            coreSDout      => jitclnrSdio,
            coreCsb        => jitclnrCsL);

      U_PLL_I2C : entity surf.AxiI2cRegMaster
         generic map (
            TPD_G          => TPD_G,
            I2C_SCL_FREQ_G => 400.0E+3,  -- units of Hz
            DEVICE_MAP_G   => PLL_I2C_CONFIG_C,
            AXI_CLK_FREQ_G => AXIL_CLK_FREQ_C)
         port map (
            -- I2C Ports
            scl            => pllClkScl,
            sda            => pllClkSda,
            -- AXI-Lite Register Interface
            axiReadMaster  => axilReadMasters(PLL_I2C_INDEX_C),
            axiReadSlave   => axilReadSlaves(PLL_I2C_INDEX_C),
            axiWriteMaster => axilWriteMasters(PLL_I2C_INDEX_C),
            axiWriteSlave  => axilWriteSlaves(PLL_I2C_INDEX_C),
            -- Clocks and Resets
            axiClk         => axilClk,
            axiRst         => axilRst);

   end generate;

end mapping;
