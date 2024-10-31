-------------------------------------------------------------------------------
-- File       : DelayDetermination.vhd
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use IEEE.numeric_std.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.SsiPkg.all;

entity DelayDetermination is 
   generic (
      TPD_G           	   : time := 1 ns
   );
   port ( 
     
      
      -- AXI lite slave port for register access
      axilClk           : in  sl;
      axilRst           : in  sl;

      mAxilWriteMaster  : out  AxiLiteWriteMasterType;
      mAxilWriteSlave   : in   AxiLiteWriteSlaveType;
      mAxilReadMaster   : out  AxiLiteReadMasterType;
      mAxilReadSlave    : in   AxiLiteReadSlaveType;
      
      start            : in  sl;
      stop             : in  sl;
      enable           : in  sl;
      increment        : in  slv(8 downto 0);
      readyForTrig     : out sl;
      readyForTrigAck  : in  sl
      
   );
end DelayDetermination;


-- Define architecture
architecture RTL of DelayDetermination is

   type StateType is (WAIT_START_S, ENDLYCFG_S, SETDLY_S, CNTRST_S, READ_ERRDETCNT_S, READY4TRIG_S);

   type RegAccessStateType is ( READ_S, READ_ACK_WAIT_S, WRITE_S, WRITE_ACK_WAIT_S, WAIT_WRITE_DONE_S);


   type RegType is record
      state                       : StateType;
      regAccessState              : RegAccessStateType;
      req                         : AxiLiteReqType;
      regIndex                    : slv(4 downto 0);
      failingRegister             : slv(31 downto 0);
      usrDelayCfg                 : slv(31 downto 0);
      readValue                   : slv(31 downto 0);
      readyForTrig                : sl;

   end record;

   constant REG_INIT_C : RegType := (
      state                       => WAIT_START_S,
      regAccessState              => READ_S,
      req                         => AXI_LITE_REQ_INIT_C,
      regIndex                    => (others => '0'),
      failingRegister             => (others => '0'),
      usrDelayCfg                 => (others => '0'),
      readValue                   => (others => '0'),
      readyForTrig                => '0'
   );
   
   
   signal ack : AxiLiteAckType;

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType := REG_INIT_C;

   type registerAddressOffsetType is array (0 to 23) of slv(31 downto 0);
   constant detErrCntAddresses : registerAddressOffsetType := 
         (x"000000C0", x"000000C4", x"000000C8", x"000000CC",
          x"000000D0", x"000000D4", x"000000D8", x"000000DC",
          x"000000E0", x"000000E4", x"000000E8", x"000000EC",
          x"000000F0", x"000000F4", x"000000F8", x"000000FC",
          x"00000100", x"00000104", x"00000108", x"0000010C",
          x"00000110", x"00000114", x"00000118", x"0000011C");

   constant cntRstAddress    : slv(31 downto 0) := x"00000FFC";
   constant enDlyCfgAddress  : slv(31 downto 0) := x"00000800";

   constant usrDlyCfgAddress : registerAddressOffsetType := 
         (x"00000500", x"00000504", x"00000508", x"0000050C",
          x"00000510", x"00000514", x"00000518", x"0000051C",
          x"00000520", x"00000524", x"00000528", x"0000052C",
          x"00000530", x"00000534", x"00000538", x"0000053C",
          x"00000540", x"00000544", x"00000548", x"0000054C",
          x"00000550", x"00000554", x"00000558", x"0000055C");

   procedure axiLRead(
         address : in slv(31 downto 0);
         r       : in RegType;
         v       : inout RegType;
         ack     : in AxiLiteAckType
      ) is
   begin

      case r.regAccessState is
         when READ_S =>
            if (ack.done = '0') then
               v.req.address  := address; 
               v.req.rnw := '1'; -- READ
               v.req.request := '1'; -- initiate request
               v.regAccessState := READ_ACK_WAIT_S;
            end if;
         when READ_ACK_WAIT_S =>
            if (ack.done = '1') then
               if (ack.resp /= AXI_RESP_OK_C) then
                  v.failingRegister := address;
               end if;
               v.req.request := '0';
               v.regAccessState := READ_S;
            end if;

         when others =>
         -- do nothing
       end case;    
   end procedure;

   procedure axiLWrite(
         address : in slv(31 downto 0);
         wrData  : in slv(31 downto 0);
         r       : in RegType;
         v       : inout RegType;
         ack     : in AxiLiteAckType
      ) is
   begin

      case r.regAccessState is
         when WRITE_S =>
            if (ack.done = '0') then
               v.req.address  := address;
               v.req.rnw := '0'; -- WRITE
               v.req.wrData := wrData; 
               v.req.request := '1'; -- initiate request
               v.regAccessState := WRITE_ACK_WAIT_S; 
            end if;              
         when WRITE_ACK_WAIT_S =>
            if (ack.done = '1') then
               if (ack.resp /= AXI_RESP_OK_C) then
                  v.failingRegister := address;
               end if; 
               v.regAccessState := WRITE_S; 
               v.req.request := '0';    
            end if;  
         when others =>
         -- do nothing              
      end case;    
   end procedure;

   function checkError(
      r       : in RegType;
      ack     : in AxiLiteAckType
   ) return boolean is variable checkError : boolean;
   begin
      if (ack.done = '1' and (r.regAccessState = WRITE_ACK_WAIT_S or r.regAccessState = READ_ACK_WAIT_S) and ack.resp /= AXI_RESP_OK_C) then
         return True;
      else
         return False;
      end if;
   end function;

   function axiLEndOfWrite(
         r       : in RegType;
         ack     : in AxiLiteAckType
      ) return boolean is variable endOfWrite : boolean;
   begin
      if (ack.done = '1' and r.regAccessState = WRITE_ACK_WAIT_S) then
         return True;
      else
         return False;
      end if;
   end function;

   function axiLEndOfRead(
      r       : in RegType;
      ack     : in AxiLiteAckType
   ) return boolean is variable endOfRead : boolean;
