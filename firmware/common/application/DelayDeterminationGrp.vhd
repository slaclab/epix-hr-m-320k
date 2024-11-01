-------------------------------------------------------------------------------
-- File       : DelayDeterminationGrp.vhd
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

entity DelayDeterminationGrp is 
   generic (
      TPD_G           	   : time := 1 ns;
      AXIL_ERR_RESP_G      : slv(1 downto 0)  := AXI_RESP_DECERR_C;
      NUM_DRIVERS_G        : natural range 1 to 5 := 4;
      AXIL_BASE_ADDR_G     : slv(31 downto 0) := x"00000000"
   );
   port ( 
     
      
      -- AXI lite slave port for register access
      axilClk           : in  sl;
      axilRst           : in  sl;

      -- local registers
      sAxilReadMaster    : in  AxiLiteReadMasterType;
      sAxilReadSlave     : out AxiLiteReadSlaveType;
      sAxilWriteMaster   : in  AxiLiteWriteMasterType;
      sAxilWriteSlave    : out AxiLiteWriteSlaveType;

      -- Master Slots (Connect to AXI Slaves)
      mAxilWriteMasters : out AxiLiteWriteMasterArray(NUM_DRIVERS_G-1 downto 0);
      mAxilWriteSlaves  : in  AxiLiteWriteSlaveArray(NUM_DRIVERS_G-1 downto 0);
      mAxilReadMasters  : out AxiLiteReadMasterArray(NUM_DRIVERS_G-1 downto 0);
      mAxilReadSlaves   : in  AxiLiteReadSlaveArray(NUM_DRIVERS_G-1 downto 0);
      
      -- Daq trigger and start readout request input
      forceTrigger        : out  sl
      
   );
end DelayDeterminationGrp;


