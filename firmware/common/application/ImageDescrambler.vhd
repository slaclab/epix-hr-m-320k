-------------------------------------------------------------------------------
-- File       : ImageDescrambler.vhd
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- This file is part of 'EPIX HR Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'EPIX HR Firmware', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiPkg.all;

entity ImageDescrambler is 
   generic (
      TPD_G           	   : time := 1 ns
   );
   port ( 

      axisClk           : in  sl;
      axisRst           : in  sl;

      sAxisMaster       : in  AxiStreamMasterType;
      sAxisSlave        : out AxiStreamSlaveType;

      mAxisMaster       : out AxiStreamMasterType;
      mAxisSlave        : in  AxiStreamSlaveType
      
   );
end ImageDescrambler;


-- Define architecture
architecture RTL of ImageDescrambler is

   -- makes the fifo input with 2B per stream
   constant AXI_STREAM_CONFIG_I_C : AxiStreamConfigType   := ssiAxiStreamConfig(2*24, TKEEP_COMP_C);
   constant framePixelRow : integer := 192;
   constant framePixelColumn : integer := 384;
   constant pixelsPerLanesRows : integer := 48;
   constant pixelsPerLanesColumns : integer := 64;
   constant numOfBanks : integer := 24;
   constant numOfDataCycles : integer := 3072;

   type Slv16BankMatrix is array (natural range<>, natural range<>, natural range<>) of slv(15 downto 0);
   type Slv16ImgFlat    is array (natural range<>) of slv(15 downto 0);

   
   signal descImgFlattened : Slv16ImgFlat (numOfBanks * pixelsPerLanesRows * pixelsPerLanesColumns - 1 downto 0);
  

   type StateType is (WAIT_SOF_S, DESCRAMBLE_S, HDR_S, DATA_S);
   
   type RegType is record
      state          : StateType;
      header         : slv(95 downto 0);
      dataCycleCntr  : integer;
      rowIndex       : integer;
      colIndex       : integer;
      even           : sl;
      txMaster       : AxiStreamMasterType;
      descImg        : Slv16BankMatrix (numOfBanks-1 downto 0, pixelsPerLanesRows-1 downto 0, pixelsPerLanesColumns-1 downto 0);
   end record;

   constant REG_INIT_C : RegType := (
      state          => WAIT_SOF_S,
      header         => (others => '0'),
      dataCycleCntr  => 0,
      rowIndex       => 0,
      colIndex       => 1,
      even           => '0',
      descImg        => (others => (others => (others => (others => '0')))),
      txMaster       => AXI_STREAM_MASTER_INIT_C
   );
   
   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   

begin

   
   -- Format bank matrix as follows
   --  3     7    11    15    19    23         
   --  2     6    10    14    18    22         
   --  1     5     9    13    17    21         
   --  0     4     8    12    16    20  

   matrixMerge : process (r.descImg) is
      variable counter : integer;
   begin
      counter := 0;
      for bankRows in 0 to 3 loop
         -- Generate all rows all adjacent banks
         for rowsInBank in 0 to pixelsPerLanesRows-1 loop
            -- Generate one complete row from all adjacent banks at a time
            for bankCols in 0 to 5 loop
               -- Generate a row from one bank
               for colsInBank in 0 to pixelsPerLanesColumns-1 loop
                  descImgFlattened(counter) <= r.descImg(bankCols*4 + bankRows, rowsInBank, colsInBank);
                  counter := counter + 1;
               end loop;
            end loop;
         end loop;
      end loop;
   end process;

   comb : process (sAxisMaster, r, mAxisSlave) is
      variable v        : RegType;
   begin
      v := r;
      
    
      -- Reset strobing Signals
      if (mAxisSlave.tReady = '1') then
         v.txMaster.tValid := '0';
         v.txMaster.tLast  := '0';
         v.txMaster.tUser  := (others => '0');
         v.txMaster.tKeep  := (others => '1');
         v.txMaster.tStrb  := (others => '1');
         v.txMaster.tData  := (others => '0');
      end if;
      
      case r.state is
                
         when WAIT_SOF_S =>
            v := REG_INIT_C;
            sAxisSlave.tReady <= '1';
            if (ssiGetUserSof(AXI_STREAM_CONFIG_I_C, sAxisMaster) = '1' and sAxisMaster.tValid = '1') then
               v.state := DESCRAMBLE_S;
               v.header := sAxisMaster.tData(95 downto 0);
            end if;
            
         when DESCRAMBLE_S =>
         -- https://confluence.slac.stanford.edu/download/attachments/392826236/image-2023-8-9_16-6-42.png?version=1&modificationDate=1691622403000&api=v2
            sAxisSlave.tReady <= '1';
            if sAxisMaster.tValid = '1' then

               v.dataCycleCntr := r.dataCycleCntr + 1;
               
               for i in 0 to 23 loop
                  v.descImg(i,r.rowIndex, r.colIndex) := sAxisMaster.tData(16*i+15 downto 16*i);
               end loop;
                  
               v.colIndex := r.colIndex + 2;
               if (r.colIndex >= pixelsPerLanesColumns-2) then
                  if (r.even = '1') then
                     v.colIndex := 0;
                  else
                     v.colIndex := 1;
                  end if;
                  v.rowIndex := r.rowIndex + 1;
                  if (r.rowIndex >= pixelsPerLanesRows - 1) then
                     v.rowIndex := 0;
                  end if;
               end if;
               if (r.colIndex = pixelsPerLanesColumns-1) and (r.rowIndex = pixelsPerLanesRows - 1) then
                  v.even := '1';
                  v.colIndex := 0;
               end if;               
               if (r.colIndex = pixelsPerLanesColumns-2) and (r.rowIndex = pixelsPerLanesRows - 1) then
                  v.state := HDR_S;
                  v.dataCycleCntr := 0;
               elsif ( sAxisMaster.tLast = '1' or ssiGetUserEofe(AXI_STREAM_CONFIG_I_C, sAxisMaster) = '1') then
               -- unanticipated finish. Send out full frame with what we received.
                  v.state := HDR_S;
                  v.dataCycleCntr := 0;
               end if;
            end if;
            
         when HDR_S =>
            if mAxisSlave.tReady = '1' then
               v.txMaster.tValid := '1';
               v.state := DATA_S;
               v.txMaster.tData(95 downto  0) := r.header;
               ssiSetUserSof(AXI_STREAM_CONFIG_I_C, v.txMaster, '1');
            end if;         

         when DATA_S =>
            if mAxisSlave.tReady = '1' then
               v.txMaster.tValid := '1';
               for i in 0 to 23 loop
                  v.txMaster.tData(16*i+15 downto  i*16) := descImgFlattened(i + 24*r.dataCycleCntr);
               end loop;
               v.dataCycleCntr := r.dataCycleCntr + 1;
               if (r.dataCycleCntr = 3071) then
                  v.state := WAIT_SOF_S;
                  v.txMaster.tLast := '1';
                  ssiSetUserEofe(AXI_STREAM_CONFIG_I_C, v.txMaster, '1');
               end if;
            end if;   
         when others => v.state := WAIT_SOF_S;              
      end case;

      if (axisRst = '1') then
         v := REG_INIT_C;
      end if;
      
      rin <= v;

   end process;

   seq : process (axisClk) is
   begin
      if (rising_edge(axisClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;
      

end RTL;
