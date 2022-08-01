
library ieee;
use ieee.std_logic_1164.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;
use surf.SsiCmdMasterPkg.all;


entity Epix320kM is 
    generic (
        TPD_G           : time := 1 ns;
        BUILD_INFO_G    : BuildInfoType;
        ROUGE_SIM_EN    : boolean := false;
        ROGUE_SIM_PORT_NUM_G : natural range 1024 to 49151 := 10000);
    port (
        --
        -- Application Ports
        --
        
        --
        -- Core Ports
        --

    );

architecture topLevel of Epix320kM is

begin

    U_App: work.Application
        generic map (
            TPD_G                 => TPD_G,
            BUILD_INFO_G          => BUILD_INFO_G,
            ROUGE_SIM_EN          => ROUGE_SIM_EN,
            ROGUE_SIM_PORT_NUM_G  => ROGUE_SIM_PORT_NUM_G
        )
        port map (
            
        );

    U_Core: work.Core
        generic (
            TPD_G                 => TPD_G,
            BUILD_INFO_G          => BUILD_INFO_G,
            ROUGE_SIM_EN          => ROUGE_SIM_EN,
            ROGUE_SIM_PORT_NUM_G  => ROGUE_SIM_PORT_NUM_G
        )
        port map (
            
        );
    
end architecture topLevel;