-- Define architecture
architecture RTL of DelayDeterminationGrp is

   type StateType is (WAIT_START_S, WAIT_STOPCOUNT_S, SEND_TRIGGER_S, ACK_S);

   type RegType is record
      state                       : StateType;
      sAxilWriteSlave             : AxiLiteWriteSlaveType;
      sAxilReadSlave              : AxiLiteReadSlaveType;
      forceTrigger                : sl;
      step                        : slv(8 downto 0);
      asicEn                      : slv(NUM_DRIVERS_G-1 downto 0);
      start                       : sl;
      stop                        : sl;
      startCounter                : slv(3 downto 0);
      stopCounter                 : slv(3 downto 0);  
      timeoutCounter              : slv(31 downto 0);  
      triggerTimeout              : slv(31 downto 0);  
      readyForTrigAck             : sl;
   end record;

   constant REG_INIT_C : RegType := (
      state                       => WAIT_START_S,
      sAxilWriteSlave             => AXI_LITE_WRITE_SLAVE_INIT_C,
      sAxilReadSlave              => AXI_LITE_READ_SLAVE_INIT_C,
      forceTrigger                => '0',
      step                        => '0' & x"01",
      asicEn                      => (others => '1'),
      start                       => '0',
      stop                        => '0',
      startCounter                => (others => '0'),
      stopCounter                 => (others => '0'),
      timeoutCounter              => (others => '0'),
      triggerTimeout              => x"00007A12", -- 200us on a 156.25MHz clock
      readyForTrigAck             => '0'
   );
   
   


   signal ack : AxiLiteAckType;

   signal r             : RegType := REG_INIT_C;
   signal rin           : RegType := REG_INIT_C;

   signal readyForTrig  : slv(NUM_DRIVERS_G-1 downto 0);
   signal allReady      : slv(NUM_DRIVERS_G-1 downto 0);
   signal busy          : slv(NUM_DRIVERS_G-1 downto 0);
   begin

      comb : process (axilRst, sAxilWriteMaster, sAxilReadMaster, r, allReady, busy) is
         variable v             : RegType;
         variable regCon        : AxiLiteEndPointType;
      begin
         v := r;
         
         axiSlaveWaitTxn(regCon, sAxilWriteMaster, sAxilReadMaster, v.sAxilWriteSlave, v.sAxilReadSlave);
         

         axiSlaveRegister (regCon, x"000",  0, v.step);
         axiSlaveRegister (regCon, x"004",  0, v.triggerTimeout);
         axiSlaveRegister (regCon, x"008",  0, v.asicEn);
         axiSlaveRegister (regCon, x"00C",  0, v.start);
         axiSlaveRegister (regCon, x"010",  0, v.stop);
         axiSlaveRegisterR(regCon, x"014",  0, busy);

         
         axiSlaveDefault(regCon, v.sAxilWriteSlave, v.sAxilReadSlave, AXIL_ERR_RESP_G);

         case r.state is
            when WAIT_START_S =>
               v.forceTrigger := '0';
               v.readyForTrigAck := '0';
               if (allReady = (NUM_DRIVERS_G-1 downto 0 => '1') and r.asicEn /= (NUM_DRIVERS_G-1 downto 0 => '0')) then
                  v.state := SEND_TRIGGER_S;
                  v.timeoutCounter := (others => '0');
               end if;
            when SEND_TRIGGER_S => 
               v.state := WAIT_STOPCOUNT_S;
               v.forceTrigger := '1';
            when WAIT_STOPCOUNT_S =>
               v.forceTrigger := '0';
               v.timeoutCounter := r.timeoutCounter + 1;
               if (r.timeoutCounter >= r.triggerTimeout) then
                  v.state := ACK_S;
                  v.timeoutCounter := (others => '0');
               end if;
            when ACK_S =>
                  v.readyForTrigAck := '1';
                  v.timeoutCounter := r.timeoutCounter + 1;
                  if (r.timeoutCounter >= x"0000000f") then
                     v.state := WAIT_START_S;
                     v.timeoutCounter := (others => '0');
                  end if;
         end case;

         if (r.start = '1') then
            v.startCounter := r.startCounter + 1;
            if (r.startCounter = 15) then
               v.start := '0';
            end if;         
         else
            v.startCounter := (others => '0');
         end if;

         if (r.stop = '1') then
            v.stopCounter := r.stopCounter + 1;
            if (r.stopCounter = 15) then
               v.stop := '0';
            end if;
         else
            v.stopCounter := (others => '0');
         end if;


         -- reset logic      
         if (axilRst = '1') then
            v := REG_INIT_C;
         end if;

         -- outputs
         
         rin <= v;

         sAxilWriteSlave <= r.sAxilWriteSlave;
         sAxilReadSlave  <= r.sAxilReadSlave;

      end process comb;

      forceTrigger <= r.forceTrigger;

      seq : process (axilClk) is
      begin
         if (rising_edge(axilClk)) then
            r <= rin after TPD_G;             
         end if;
      end process seq;
      
      G_DELAYDETERMINATION : for i in 0 to NUM_DRIVERS_G-1 generate

         allReady(i) <= (not r.asicEn(i)) or readyForTrig(i);

         U_DelayDetermination : entity work.DelayDetermination
         generic map (
            TPD_G                  => TPD_G,
            AXIL_BASE_ADDR_G        => AXIL_BASE_ADDR_G
            )
         port map (
            axilClk           => axilClk,
            axilRst           => axilRst,
            
            start             => r.start,
            stop              => r.stop,
            enable            => r.asicEn(i),
            step              => r.step,
            readyForTrig      => readyForTrig(i),
            readyForTrigAck   => r.readyForTrigAck,
            busy              => busy(i),

            mAxilWriteMaster  => mAxilWriteMasters(i), 
            mAxilWriteSlave   => mAxilWriteSlaves(i),  
            mAxilReadMaster   => mAxilReadMasters(i),  
            mAxilReadSlave    => mAxilReadSlaves(i)

         );
      end generate;


end RTL;
