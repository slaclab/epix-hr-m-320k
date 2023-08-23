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
        -- ASIC[X]_R0_CLK_M input
        -- ASIC[X]_R0_CLK_P
        -- VCAL_P
        -- DET_BIAS
        -- VGUARD : reference voltage to asic -- input
        -- DS_PLL
        -- ADC_MON_VIN_P : Going to high speed monitor (ADC) in analog board
        -- ADC_MON_VIN_M : Going to high speed monitor (ADC) in analog board
        -- ADC_MON_VCOM  : Going to high speed monitor (ADC) in analog board
          -- 

      asicR0Clk       : in    sl;               -- ASIC[X]_R0_CLK

      saciClk         : in    sl;               -- ASIC_SACI_CLK
      saciCmd         : in    sl;               -- ASIC_SACI_CMD 
      saciSel         : in    slv(3 downto 0);  -- ASIC[X]_SACI_SEL
      saciResp        : out   sl;               -- ASIC_[0123]_SACI_RESP

      asicDataP       : out   slv(23 downto 0); -- D_DATA_P[5:0]
      asicDataN       : out   slv(23 downto 0); -- D_DATA_M[5:0]

      asicDm          : out    slv(1 downto 0); -- DIGMON_1 , DIGMON_2
      asicGr          : in    sl; -- ASIC_GR
      asicR0          : in    sl; -- ASIC_R0
      asicAcq         : in    sl; -- ASIC_ACQ
      asicSync        : in    sl; -- ASIC_SYNC
      asicSro         : in    sl; -- ASIC_SR0
      asicClkSyncEn   : in    sl  -- ASIC_CLK_SYNC_ENA

      );
end ePixHRM320kModel;

-------------------------------------------------------------------------------

architecture arch of ePixHRM320kModel is

    --file definitions
    constant DATA_BITS   : natural := 16;
    constant DEPTH_C     : natural := 1024;
    --simulation constants to select data type
    constant CH_ID       : natural := 0;
    constant CH_WF       : natural := 1;
    constant DATA_TYPE_C : natural := CH_ID;

    signal serData2_20b : slv(19 downto 0);
    signal serData2_10b : slv( 9 downto 0);
    signal serialDataOut2  : sl;
    signal serialDataOut2d : slv(39 downto 0) := (others => '0');

    -- Encoder
    signal EncValidIn  : sl              := '1';
    signal EncReadyIn  : sl;
    signal EncDataIn   : slv(15 downto 0);
    signal EncDispIn   : slv(1 downto 0) := "00";
    signal EncValidOut : sl;
    signal EncReadyOut : sl              := '1';
    signal EncDataOut  : slv(19 downto 0);
    signal EncDataOutRev  : slv(19 downto 0);
    signal EncDataOut_d: Slv20Array(7 downto 0) := (others => (others => '0'));
    signal EncSof      : sl := '0';
    signal EncEof      : sl := '0';

    signal chId           : slv(15 downto 0);
    
    -- Normalize ASIC spec mistake
    signal asicReset_n    :  sl;
    signal asicReset      :  sl;

    -- internal clocks
    signal dClkP     :  sl;
    signal fClkP     :  sl;
    signal dClkP2x   :  sl;
    
    begin
    -- SACI inputs left dangling
    saciResp <= '0';

    EncDataOutRev <= bitReverse(EncDataOut);
    
    -- asicGr is an active low signal despite not having it in the name
    asicReset_n      <= asicGr;
    asicReset        <= not asicGr;

    -------------------------------------------------------------------------------
--  Starts transmitting data in the righ clock transition
-------------------------------------------------------------------------------  
  EncValid_Proc: process  
  variable counter : integer := 0;
  begin
    wait until fClkP = '1';
    if (asicSro = '1') then
      EncReadyOut <= '1'; 
      EncValidIn  <= '1';
      if (counter = 0) then
        EncSof <= '1';
      else
        EncSof <= '0';
      end if;  
      if (EncReadyIn = '1') then
        counter := counter + 1;
      end if;
      if counter = 3074 then
        EncValidIn  <= '0';
        EncReadyOut <= '0'; 
        EncEof <= '1';
      end if; 
    else 
      counter := 0;
      EncEof <= '0';
      EncSof <= '0';
      EncReadyOut <= '0'; 
      EncValidIn  <= '0';      
    end if; 

  end process;  


    U_encoder : entity surf.SspEncoder8b10b 
    generic map (
      TPD_G          => TPD_G,
      RST_POLARITY_G => '1',
      RST_ASYNC_G    => false,
      AUTO_FRAME_G   => true,
      FLOW_CTRL_EN_G => false)
    port map(
       clk      => fClkP,
       rst      => asicReset,
       validIn  => EncValidIn,
       readyIn  => EncReadyIn,
       sof      => EncSof,
       eof      => EncEof,
       dataIn   => EncDataIn,
       validOut => EncValidOut,
       readyOut => EncReadyOut,
       dataOut  => EncDataOut);

-------------------------------------------------------------------------------
--  simulation process for channel ID. Counter from 0 to 31
-------------------------------------------------------------------------------  
chId_Proc: process
variable chIdCounter : integer := 0;
begin
wait until fClkP = '1';
if asicSro = '1' then
  chIdCounter := ChIdCounter + 1;
  if chIdCounter = 32 then
    chIdCounter := 0;
  end if;
else
  chIdCounter := 0;
end if;
chId(15 downto 1) <= toSlv(chIdCounter, 15);
chId(0) <= '0';

end process;  


    EncDataIn_Proc: process
    variable dataIndex : integer := 0;
  begin
    wait until fClkP = '1';
    if asicSro = '1' then
      if DATA_TYPE_C = CH_ID then
        EncDataIn <= chId;
      end if;
      dataIndex := dataIndex + 1;
      if dataIndex = DEPTH_C then
        dataIndex := 0;
      end if;
    else
      EncDataIn <= IDLE_PATTERN_C;
    end if;
    EncDataOut_d(0) <= EncDataOutRev;
    for i in 1 to 7 loop
      EncDataOut_d(i) <= EncDataOut_d(i-1);
    end loop;
  end process;

    serData2_20b <= EncDataOut_d(7);
    serData2_10b <= serData2_20b(19 downto 10) when fClkP = '1' else serData2_20b(9 downto 0);

    U_serializer2 :  entity work.serializerSim 
    generic map(
      TPD_G    => 0ns,
      g_dwidth => 10 
    )
    port map(
        clk_i     => dClkP,
        reset_n_i => asicReset_n,
        data_i    => serData2_10b,
        data_o    => serialDataOut2
    );

    -- Not used
    DelaySerialData_Proc: process 
    begin
      wait until dClkP2x = '1';
      serialDataOut2d(0) <= serialDataOut2;
      for i in 1 to 39 loop
        serialDataOut2d(i) <= serialDataOut2d(i-1);
      end loop;
    end process;    

    asicDataWiring:  process(serialDataOut2d(0))
    variable i       : natural;
    variable retVarP : std_logic_vector(24-1 downto 0);
    variable retVarN : std_logic_vector(24-1 downto 0);
    begin
        for i in 0 to 24-1 loop
          retVarP(i) := serialDataOut2d(0);
          retVarN(i) := not serialDataOut2d(0);
        end loop;
        asicDataP <= retVarP;
        asicDataN <= retVarN;
    end process;        


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

