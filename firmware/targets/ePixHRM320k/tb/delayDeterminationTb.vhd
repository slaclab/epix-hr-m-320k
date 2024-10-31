-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: test bench for ePixHRM320k
-------------------------------------------------------------------------------
-- This file is part of 'ePixHRM320k firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'Simple-PGPv4-KCU105-Example', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;
use surf.AxiLitePkg.all;

use ieee.std_logic_misc.all;

library ruckus;
use ruckus.BuildInfoPkg.all;

entity DelayDeterminationGrpTb is
end entity DelayDeterminationGrpTb;

architecture testbench of DelayDeterminationGrpTb is

    signal sAxilWriteMaster  : AxiLiteWriteMasterType;
    signal sAxilWriteSlave   : AxiLiteWriteSlaveType;
    signal sAxilReadMaster   : AxiLiteReadMasterType;
    signal sAxilReadSlave    : AxiLiteReadSlaveType;

    -- AXI lite master port for asic register writes
    signal mAxilWriteMaster  :  AxiLiteWriteMasterType;
    signal mAxilWriteSlave   :  AxiLiteWriteSlaveType;
    signal mAxilReadMaster   :  AxiLiteReadMasterType;
    signal mAxilReadSlave    :  AxiLiteReadSlaveType;

    signal axilClk : sl;
    signal axilRst : sl;
    signal forceTrigger : sl;

    signal ack : AxiLiteAckType;
    signal req : AxiLiteReqType;


begin


    process
    begin
        axilRst <= '1';
        wait for 50 ns;
        axilRst <= '0';
        req.address  <= x"0000000C"; 
        req.rnw <= '0'; -- WRITE
        req.wrData <= x"00000001"; 
        req.request <= '1'; -- initiate request
        wait until ack.done = '1';
        req.request <= '0';        
        wait;
    end process;



    U_AxiLiteMaster : entity surf.AxiLiteMaster
    port map (
       req             => req,
       ack             => ack,
       axilClk         => axilClk,
       axilRst         => axilRst,
       axilWriteMaster => sAxilWriteMaster,
       axilWriteSlave  => sAxilWriteSlave,
       axilReadMaster  => sAxilReadMaster,
       axilReadSlave   => sAxilReadSlave);



    U_DelayDeterminationGrp : entity work.DelayDeterminationGrp
    generic map(
        NUM_DRIVERS_G        => 1
    )
    port map( 
       -- AXI lite slave port for register access
       axilClk           => axilClk,
       axilRst           => axilRst,

       sAxilWriteMaster  => sAxilWriteMaster,
       sAxilWriteSlave   => sAxilWriteSlave,
       sAxilReadMaster   => sAxilReadMaster,
       sAxilReadSlave    => sAxilReadSlave,

       -- AXI lite master port for asic register writes
       mAxilWriteMasters(0)  => mAxilWriteMaster,
       mAxilWriteSlaves(0)   => mAxilWriteSlave,
       mAxilReadMasters(0)   => mAxilReadMaster,
       mAxilReadSlaves(0)    => mAxilReadSlave,
       
       -- Charge injection forced trigger
       forceTrigger      => forceTrigger
       
    );  




    U_MEM : entity surf.AxiDualPortRam
    generic map (
        ADDR_WIDTH_G => 22,
        DATA_WIDTH_G => 32)
  port map (
     -- Axi Port
     axiClk         => axilClk,
     axiRst         => axilRst,
     axiReadMaster  => mAxilReadMaster,
     axiReadSlave   => mAxilReadSlave,
     axiWriteMaster => mAxilWriteMaster,
     axiWriteSlave  => mAxilWriteSlave);


 
    U_Clk156 : entity surf.ClkRst
       generic map (
            CLK_PERIOD_G      => 6.4 ns,   -- 156.25 MHz
            RST_START_DELAY_G => 0 ns,
            RST_HOLD_TIME_G   => 1000 ns)
       port map (
            clkP => axilClk
        );
 

end architecture;