begin
   if (ack.done = '1' and r.regAccessState = READ_ACK_WAIT_S) then
      return True;
   else
      return False;
   end if;
end function;

begin

   U_AxiLiteMaster : entity surf.AxiLiteMaster
      generic map (
         TPD_G => TPD_G)
      port map (
         req             => r.req,
         ack             => ack,
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilWriteMaster => mAxilWriteMaster,
         axilWriteSlave  => mAxilWriteSlave,
         axilReadMaster  => mAxilReadMaster,
         axilReadSlave   => mAxilReadSlave);



   -- Algorithm : https://confluence.slac.stanford.edu/display/ppareg/Delay+determination+in+lanes
   comb : process (axilRst, r, ack, start, stop, readyForTrigAck, enable, increment) is
      variable v             : RegType;
      variable regIndex      : integer;
   begin
      v := r;
      regIndex :=  to_integer(unsigned(r.regIndex));

      case r.state is
         when WAIT_START_S =>
            if (start = '1' and enable = '1') then
               v.state := ENDLYCFG_S;
               v.regAccessState := WRITE_S;
            end if;
         -- Enable user delay configuration
         when ENDLYCFG_S =>
            if (stop = '1') then
               v.state := WAIT_START_S;
            else         
               axiLWrite(enDlyCfgAddress, x"00000001", r, v, ack);
               -- check end case
               if (axiLEndOfWrite(r, ack) = True) then
                  v.state := SETDLY_S;
                  v.regAccessState := WRITE_S;
                  v.regIndex := (others => '0');
                  v.usrDelayCfg := (others => '0');
               end if;
            end if;
         -- Set the delay for all the lanes
         when SETDLY_S => 
            if (stop = '1') then
               v.state := WAIT_START_S;
            elsif (r.regIndex >= 24) then
               v.regIndex := (others => '0');
               v.state := CNTRST_S;
               v.regAccessState := WRITE_S;
               v.regIndex := (others => '0');
            else
               axiLWrite(usrDlyCfgAddress(regIndex), r.usrDelayCfg, r, v, ack);
               -- check end case
               if (axiLEndOfWrite(r, ack) = True) then
                  v.regAccessState := WRITE_S;
                  v.regIndex := r.regIndex + 1;
               end if;
            end if;        
         -- reset statistics counters
         when CNTRST_S => 
            if (stop = '1') then
               v.state := WAIT_START_S;
            else         
               axiLWrite(cntRstAddress, x"00000001", r, v, ack);
               -- check end case
               if (axiLEndOfWrite(r, ack) = True) then
                  v.state := READY4TRIG_S;
                  v.regAccessState := READ_S;
                  v.regIndex := (others => '0');
               end if;
            end if;
         when READ_ERRDETCNT_S =>
            if (stop = '1') then
               v.state := WAIT_START_S;
            elsif (r.regIndex >= 24) then
               v.regIndex := (others => '0');
               v.state := SETDLY_S;
               v.regAccessState := WRITE_S;
               v.usrDelayCfg := r.usrDelayCfg + increment;
               if (r.usrDelayCfg = 511) then
                  v.state := WAIT_START_S;
               end if;               
               v.regIndex := (others => '0');
            else
               axiLRead(detErrCntAddresses(regIndex), r, v, ack);
               -- check end case
               if (axiLEndOfRead(r, ack) = True) then
                  v.regAccessState := READ_S;
                  v.regIndex := r.regIndex + 1;
                  v.readValue := ack.rdData;                  
               end if;
            end if;           
         when READY4TRIG_S =>
            if (stop = '1') then
               v.state := WAIT_START_S;
            else
               v.readyForTrig := '1';
               if(readyForTrigAck = '1') then
                  v.readyForTrig := '0';
                  v.state := READ_ERRDETCNT_S;
               end if;
            end if;
            
      end case;
      

      -- reset logic      
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- outputs
      
      rin <= v;

      readyForTrig <= r.readyForTrig;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;             
      end if;
   end process seq;
   
   

end RTL;
