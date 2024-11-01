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
      TPD_G           	   : time := 1 ns;
      AXIL_BASE_ADDR_G      : slv(31 downto 0) := x"00000000"
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
      step        : in  slv(8 downto 0);
      readyForTrig     : out sl;
      readyForTrigAck  : in  sl;
      busy             : out sl
      
   );
end DelayDetermination;


-- Define architecture
architecture RTL of DelayDetermination is

   type StateType is (WAIT_START_S, ENDLYCFG_S, SETDLY_S, CNTRST_S, READ_ERRDETCNT_S, READY4TRIG_S, WRITE_OPT_S);

   type RegAccessStateType is ( READ_S, READ_ACK_WAIT_S, WRITE_S, WRITE_ACK_WAIT_S, WAIT_WRITE_DONE_S);

   type RangeStateType is (FIRST_RANGE_S, SECOND_RANGE_S);

   type RangeValueArrayType is array (0 to 23) of slv(31 downto 0);

   type RangeFoundBoolArrayType is array (0 to 23) of sl;

   type RangeStateArrayType is array (0 to 23) of RangeStateType;


   type RegType is record
      state                       : StateType;
      regAccessState              : RegAccessStateType;
      req                         : AxiLiteReqType;
      regIndex                    : slv(4 downto 0);
      failingRegister             : slv(31 downto 0);
      usrDelayCfg                 : slv(31 downto 0);
      readValue                   : slv(31 downto 0);
      readyForTrig                : sl;
      busy                        : sl;
      rangeState                  : RangeStateArrayType;
      fstRangeStart               : RangeValueArrayType;
      fstRangeEnd                 : RangeValueArrayType;
      scndRangeStart              : RangeValueArrayType;
      scndRangeEnd                : RangeValueArrayType;
      fstRangeStarted             : RangeFoundBoolArrayType;
      scndRangeStarted            : RangeFoundBoolArrayType;
      fstRangeBestValue           : RangeValueArrayType;
      scndRangeBestValue          : RangeValueArrayType;
      fstOptimumDelay             : slv(31 downto 0);
      fstDiff                     : slv(31 downto 0);
      scndOptimumDelay            : slv(31 downto 0);
      scndDiff                    : slv(31 downto 0);
      optimumDelay                : slv(31 downto 0);
   end record;

   constant REG_INIT_C : RegType := (
      state                       => WAIT_START_S,
      regAccessState              => READ_S,
      req                         => AXI_LITE_REQ_INIT_C,
      regIndex                    => (others => '0'),
      failingRegister             => (others => '0'),
      usrDelayCfg                 => (others => '0'),
      readValue                   => (others => '0'),
      readyForTrig                => '0',
      busy                        => '0',
      rangeState                  => (others => FIRST_RANGE_S),
      fstRangeStart               => (others => (others => '0')),
      fstRangeEnd                 => (others => (others => '0')),
      scndRangeStart              => (others => (others => '0')),
      scndRangeEnd                => (others => (others => '0')),
      fstRangeStarted             => (others => '0'),
      scndRangeStarted            => (others => '0'),
      fstRangeBestValue           => (others => (others => '0')),
      scndRangeBestValue          => (others => (others => '0')),
      fstOptimumDelay             => (others => '0'),
      scndOptimumDelay            => (others => '0'),
      optimumDelay                => (others => '0'),
      fstDiff                     => (others => '0'),
      scndDiff                    => (others => '0')
   );
   
   
   signal ack : AxiLiteAckType;

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType := REG_INIT_C;

   type registerAddressOffsetType is array (0 to 23) of slv(31 downto 0);
   constant detErrCntAddresses : registerAddressOffsetType := 
         (x"000000C0"+AXIL_BASE_ADDR_G, x"000000C4"+AXIL_BASE_ADDR_G, 
          x"000000C8"+AXIL_BASE_ADDR_G, x"000000CC"+AXIL_BASE_ADDR_G,
          x"000000D0"+AXIL_BASE_ADDR_G, x"000000D4"+AXIL_BASE_ADDR_G,
          x"000000D8"+AXIL_BASE_ADDR_G, x"000000DC"+AXIL_BASE_ADDR_G,
          x"000000E0"+AXIL_BASE_ADDR_G, x"000000E4"+AXIL_BASE_ADDR_G,
          x"000000E8"+AXIL_BASE_ADDR_G, x"000000EC"+AXIL_BASE_ADDR_G,
          x"000000F0"+AXIL_BASE_ADDR_G, x"000000F4"+AXIL_BASE_ADDR_G,
          x"000000F8"+AXIL_BASE_ADDR_G, x"000000FC"+AXIL_BASE_ADDR_G,
          x"00000100"+AXIL_BASE_ADDR_G, x"00000104"+AXIL_BASE_ADDR_G,
          x"00000108"+AXIL_BASE_ADDR_G, x"0000010C"+AXIL_BASE_ADDR_G,
          x"00000110"+AXIL_BASE_ADDR_G, x"00000114"+AXIL_BASE_ADDR_G,
          x"00000118"+AXIL_BASE_ADDR_G, x"0000011C"+AXIL_BASE_ADDR_G);

   constant cntRstAddress    : slv(31 downto 0) := x"00000FFC"+AXIL_BASE_ADDR_G;
   constant enDlyCfgAddress  : slv(31 downto 0) := x"00000800"+AXIL_BASE_ADDR_G;

   constant usrDlyCfgAddress : registerAddressOffsetType := 
         (x"00000500"+AXIL_BASE_ADDR_G, x"00000504"+AXIL_BASE_ADDR_G,
          x"00000508"+AXIL_BASE_ADDR_G, x"0000050C"+AXIL_BASE_ADDR_G,
          x"00000510"+AXIL_BASE_ADDR_G, x"00000514"+AXIL_BASE_ADDR_G,
          x"00000518"+AXIL_BASE_ADDR_G, x"0000051C"+AXIL_BASE_ADDR_G,
          x"00000520"+AXIL_BASE_ADDR_G, x"00000524"+AXIL_BASE_ADDR_G, 
          x"00000528"+AXIL_BASE_ADDR_G, x"0000052C"+AXIL_BASE_ADDR_G,
          x"00000530"+AXIL_BASE_ADDR_G, x"00000534"+AXIL_BASE_ADDR_G, 
          x"00000538"+AXIL_BASE_ADDR_G, x"0000053C"+AXIL_BASE_ADDR_G,
          x"00000540"+AXIL_BASE_ADDR_G, x"00000544"+AXIL_BASE_ADDR_G, 
          x"00000548"+AXIL_BASE_ADDR_G, x"0000054C"+AXIL_BASE_ADDR_G,
          x"00000550"+AXIL_BASE_ADDR_G, x"00000554"+AXIL_BASE_ADDR_G, 
          x"00000558"+AXIL_BASE_ADDR_G, x"0000055C"+AXIL_BASE_ADDR_G);

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
   comb : process (axilRst, r, ack, start, stop, readyForTrigAck, enable, step) is
      variable v             : RegType;
      variable regIndex      : integer;
   begin
      v := r;
      regIndex :=  to_integer(unsigned(r.regIndex));

      case r.state is
         when WAIT_START_S =>
            v.busy := '0';
            v.readyForTrig        := '0';
            v.rangeState          := (others => FIRST_RANGE_S);
            v.fstRangeStart       := (others => (others => '0'));
            v.fstRangeEnd         := (others => (others => '0'));
            v.scndRangeStart      := (others => (others => '0'));
            v.scndRangeEnd        := (others => (others => '0'));
            v.fstRangeStarted     := (others => '0');
            v.scndRangeStarted    := (others => '0');
            v.fstRangeBestValue   := (others => (others => '0'));
            v.scndRangeBestValue  := (others => (others => '0'));
            v.regAccessState := WRITE_S;
            if (start = '1' and enable = '1') then
               v.state := ENDLYCFG_S;
            end if;
         -- Enable user delay configuration
         when ENDLYCFG_S =>
            v.busy := '1';
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
         -- This is where the magic happens
     
     
         --fstRangeEnd         
         --scndRangeStart      
         --scndRangeEnd        
         --fstRangeStarted       
         --scndRangeStarted      
         --fstRangeBestValue   
         --scndRangeBestValue  

         when READ_ERRDETCNT_S =>
            if (stop = '1') then
               v.state := WAIT_START_S;
            elsif (r.regIndex >= 24) then
               v.regIndex := (others => '0');
               v.state := SETDLY_S;
               v.regAccessState := WRITE_S;
               v.usrDelayCfg := r.usrDelayCfg + step;
               if (r.usrDelayCfg = 511) then
                  v.state := WRITE_OPT_S;
               end if;               
               v.regIndex := (others => '0');
            else
               axiLRead(detErrCntAddresses(regIndex), r, v, ack);
               -- check end case
               if (axiLEndOfRead(r, ack) = True) then
                  v.regAccessState := READ_S;
                  v.regIndex := r.regIndex + 1;
                  v.readValue := ack.rdData;
                  case r.rangeState(regIndex) is
                     when FIRST_RANGE_S =>
                        if (ack.rdData = 0) then
                           if (r.fstRangeStarted(regIndex) = '0') then
                              v.fstRangeStarted(regIndex) := '1';
                              v.fstRangeStart(regIndex) := r.usrDelayCfg;
                           else
                              v.fstRangeEnd(regIndex) := r.usrDelayCfg;
                           end if;
                        else
                           if (r.fstRangeStarted(regIndex) = '1') then
                              v.rangeState(regIndex) := SECOND_RANGE_S;
                           end if;                              
                        end if;
                     when SECOND_RANGE_S =>
                        if (ack.rdData = 0) then
                           if (r.scndRangeStarted(regIndex) = '0') then
                              v.scndRangeStarted(regIndex) := '1';
                              v.scndRangeStart(regIndex) := r.usrDelayCfg;
                           else
                              v.scndRangeEnd(regIndex) := r.usrDelayCfg;
                           end if;
                        end if;                     
                  end case;
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
                  v.regAccessState := READ_S;
               end if;
            end if;
         when WRITE_OPT_S =>
            if (stop = '1') then
               v.state := WAIT_START_S;
            elsif (r.regIndex >= 24) then
               v.state := WAIT_START_S;
            else
               v.fstDiff   := r.fstRangeEnd(regIndex) - r.fstRangeStart(regIndex);
               v.scndDiff  := r.scndRangeEnd(regIndex) - r.scndRangeStart(regIndex);

               v.fstOptimumDelay   := r.fstRangeStart(regIndex) + r.fstRangeEnd(regIndex);
               v.scndOptimumDelay  := r.scndRangeStart(regIndex) + r.scndRangeEnd(regIndex);

               if (v.fstDiff > v.scndDiff) then
                  v.optimumDelay := '0' & v.fstOptimumDelay(31 downto 1);
               else
                  v.optimumDelay := '0' & v.scndOptimumDelay(31 downto 1);
               end if;
               axiLWrite(usrDlyCfgAddress(regIndex), v.optimumDelay, r, v, ack);
               -- check end case
               if (axiLEndOfWrite(r, ack) = True) then
                  v.regIndex := r.regIndex + 1;
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
      busy <= r.busy;
      
   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;             
      end if;
   end process seq;
   
   

end RTL;
