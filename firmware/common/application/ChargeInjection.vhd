-------------------------------------------------------------------------------
-- File       : DigitalAsicStreamAxi.vhd
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

entity ChargeInjection is 
   generic (
      TPD_G           	   : time := 1 ns;
      AXIL_ERR_RESP_G      : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      AXI_BASE_ADDR_C      : slv(31 downto 0) := x"00000000"
   );
   port ( 
     
      
      -- AXI lite slave port for register access
      axilClk           : in  sl;
      axilRst           : in  sl;
      sAxilWriteMaster  : in  AxiLiteWriteMasterType;
      sAxilWriteSlave   : out AxiLiteWriteSlaveType;
      sAxilReadMaster   : in  AxiLiteReadMasterType;
      sAxilReadSlave    : out AxiLiteReadSlaveType;

      -- AXI lite master port for asic register writes
      mAxilWriteMaster  : out  AxiLiteWriteMasterType;
      mAxilWriteSlave   : in   AxiLiteWriteSlaveType;
      mAxilReadMaster   : out  AxiLiteReadMasterType;
      mAxilReadSlave    : in   AxiLiteReadSlaveType;
      
      -- Daq trigger and start readout request input
      forceTrigger        : out  sl
      
   );
end ChargeInjection;


-- Define architecture
architecture RTL of ChargeInjection is

   type asicAddressOffsetType is array (0 to 3) of slv(31 downto 0);
   constant addresses : asicAddressOffsetType := (x"00000000"+AXI_BASE_ADDR_C, 
                                                  x"00040000"+AXI_BASE_ADDR_C, 
                                                  x"00080000"+AXI_BASE_ADDR_C, 
                                                  x"000C0000"+AXI_BASE_ADDR_C);

   type StateType is (WAIT_START_S, FE_XX2GR_S, TEST_START_S, PULSER_S, 
                      CHARGE_COL_S, CLK_NEGEDGE_S, CLK_POSEDGE_S, TRIGGER_S, TEST_END_S , ERROR_S, INIT_S);

   type RegAccessStateType is ( READ_S, READ_ACK_WAIT_S, WRITE_S, WRITE_ACK_WAIT_S, WAIT_WRITE_DONE_S);

   type chargeInjectionStatusType is ( IDLE_S, RUNNING_S, SUCCESS_S, AXI_ERROR_S, COL_ERROR_S, STEP_ERROR_S, STOP_S );



   type RegType is record
      state                       : StateType;
      stateLast                   : StateType;
      regAccessState              : RegAccessStateType;
      req                         : AxiLiteReqType;
      sAxilWriteSlave             : AxiLiteWriteSlaveType;
      sAxilReadSlave              : AxiLiteReadSlaveType;
      startCol                    : slv(8 downto 0);
      endCol                      : slv(8 downto 0);
      step                        : slv(8 downto 0);
      start                       : sl;
      stop                        : sl;
      pulser                      : slv(10 downto 0);
      currentCol                  : slv(8 downto 0);
      failingRegister             : slv(31 downto 0);
      chargeCol                   : sl;
      rdData                      : slv(31 downto 0);
      forceTrigger                : sl;
      triggerWaitCycles           : slv(31 downto 0);
      cycleCounter                : slv(31 downto 0);
      status                      : slv(7 downto 0);
      currentAsic                 : slv(1 downto 0);
      triggerStateCounter         : slv(31 downto 0);
   end record;

   constant REG_INIT_C : RegType := (
      state                       => WAIT_START_S,
      stateLast                   => WAIT_START_S,
      regAccessState              => READ_S,
      sAxilWriteSlave             => AXI_LITE_WRITE_SLAVE_INIT_C,
      sAxilReadSlave              => AXI_LITE_READ_SLAVE_INIT_C,
      req                         => AXI_LITE_REQ_INIT_C,
      startCol                    => '0' & x"32",
      endCol                      => '0' & x"64",
      step                        => '0' & x"01",
      start                       => '0',
      stop                        => '0',
      pulser                      => (others=>'0'),
      currentCol                  => (others=>'0'),
      failingRegister             => (others=>'0'),
      chargeCol                   => '0',
      rdData                      => (others=>'0'),
      forceTrigger                => '0',
      triggerWaitCycles           => x"00007A12",
      cycleCounter                => (others=>'0'),
      status                      => (others=>'0'),
      currentAsic                 => (others=>'0'),
      triggerStateCounter         => (others=>'0')
   );
   
   
   signal ack : AxiLiteAckType;

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType := REG_INIT_C;




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
               if (ack.resp = AXI_RESP_OK_C) then
                  v.rdData := ack.rdData;
               else 
                  v.failingRegister := address;
               end if;
               v.req.request := '0';
               v.regAccessState := WRITE_S;
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
               v.regAccessState := WAIT_WRITE_DONE_S; 
               v.req.request := '0';    
            end if;  
         when WAIT_WRITE_DONE_S =>
         -- do nothing  
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
      if (ack.done = '0' and r.regAccessState = WAIT_WRITE_DONE_S) then
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



  
   comb : process (axilRst, sAxilWriteMaster, sAxilReadMaster, r, ack) is
      variable v             : RegType;
      variable regCon        : AxiLiteEndPointType;
      variable chargeCol     : sl;
      variable currentAsic   : integer;
      variable status        : chargeInjectionStatusType;
   begin
      v := r;
      
      axiSlaveWaitTxn(regCon, sAxilWriteMaster, sAxilReadMaster, v.sAxilWriteSlave, v.sAxilReadSlave);
      

      axiSlaveRegister (regCon, x"000",  0, v.startCol);
      axiSlaveRegister (regCon, x"004",  0, v.endCol);
      axiSlaveRegister (regCon, x"008",  0, v.step);
      axiSlaveRegister (regCon, x"00C",  0, v.start);
      axiSlaveRegister (regCon, x"010",  0, v.stop);
      axiSlaveRegister (regCon, x"014",  0, v.triggerWaitCycles);
      axiSlaveRegister (regCon, x"018",  0, v.currentAsic);
      axiSlaveRegisterR(regCon, x"020",  0, r.pulser);
      axiSlaveRegisterR(regCon, x"024",  0, r.currentCol);
      axiSlaveRegisterR(regCon, x"028",  0, r.failingRegister);
      axiSlaveRegisterR(regCon, x"02C",  0, r.status);
      axiSlaveRegisterR(regCon, x"030",  0, std_logic_vector(to_unsigned(StateType'pos(r.state), 8))); 
      axiSlaveRegisterR(regCon, x"034",  0, std_logic_vector(to_unsigned(StateType'pos(r.stateLast), 8))); 
      axiSlaveRegisterR(regCon, x"038",  0, r.triggerStateCounter);
      
      axiSlaveDefault(regCon, v.sAxilWriteSlave, v.sAxilReadSlave, AXIL_ERR_RESP_G);

      currentAsic :=  to_integer(unsigned(r.currentAsic));

      -- Do this for all enabled asics
      -- CHARGE INJECTION ALGORITHM
      -- Setting charge injection necessary registers in the relevant ASIC
         -- FE_ACQ2GR_en = True       0x00001023*addrSize, bitSize=1, bitOffset=5
         -- FE_sync2GR_en = False     0x00001023*addrSize, bitSize=1, bitOffset=6
         -- InjEn_ePixM = 0           offset=0x0000101a*addrSize, bitSize=1, bitOffset=6
      -- Enable charge injection 
         -- test = True               offset=0x00001003*addrSize, bitSize=1,  bitOffset=12
      -- Set the value of the Pulser  offset=0x00001003*addrSize, bitSize=10, bitOffset=0
      -- Shift in one element at a time an array of 384 elements (1 element per column) where each value is either 0 or 1 by setting the InjEn_ePixM register to the value then toggling the ClkInj_ePixM register to 1, then back to 0
         -- InjEn_ePixM 0 being disable charge injection for the column offset=0x0000101a*addrSize, bitSize=1, bitOffset=6
         -- InjEn_ePixM 1 being enable charge injection for the column offset=0x0000101a*addrSize, bitSize=1, bitOffset=6
         -- ClkInj_ePixM offset=0x0000101a*addrSize, bitSize=1, bitOffset=7
      -- Once done disable charge injection by setting test register to 0      

      -- WAIT_START_S, FE_XX2GR_S, TEST_START_S, PULSER_S, 
      -- CHARGE_COL_S, SHIFT_S, TRIGGER_S, TEST_END_S, ERROR_S,

      -- RegAccessStateType is ( READ_S, READ_ACK_WAIT, WRITE_S, WRITE_ACK_WAIT );
      case r.state is
         when WAIT_START_S =>
            v.stop := '0';
            if (r.startCol >= r.endCol) then
               status := COL_ERROR_S;
            elsif (r.step = '0' & x"00") then
               status := STEP_ERROR_S;
            elsif r.start = '1' then
               v.state := FE_XX2GR_S;
               v.stateLast := WAIT_START_S;
               v.regAccessState := READ_S;
               v.failingRegister := (others => '0');
               v.triggerStateCounter := (others => '0');
            end if;

         when FE_XX2GR_S =>
            if (r.stop = '1') then
               v.state := INIT_S;
               v.stateLast := FE_XX2GR_S;
               status := STOP_S;
            else
               -- Setting charge injection necessary registers in the relevant ASIC
               -- FE_ACQ2GR_en = True       0x00001023*addrSize, bitSize=1, bitOffset=5
               -- FE_sync2GR_en = False     0x00001023*addrSize, bitSize=1, bitOffset=6         
               axiLRead(x"408C"+addresses(currentAsic), r, v, ack);
               axiLWrite(x"408C"+addresses(currentAsic), r.rdData(31 downto 7) & "01" & r.rdData(4 downto 0), r, v, ack); 
               
               -- check end case
               if(checkError(r, ack) = True) then
                  v.state := ERROR_S;
                  v.stateLast := FE_XX2GR_S;
               elsif (axiLEndOfWrite(r, ack) = True) then
                  v.state := TEST_START_S;
                  v.stateLast := FE_XX2GR_S;
                  v.regAccessState := READ_S;
               end if;

               status := RUNNING_S;
            end if;
         when TEST_START_S =>
            if (r.stop = '1') then
               v.state := INIT_S;
               v.stateLast := TEST_START_S;
               status := STOP_S;
            else         
               -- test = True               offset=0x00001003*addrSize, bitSize=1,  bitOffset=12         
               axiLRead(x"400C"+addresses(currentAsic), r, v, ack);
               axiLWrite(x"400C"+addresses(currentAsic), r.rdData(31 downto 13) & "1" & r.rdData(11 downto 0), r, v, ack);          

               -- check end case
               if(checkError(r, ack) = True) then
                  v.state := ERROR_S;
                  v.stateLast := TEST_START_S;
               elsif (axiLEndOfWrite(r, ack) = True) then
                  v.state := PULSER_S;
                  v.stateLast := TEST_START_S;
                  v.regAccessState := READ_S;
               end if;
               
               v.pulser := (others => '0');
            end if;
         when PULSER_S =>
            if (r.stop = '1') then
               v.state := INIT_S;
               v.stateLast := PULSER_S;
               status := STOP_S;
            else           
               -- Set the value of the Pulser  offset=0x00001003*addrSize, bitSize=10, bitOffset=0         
               -- exit state condition
               axiLRead(x"400C"+addresses(currentAsic), r, v, ack);
               axiLWrite(x"400C"+addresses(currentAsic), r.rdData(31 downto 10) & r.pulser(9 downto 0), r, v, ack);     

               -- check end case
               if(checkError(r, ack) = True) then
                  v.state := ERROR_S;
                  v.stateLast := PULSER_S;
               elsif (axiLEndOfWrite(r, ack) = True) then
                  -- increment pulser
                  v.pulser := r.pulser + r.step;
                  v.state := CHARGE_COL_S;
                  v.stateLast := PULSER_S;
                  v.regAccessState := READ_S;
               end if;
               v.currentCol := (others => '0');
            end if;
         when CHARGE_COL_S =>
            if (r.stop = '1') then
               v.state := INIT_S;
               v.stateLast := CHARGE_COL_S;
               status := STOP_S;
            else              
               -- InjEn_ePixM 0 being disable charge injection for the column offset=0x0000101a*addrSize, bitSize=1, bitOffset=6
               -- InjEn_ePixM 1 being enable charge injection for the column offset=0x0000101a*addrSize, bitSize=1, bitOffset=6         
               if (r.currentCol >= r.startCol and r.currentCol <= r.endCol) then
                  chargeCol := '1';
               else
                  chargeCol := '0';
               end if;
               v.chargeCol := chargeCol;
               axiLRead(x"4068"+addresses(currentAsic), r, v, ack);
               axiLWrite(x"4068"+addresses(currentAsic), r.rdData(31 downto 7) & chargeCol & r.rdData(5 downto 0), r, v, ack);    
               
               if(checkError(r, ack) = True) then
                  v.state := ERROR_S;
                  v.stateLast := CHARGE_COL_S;
               elsif (axiLEndOfWrite(r, ack) = True) then
                  v.state := CLK_NEGEDGE_S;
                  v.stateLast := CHARGE_COL_S;
                  v.regAccessState := READ_S;
                  -- increment currentCol
                  v.currentCol := r.currentCol + 1;
               end if;
            end if;
            
         when CLK_NEGEDGE_S =>
            if (r.stop = '1') then
               v.state := INIT_S;
               v.stateLast := CLK_NEGEDGE_S;
               status := STOP_S;
            else              
               -- ClkInj_ePixM offset=0x0000101a*addrSize, bitSize=1, bitOffset=7
               axiLRead(x"4068"+addresses(currentAsic), r, v, ack);
               axiLWrite(x"4068"+addresses(currentAsic), r.rdData(31 downto 8) & '0' & r.rdData(6 downto 0), r, v, ack);

               -- check end case
               if(checkError(r, ack) = True) then
                  v.state := ERROR_S;
                  v.stateLast := CLK_NEGEDGE_S;
               elsif (axiLEndOfWrite(r, ack) = True) then
                  -- increment pulser
                  v.state := CLK_POSEDGE_S;
                  v.stateLast := CLK_NEGEDGE_S;
                  v.regAccessState := READ_S;
               end if;
            end if;
         when CLK_POSEDGE_S =>
            if (r.stop = '1') then
               v.state := INIT_S;
               v.stateLast := CLK_POSEDGE_S;
               status := STOP_S;
            else            
               -- ClkInj_ePixM offset=0x0000101a*addrSize, bitSize=1, bitOffset=7
               axiLRead(x"4068"+addresses(currentAsic), r, v, ack);
               axiLWrite(x"4068"+addresses(currentAsic), r.rdData(31 downto 8) & '1' & r.rdData(6 downto 0), r, v, ack);

               -- check end case
               if(checkError(r, ack) = True) then
                  v.state := ERROR_S;
                  v.stateLast := CLK_POSEDGE_S;
               elsif (axiLEndOfWrite(r, ack) = True) then
                  -- increment pulser
                  if (r.currentCol < 384) then
                     v.state := CHARGE_COL_S;
                     v.regAccessState := READ_S;
                  else
                     v.state := TRIGGER_S;
                     v.regAccessState := READ_S;
                  end if;
                  v.stateLast := CLK_POSEDGE_S;
               end if;
            end if;

         when TRIGGER_S =>
            if (r.stop = '1') then
               v.state := INIT_S;
               v.stateLast := TRIGGER_S;
               status := STOP_S;
            else          
               -- set trigger and wait triggerWaitCycles (default 200 us)
               if (r.cycleCounter <= 10) then               
                  v.forceTrigger := '1';
               else
                  v.forceTrigger := '0';
               end if;
               if (r.cycleCounter <= r.triggerWaitCycles) then
                  v.cycleCounter := r.cycleCounter + 1;
               else
                  v.cycleCounter := (others => '0');
                  if (r.pulser < 1024) then
                     v.state := PULSER_S;
                     v.regAccessState := READ_S;
                  else               
                     v.state := TEST_END_S;
                     v.regAccessState := READ_S;
                  end if;
                  v.stateLast := TRIGGER_S;
                  v.triggerStateCounter := r.triggerStateCounter + 1;
               end if;
            end if;
         when TEST_END_S =>
            if (r.stop = '1') then
               v.state := INIT_S;
               v.stateLast := TEST_END_S;
               status := STOP_S;
            else              
               -- test = False               offset=0x00001003*addrSize, bitSize=1,  bitOffset=12 
               axiLRead(x"400C"+addresses(currentAsic), r, v, ack);
               axiLWrite(x"400C"+addresses(currentAsic), r.rdData(31 downto 13) & "0" & r.rdData(11 downto 0), r, v, ack);          

               -- check end case
               if(checkError(r, ack) = True) then
                  v.state := ERROR_S;
                  v.stateLast := TEST_END_S;
               elsif (axiLEndOfWrite(r, ack) = True) then
                  v.state := INIT_S;
                  v.stateLast := TEST_END_S;
               end if;
               status := SUCCESS_S;
            end if;
         when ERROR_S =>   
            v.state := INIT_S;
            v.stateLast := ERROR_S;
            status := AXI_ERROR_S;
            
         when INIT_S =>
            v.state := WAIT_START_S;
            v.regAccessState := READ_S;
            v.start := '0';
            v.stop  := '0';
            v.req  := AXI_LITE_REQ_INIT_C;
            v.forceTrigger := '0';
      end case;
      
  
      v.status := std_logic_vector(to_unsigned(chargeInjectionStatusType'POS(status), 8)) ; 

      -- reset logic      
      if (axilRst = '1') then
         v := REG_INIT_C;
      end if;

      -- outputs
      
      rin <= v;

      sAxilWriteSlave <= r.sAxilWriteSlave;
      sAxilReadSlave  <= r.sAxilReadSlave;
      forceTrigger <= r.forceTrigger;

   end process comb;

   seq : process (axilClk) is
   begin
      if (rising_edge(axilClk)) then
         r <= rin after TPD_G;             
      end if;
   end process seq;
   

end RTL;
