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

entity ePixHRM320kLaneModel is
     generic (
      TPD_G        : time := 1 ns;
      IDLE_PATTERN_C : slv(15 downto 0) := x"00FF";
      LANE_INDEX : slv(15 downto 0) := x"0000"
      );
      port (

      dClkP           : in    sl; 
      fClkP           : in    sl; 
      dClkP2x         : in    sl; 

      asicDataP       : out   sl; -- D_DATA_P[5:0]
      asicDataN       : out   sl; -- D_DATA_M[5:0]

      asicGr          : in    sl; -- ASIC_GR
      asicSro         : in    sl -- ASIC_SR0

      );
end ePixHRM320kLaneModel;

-------------------------------------------------------------------------------

architecture arch of ePixHRM320kLaneModel is

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
    signal serialDataOut2d : sl := '0';

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
    
    begin

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
    chId <= LANE_INDEX;

    EncDataIn_Proc: process
  begin
    wait until fClkP = '1';
    if asicSro = '1' then
      EncDataIn <= LANE_INDEX;
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
      serialDataOut2d <= serialDataOut2;
    end process;    


    asicDataP <= serialDataOut2d;
    asicDataN <= not serialDataOut2d;

end arch;

