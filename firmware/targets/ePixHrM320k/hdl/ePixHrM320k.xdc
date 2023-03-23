
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR Yes [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1     [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE No   [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 51.0    [current_design]
set_property CFGBVS         {GND}                [current_design]
set_property CONFIG_VOLTAGE {1.8}                [current_design]


set_property -dict {PACKAGE_PIN V12 IOSTANDARD ANALOG} [get_ports vPIn]
set_property -dict {PACKAGE_PIN W11 IOSTANDARD ANALOG} [get_ports vNIn]

set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]

##########################
##	Bank 72
##########################
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS18} [get_ports adcMonSpiData]
set_property -dict {PACKAGE_PIN E17 IOSTANDARD LVCMOS18} [get_ports adcMonSpiClk]
set_property -dict {PACKAGE_PIN E16 IOSTANDARD LVDS} [get_ports adcMonClkP]
set_property -dict {PACKAGE_PIN D16 IOSTANDARD LVDS} [get_ports adcMonClkM]
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS18} [get_ports adcMonSpiCsL]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS18} [get_ports adcMonPdwn]
set_property -dict {PACKAGE_PIN B19 IOSTANDARD LVCMOS18} [get_ports {slowAdcDout[0]}]
set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS18} [get_ports {slowAdcDrdyL[0]}]
set_property -dict {PACKAGE_PIN A15 IOSTANDARD LVCMOS18} [get_ports {slowAdcRefClk[0]}]
set_property -dict {PACKAGE_PIN A19 IOSTANDARD LVCMOS18} [get_ports {slowAdcSyncL[0]}]
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS18} [get_ports {slowAdcSclk[0]}]
set_property -dict {PACKAGE_PIN B14 IOSTANDARD LVCMOS18} [get_ports {slowAdcDin[0]}]
set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS18} [get_ports {slowAdcCsL[0]}]


##########################
##	Bank 71
##########################
set_property -dict {PACKAGE_PIN H21} [get_ports {asicDataP[3][23]}]
set_property -dict {PACKAGE_PIN G21} [get_ports {asicDataM[3][23]}]
set_property -dict {PACKAGE_PIN G22} [get_ports {asicDataP[3][22]}]
set_property -dict {PACKAGE_PIN F22} [get_ports {asicDataM[3][22]}]
set_property -dict {PACKAGE_PIN G20} [get_ports {asicDataP[3][21]}]
set_property -dict {PACKAGE_PIN F20} [get_ports {asicDataM[3][21]}]
set_property -dict {PACKAGE_PIN F23} [get_ports {asicDataP[3][20]}]
set_property -dict {PACKAGE_PIN F24} [get_ports {asicDataM[3][20]}]
set_property -dict {PACKAGE_PIN E20} [get_ports {asicDataP[3][19]}]
set_property -dict {PACKAGE_PIN E21} [get_ports {asicDataM[3][19]}]
set_property -dict {PACKAGE_PIN G24} [get_ports {asicDataP[3][18]}]
set_property -dict {PACKAGE_PIN F25} [get_ports {asicDataM[3][18]}]
set_property -dict {PACKAGE_PIN D20} [get_ports {asicDataP[3][17]}]
set_property -dict {PACKAGE_PIN D21} [get_ports {asicDataM[3][17]}]
set_property -dict {PACKAGE_PIN B20} [get_ports {asicDataP[3][16]}]
set_property -dict {PACKAGE_PIN A20} [get_ports {asicDataM[3][16]}]
set_property -dict {PACKAGE_PIN C21} [get_ports {asicDataP[3][15]}]
set_property -dict {PACKAGE_PIN C22} [get_ports {asicDataM[3][15]}]
set_property -dict {PACKAGE_PIN B21} [get_ports {asicDataP[3][14]}]
set_property -dict {PACKAGE_PIN B22} [get_ports {asicDataM[3][14]}]
set_property -dict {PACKAGE_PIN E22} [get_ports {asicDataP[3][13]}]
set_property -dict {PACKAGE_PIN E23} [get_ports {asicDataM[3][13]}]
set_property -dict {PACKAGE_PIN D23} [get_ports {asicDataP[3][12]}]
set_property -dict {PACKAGE_PIN C23} [get_ports {asicDataM[3][12]}]
set_property -dict {PACKAGE_PIN D24} [get_ports {asicDataP[3][11]}]
set_property -dict {PACKAGE_PIN C24} [get_ports {asicDataM[3][11]}]
set_property -dict {PACKAGE_PIN E25} [get_ports {asicDataP[3][10]}]
set_property -dict {PACKAGE_PIN D25} [get_ports {asicDataM[3][10]}]
set_property -dict {PACKAGE_PIN B24} [get_ports {asicDataP[3][9]}]
set_property -dict {PACKAGE_PIN A24} [get_ports {asicDataM[3][9]}]
set_property -dict {PACKAGE_PIN C26} [get_ports {asicDataP[3][8]}]
set_property -dict {PACKAGE_PIN B26} [get_ports {asicDataM[3][8]}]
set_property -dict {PACKAGE_PIN B25} [get_ports {asicDataP[3][7]}]
set_property -dict {PACKAGE_PIN A25} [get_ports {asicDataM[3][7]}]
set_property -dict {PACKAGE_PIN E26} [get_ports {asicDataP[3][6]}]
set_property -dict {PACKAGE_PIN D26} [get_ports {asicDataM[3][6]}]
set_property -dict {PACKAGE_PIN A27} [get_ports {asicDataP[3][5]}]
set_property -dict {PACKAGE_PIN A28} [get_ports {asicDataM[3][5]}]
set_property -dict {PACKAGE_PIN D28} [get_ports {asicDataP[3][4]}]
set_property -dict {PACKAGE_PIN C28} [get_ports {asicDataM[3][4]}]
set_property -dict {PACKAGE_PIN B29} [get_ports {asicDataP[3][3]}]
set_property -dict {PACKAGE_PIN A29} [get_ports {asicDataM[3][3]}]
set_property -dict {PACKAGE_PIN E28} [get_ports {asicDataP[3][2]}]
set_property -dict {PACKAGE_PIN D29} [get_ports {asicDataM[3][2]}]
set_property -dict {PACKAGE_PIN C27} [get_ports {asicDataP[3][1]}]
set_property -dict {PACKAGE_PIN B27} [get_ports {asicDataM[3][1]}]
set_property -dict {PACKAGE_PIN F27} [get_ports {asicDataP[3][0]}]
set_property -dict {PACKAGE_PIN E27} [get_ports {asicDataM[3][0]}]

set_property -dict {IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 DQS_BIAS TRUE EQUALIZATION EQ_LEVEL0} [get_ports {asicDataP[3][*]}]
set_property -dict {IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 DQS_BIAS TRUE EQUALIZATION EQ_LEVEL0} [get_ports {asicDataM[3][*]}]

##########################
##	Bank 70
##########################
set_property -dict {PACKAGE_PIN V31} [get_ports {asicDataP[2][23]}]
set_property -dict {PACKAGE_PIN W31} [get_ports {asicDataM[2][23]}]
set_property -dict {PACKAGE_PIN U34} [get_ports {asicDataP[2][22]}]
set_property -dict {PACKAGE_PIN V34} [get_ports {asicDataM[2][22]}]
set_property -dict {PACKAGE_PIN Y31} [get_ports {asicDataP[2][21]}]
set_property -dict {PACKAGE_PIN Y32} [get_ports {asicDataM[2][21]}]
set_property -dict {PACKAGE_PIN V33} [get_ports {asicDataP[2][20]}]
set_property -dict {PACKAGE_PIN W34} [get_ports {asicDataM[2][20]}]
set_property -dict {PACKAGE_PIN W30} [get_ports {asicDataP[2][19]}]
set_property -dict {PACKAGE_PIN Y30} [get_ports {asicDataM[2][19]}]
set_property -dict {PACKAGE_PIN W33} [get_ports {asicDataP[2][18]}]
set_property -dict {PACKAGE_PIN Y33} [get_ports {asicDataM[2][18]}]
set_property -dict {PACKAGE_PIN AC33} [get_ports {asicDataP[2][17]}]
set_property -dict {PACKAGE_PIN AD33} [get_ports {asicDataM[2][17]}]
set_property -dict {PACKAGE_PIN AA34} [get_ports {asicDataP[2][16]}]
set_property -dict {PACKAGE_PIN AB34} [get_ports {asicDataM[2][16]}]
set_property -dict {PACKAGE_PIN AA29} [get_ports {asicDataP[2][15]}]
set_property -dict {PACKAGE_PIN AB29} [get_ports {asicDataM[2][15]}]
set_property -dict {PACKAGE_PIN AC34} [get_ports {asicDataP[2][14]}]
set_property -dict {PACKAGE_PIN AD34} [get_ports {asicDataM[2][14]}]
set_property -dict {PACKAGE_PIN AB30} [get_ports {asicDataP[2][13]}]
set_property -dict {PACKAGE_PIN AB31} [get_ports {asicDataM[2][13]}]
set_property -dict {PACKAGE_PIN AA32} [get_ports {asicDataP[2][12]}]
set_property -dict {PACKAGE_PIN AB32} [get_ports {asicDataM[2][12]}]
set_property -dict {PACKAGE_PIN AC31} [get_ports {asicDataP[2][11]}]
set_property -dict {PACKAGE_PIN AC32} [get_ports {asicDataM[2][11]}]
set_property -dict {PACKAGE_PIN AD30} [get_ports {asicDataP[2][10]}]
set_property -dict {PACKAGE_PIN AD31} [get_ports {asicDataM[2][10]}]
set_property -dict {PACKAGE_PIN AE33} [get_ports {asicDataP[2][9]}]
set_property -dict {PACKAGE_PIN AF34} [get_ports {asicDataM[2][9]}]
set_property -dict {PACKAGE_PIN AE32} [get_ports {asicDataP[2][8]}]
set_property -dict {PACKAGE_PIN AF32} [get_ports {asicDataM[2][8]}]
set_property -dict {PACKAGE_PIN AF33} [get_ports {asicDataP[2][7]}]
set_property -dict {PACKAGE_PIN AG34} [get_ports {asicDataM[2][7]}]
set_property -dict {PACKAGE_PIN AG31} [get_ports {asicDataP[2][6]}]
set_property -dict {PACKAGE_PIN AG32} [get_ports {asicDataM[2][6]}]
set_property -dict {PACKAGE_PIN AF30} [get_ports {asicDataP[2][5]}]
set_property -dict {PACKAGE_PIN AG30} [get_ports {asicDataM[2][5]}]
set_property -dict {PACKAGE_PIN AD29} [get_ports {asicDataP[2][4]}]
set_property -dict {PACKAGE_PIN AE30} [get_ports {asicDataM[2][4]}]
set_property -dict {PACKAGE_PIN AF29} [get_ports {asicDataP[2][3]}]
set_property -dict {PACKAGE_PIN AG29} [get_ports {asicDataM[2][3]}]
set_property -dict {PACKAGE_PIN AC28} [get_ports {asicDataP[2][2]}]
set_property -dict {PACKAGE_PIN AD28} [get_ports {asicDataM[2][2]}]
set_property -dict {PACKAGE_PIN AE28} [get_ports {asicDataP[2][1]}]
set_property -dict {PACKAGE_PIN AF28} [get_ports {asicDataM[2][1]}]
set_property -dict {PACKAGE_PIN AE27} [get_ports {asicDataP[2][0]}]
set_property -dict {PACKAGE_PIN AF27} [get_ports {asicDataM[2][0]}]

set_property -dict {IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 DQS_BIAS TRUE EQUALIZATION EQ_LEVEL0} [get_ports {asicDataP[2][*]}]
set_property -dict {IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 DQS_BIAS TRUE EQUALIZATION EQ_LEVEL0} [get_ports {asicDataM[2][*]}]


##########################
##	Bank 69
##########################
set_property -dict {PACKAGE_PIN AA20 IOSTANDARD LVCMOS18} [get_ports pcbSync]
# set_property -dict { PACKAGE_PIN AB20 IOSTANDARD LVCMOS18 } [get_ports { pcb    }]
set_property -dict {PACKAGE_PIN AC22 IOSTANDARD LVCMOS18} [get_ports {slowAdcDrdyL[1]}]
set_property -dict {PACKAGE_PIN AC23 IOSTANDARD LVCMOS18} [get_ports {slowAdcDout[1]}]

set_property -dict {PACKAGE_PIN AA22 IOSTANDARD LVCMOS18} [get_ports runToFpga]
set_property -dict {PACKAGE_PIN AB22 IOSTANDARD LVCMOS18} [get_ports daqToFpga]
set_property -dict {PACKAGE_PIN AB25 IOSTANDARD LVCMOS18} [get_ports ttlToFpga]

set_property -dict {PACKAGE_PIN AB26 IOSTANDARD LVCMOS18} [get_ports {pcbSpare[5]}]
set_property -dict {PACKAGE_PIN AA27 IOSTANDARD LVCMOS18} [get_ports {pcbSpare[4]}]
set_property -dict {PACKAGE_PIN AB27 IOSTANDARD LVCMOS18} [get_ports {pcbSpare[3]}]
set_property -dict {PACKAGE_PIN AC26 IOSTANDARD LVCMOS18} [get_ports {pcbSpare[2]}]
set_property -dict {PACKAGE_PIN AC27 IOSTANDARD LVCMOS18} [get_ports {pcbSpare[1]}]
set_property -dict {PACKAGE_PIN AB24 IOSTANDARD LVCMOS18} [get_ports {pcbSpare[0]}]

set_property -dict {PACKAGE_PIN AC24 IOSTANDARD LVCMOS18} [get_ports {slowAdcCsL[1]}]
set_property -dict {PACKAGE_PIN AD25 IOSTANDARD LVCMOS18} [get_ports {slowAdcSclk[1]}]
set_property -dict {PACKAGE_PIN AD26 IOSTANDARD LVCMOS18} [get_ports {slowAdcDin[1]}]

set_property -dict {PACKAGE_PIN Y26 IOSTANDARD LVCMOS18} [get_ports {slowAdcSyncL[1]}]
set_property -dict {PACKAGE_PIN Y27 IOSTANDARD LVCMOS18} [get_ports {slowAdcRefClk[1]}]



##########################
##	Bank 68
##########################
set_property -dict {PACKAGE_PIN AL34} [get_ports {asicDataP[1][23]}]
set_property -dict {PACKAGE_PIN AM34} [get_ports {asicDataM[1][23]}]
set_property -dict {PACKAGE_PIN AM32} [get_ports {asicDataP[1][22]}]
set_property -dict {PACKAGE_PIN AN32} [get_ports {asicDataM[1][22]}]
set_property -dict {PACKAGE_PIN AN34} [get_ports {asicDataP[1][21]}]
set_property -dict {PACKAGE_PIN AP34} [get_ports {asicDataM[1][21]}]
set_property -dict {PACKAGE_PIN AN31} [get_ports {asicDataP[1][20]}]
set_property -dict {PACKAGE_PIN AP31} [get_ports {asicDataM[1][20]}]
set_property -dict {PACKAGE_PIN AN33} [get_ports {asicDataP[1][19]}]
set_property -dict {PACKAGE_PIN AP33} [get_ports {asicDataM[1][19]}]
set_property -dict {PACKAGE_PIN AL32} [get_ports {asicDataP[1][18]}]
set_property -dict {PACKAGE_PIN AL33} [get_ports {asicDataM[1][18]}]
set_property -dict {PACKAGE_PIN AH34} [get_ports {asicDataP[1][17]}]
set_property -dict {PACKAGE_PIN AJ34} [get_ports {asicDataM[1][17]}]
set_property -dict {PACKAGE_PIN AH31} [get_ports {asicDataP[1][16]}]
set_property -dict {PACKAGE_PIN AH32} [get_ports {asicDataM[1][16]}]
set_property -dict {PACKAGE_PIN AH33} [get_ports {asicDataP[1][15]}]
set_property -dict {PACKAGE_PIN AJ33} [get_ports {asicDataM[1][15]}]
set_property -dict {PACKAGE_PIN AJ30} [get_ports {asicDataP[1][14]}]
set_property -dict {PACKAGE_PIN AJ31} [get_ports {asicDataM[1][14]}]
set_property -dict {PACKAGE_PIN AK31} [get_ports {asicDataP[1][13]}]
set_property -dict {PACKAGE_PIN AK32} [get_ports {asicDataM[1][13]}]
set_property -dict {PACKAGE_PIN AJ29} [get_ports {asicDataP[1][12]}]
set_property -dict {PACKAGE_PIN AK30} [get_ports {asicDataM[1][12]}]
set_property -dict {PACKAGE_PIN AL30} [get_ports {asicDataP[1][11]}]
set_property -dict {PACKAGE_PIN AM30} [get_ports {asicDataM[1][11]}]
set_property -dict {PACKAGE_PIN AL29} [get_ports {asicDataP[1][10]}]
set_property -dict {PACKAGE_PIN AM29} [get_ports {asicDataM[1][10]}]
set_property -dict {PACKAGE_PIN AN29} [get_ports {asicDataP[1][9]}]
set_property -dict {PACKAGE_PIN AP30} [get_ports {asicDataM[1][9]}]
set_property -dict {PACKAGE_PIN AN27} [get_ports {asicDataP[1][8]}]
set_property -dict {PACKAGE_PIN AN28} [get_ports {asicDataM[1][8]}]
set_property -dict {PACKAGE_PIN AP28} [get_ports {asicDataP[1][7]}]
set_property -dict {PACKAGE_PIN AP29} [get_ports {asicDataM[1][7]}]
set_property -dict {PACKAGE_PIN AN26} [get_ports {asicDataP[1][6]}]
set_property -dict {PACKAGE_PIN AP26} [get_ports {asicDataM[1][6]}]
set_property -dict {PACKAGE_PIN AJ28} [get_ports {asicDataP[1][5]}]
set_property -dict {PACKAGE_PIN AK28} [get_ports {asicDataM[1][5]}]
set_property -dict {PACKAGE_PIN AH27} [get_ports {asicDataP[1][4]}]
set_property -dict {PACKAGE_PIN AH28} [get_ports {asicDataM[1][4]}]
set_property -dict {PACKAGE_PIN AL27} [get_ports {asicDataP[1][3]}]
set_property -dict {PACKAGE_PIN AL28} [get_ports {asicDataM[1][3]}]
set_property -dict {PACKAGE_PIN AK26} [get_ports {asicDataP[1][2]}]
set_property -dict {PACKAGE_PIN AK27} [get_ports {asicDataM[1][2]}]
set_property -dict {PACKAGE_PIN AM26} [get_ports {asicDataP[1][1]}]
set_property -dict {PACKAGE_PIN AM27} [get_ports {asicDataM[1][1]}]
set_property -dict {PACKAGE_PIN AH26} [get_ports {asicDataP[1][0]}]
set_property -dict {PACKAGE_PIN AJ26} [get_ports {asicDataM[1][0]}]

set_property -dict {IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 DQS_BIAS TRUE EQUALIZATION EQ_LEVEL0} [get_ports {asicDataP[1][*]}]
set_property -dict {IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 DQS_BIAS TRUE EQUALIZATION EQ_LEVEL0} [get_ports {asicDataM[1][*]}]


##########################
##	Bank 67
##########################
set_property -dict {PACKAGE_PIN AN23} [get_ports {asicDataP[0][23]}]
set_property -dict {PACKAGE_PIN AP23} [get_ports {asicDataM[0][23]}]
set_property -dict {PACKAGE_PIN AP24} [get_ports {asicDataP[0][22]}]
set_property -dict {PACKAGE_PIN AP25} [get_ports {asicDataM[0][22]}]
set_property -dict {PACKAGE_PIN AP20} [get_ports {asicDataP[0][21]}]
set_property -dict {PACKAGE_PIN AP21} [get_ports {asicDataM[0][21]}]
set_property -dict {PACKAGE_PIN AM24} [get_ports {asicDataP[0][20]}]
set_property -dict {PACKAGE_PIN AN24} [get_ports {asicDataM[0][20]}]
set_property -dict {PACKAGE_PIN AM22} [get_ports {asicDataP[0][19]}]
set_property -dict {PACKAGE_PIN AN22} [get_ports {asicDataM[0][19]}]
set_property -dict {PACKAGE_PIN AM21} [get_ports {asicDataP[0][18]}]
set_property -dict {PACKAGE_PIN AN21} [get_ports {asicDataM[0][18]}]
set_property -dict {PACKAGE_PIN AL24} [get_ports {asicDataP[0][17]}]
set_property -dict {PACKAGE_PIN AL25} [get_ports {asicDataM[0][17]}]
set_property -dict {PACKAGE_PIN AL22} [get_ports {asicDataP[0][16]}]
set_property -dict {PACKAGE_PIN AL23} [get_ports {asicDataM[0][16]}]
set_property -dict {PACKAGE_PIN AJ20} [get_ports {asicDataP[0][15]}]
set_property -dict {PACKAGE_PIN AK20} [get_ports {asicDataM[0][15]}]
set_property -dict {PACKAGE_PIN AL20} [get_ports {asicDataP[0][14]}]
set_property -dict {PACKAGE_PIN AM20} [get_ports {asicDataM[0][14]}]
set_property -dict {PACKAGE_PIN AK22} [get_ports {asicDataP[0][13]}]
set_property -dict {PACKAGE_PIN AK23} [get_ports {asicDataM[0][13]}]
set_property -dict {PACKAGE_PIN AJ21} [get_ports {asicDataP[0][12]}]
set_property -dict {PACKAGE_PIN AK21} [get_ports {asicDataM[0][12]}]
set_property -dict {PACKAGE_PIN AH22} [get_ports {asicDataP[0][11]}]
set_property -dict {PACKAGE_PIN AH23} [get_ports {asicDataM[0][11]}]
set_property -dict {PACKAGE_PIN AJ23} [get_ports {asicDataP[0][10]}]
set_property -dict {PACKAGE_PIN AJ24} [get_ports {asicDataM[0][10]}]
set_property -dict {PACKAGE_PIN AH24} [get_ports {asicDataP[0][9]}]
set_property -dict {PACKAGE_PIN AJ25} [get_ports {asicDataM[0][9]}]
set_property -dict {PACKAGE_PIN AG24} [get_ports {asicDataP[0][8]}]
set_property -dict {PACKAGE_PIN AG25} [get_ports {asicDataM[0][8]}]
set_property -dict {PACKAGE_PIN AF23} [get_ports {asicDataP[0][7]}]
set_property -dict {PACKAGE_PIN AF24} [get_ports {asicDataM[0][7]}]
set_property -dict {PACKAGE_PIN AE25} [get_ports {asicDataP[0][6]}]
set_property -dict {PACKAGE_PIN AE26} [get_ports {asicDataM[0][6]}]
set_property -dict {PACKAGE_PIN AF22} [get_ports {asicDataP[0][5]}]
set_property -dict {PACKAGE_PIN AG22} [get_ports {asicDataM[0][5]}]
set_property -dict {PACKAGE_PIN AE22} [get_ports {asicDataP[0][4]}]
set_property -dict {PACKAGE_PIN AE23} [get_ports {asicDataM[0][4]}]
set_property -dict {PACKAGE_PIN AG21} [get_ports {asicDataP[0][3]}]
set_property -dict {PACKAGE_PIN AH21} [get_ports {asicDataM[0][3]}]
set_property -dict {PACKAGE_PIN AD20} [get_ports {asicDataP[0][2]}]
set_property -dict {PACKAGE_PIN AE20} [get_ports {asicDataM[0][2]}]
set_property -dict {PACKAGE_PIN AF20} [get_ports {asicDataP[0][1]}]
set_property -dict {PACKAGE_PIN AG20} [get_ports {asicDataM[0][1]}]
set_property -dict {PACKAGE_PIN AD21} [get_ports {asicDataP[0][0]}]
set_property -dict {PACKAGE_PIN AE21} [get_ports {asicDataM[0][0]}]

set_property -dict {IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 DQS_BIAS TRUE EQUALIZATION EQ_LEVEL0} [get_ports {asicDataP[0][*]}]
set_property -dict {IOSTANDARD LVDS DIFF_TERM_ADV TERM_100 DQS_BIAS TRUE EQUALIZATION EQ_LEVEL0} [get_ports {asicDataM[0][*]}]



##########################
##	Bank 66
##########################
set_property -dict {PACKAGE_PIN J13 IOSTANDARD LVDS} [get_ports {adcMonDoutP[1][4]}]
set_property -dict {PACKAGE_PIN H13 IOSTANDARD LVDS} [get_ports {adcMonDoutM[1][4]}]
set_property -dict {PACKAGE_PIN L12 IOSTANDARD LVDS} [get_ports {adcMonDoutP[1][3]}]
set_property -dict {PACKAGE_PIN K12 IOSTANDARD LVDS} [get_ports {adcMonDoutM[1][3]}]
set_property -dict {PACKAGE_PIN L13 IOSTANDARD LVDS} [get_ports {adcMonDoutP[1][2]}]
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVDS} [get_ports {adcMonDoutM[1][2]}]
set_property -dict {PACKAGE_PIN K11 IOSTANDARD LVDS} [get_ports {adcMonDoutP[1][1]}]
set_property -dict {PACKAGE_PIN J11 IOSTANDARD LVDS} [get_ports {adcMonDoutM[1][1]}]
set_property -dict {PACKAGE_PIN H12 IOSTANDARD LVDS} [get_ports {adcMonDataClkP[1]}]
set_property -dict {PACKAGE_PIN G12 IOSTANDARD LVDS} [get_ports {adcMonDataClkM[1]}]
set_property -dict {PACKAGE_PIN H11 IOSTANDARD LVDS} [get_ports {adcMonFrameClkP[1]}]
set_property -dict {PACKAGE_PIN G11 IOSTANDARD LVDS} [get_ports {adcMonFrameClkM[1]}]
set_property -dict {PACKAGE_PIN G10 IOSTANDARD LVDS} [get_ports {adcMonDataClkP[0]}]
set_property -dict {PACKAGE_PIN F10 IOSTANDARD LVDS} [get_ports {adcMonDataClkM[0]}]
set_property -dict {PACKAGE_PIN G9 IOSTANDARD LVDS} [get_ports {adcMonFrameClkP[0]}]
set_property -dict {PACKAGE_PIN F9 IOSTANDARD LVDS} [get_ports {adcMonFrameClkM[0]}]
set_property -dict {PACKAGE_PIN J9 IOSTANDARD LVDS} [get_ports {adcMonDoutP[0][7]}]
set_property -dict {PACKAGE_PIN H9 IOSTANDARD LVDS} [get_ports {adcMonDoutM[0][7]}]
set_property -dict {PACKAGE_PIN L8 IOSTANDARD LVDS} [get_ports {adcMonDoutP[0][6]}]
set_property -dict {PACKAGE_PIN K8 IOSTANDARD LVDS} [get_ports {adcMonDoutM[0][6]}]
set_property -dict {PACKAGE_PIN E10 IOSTANDARD LVDS} [get_ports {adcMonDoutP[0][5]}]
set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVDS} [get_ports {adcMonDoutM[0][5]}]
set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVDS} [get_ports {adcMonDoutP[0][4]}]
set_property -dict {PACKAGE_PIN C9 IOSTANDARD LVDS} [get_ports {adcMonDoutM[0][4]}]
set_property -dict {PACKAGE_PIN B10 IOSTANDARD LVDS} [get_ports {adcMonDoutP[0][3]}]
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVDS} [get_ports {adcMonDoutM[0][3]}]
set_property -dict {PACKAGE_PIN D8 IOSTANDARD LVDS} [get_ports {adcMonDoutP[0][2]}]
set_property -dict {PACKAGE_PIN C8 IOSTANDARD LVDS} [get_ports {adcMonDoutM[0][2]}]
set_property -dict {PACKAGE_PIN B9 IOSTANDARD LVDS} [get_ports {adcMonDoutP[0][1]}]
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVDS} [get_ports {adcMonDoutM[0][1]}]
set_property -dict {PACKAGE_PIN F8 IOSTANDARD LVDS} [get_ports {adcMonDoutP[0][0]}]
set_property -dict {PACKAGE_PIN E8 IOSTANDARD LVDS} [get_ports {adcMonDoutM[0][0]}]

set_property -dict {DIFF_TERM_ADV TERM_100} [get_ports {adcMonDoutP[*]}]
set_property -dict {DIFF_TERM_ADV TERM_100} [get_ports {adcMonDoutM[*]}]

set_property -dict {DIFF_TERM_ADV TERM_100} [get_ports {adcMonDataClkP[1]}]
set_property -dict {DIFF_TERM_ADV TERM_100} [get_ports {adcMonFrameClkP[1]}]
set_property -dict {DIFF_TERM_ADV TERM_100} [get_ports {adcMonDataClkP[0]}]
set_property -dict {DIFF_TERM_ADV TERM_100} [get_ports {adcMonFrameClkP[0]}]


##########################
##	Bank 65
##########################
set_property -dict {PACKAGE_PIN N22 IOSTANDARD LVCMOS18} [get_ports {spareM[1]}]
set_property -dict {PACKAGE_PIN M22 IOSTANDARD LVCMOS18} [get_ports {spareP[1]}]

set_property -dict {PACKAGE_PIN R23 IOSTANDARD LVCMOS18} [get_ports {spareM[0]}]
set_property -dict {PACKAGE_PIN P23 IOSTANDARD LVCMOS18} [get_ports {spareP[0]}]

set_property -dict {PACKAGE_PIN R26 IOSTANDARD LVCMOS18} [get_ports {serialNumber[2]}]
set_property -dict {PACKAGE_PIN T24 IOSTANDARD LVCMOS18} [get_ports {serialNumber[1]}]
set_property -dict {PACKAGE_PIN T25 IOSTANDARD LVCMOS18} [get_ports {serialNumber[0]}]

set_property -dict {PACKAGE_PIN M25 IOSTANDARD LVCMOS18} [get_ports fpgaRdClkP]
set_property -dict {PACKAGE_PIN M26 IOSTANDARD LVCMOS18} [get_ports fpgaRdClkM]

set_property -dict {PACKAGE_PIN K25 IOSTANDARD LVCMOS18} [get_ports rdClkSel]
set_property -dict {PACKAGE_PIN L23 IOSTANDARD LVCMOS18} [get_ports {digMon[0]}]
set_property -dict {PACKAGE_PIN L24 IOSTANDARD LVCMOS18} [get_ports {digMon[1]}]

set_property -dict {PACKAGE_PIN M27 IOSTANDARD LVCMOS18} [get_ports asicSro]
set_property -dict {PACKAGE_PIN L27 IOSTANDARD LVCMOS18} [get_ports asicClkEn]
set_property -dict {PACKAGE_PIN J23 IOSTANDARD LVCMOS18} [get_ports asicGlblRst]
set_property -dict {PACKAGE_PIN H24 IOSTANDARD LVCMOS18} [get_ports asicR0]

set_property -dict {PACKAGE_PIN J26 IOSTANDARD LVCMOS18} [get_ports asicAcq]
set_property -dict {PACKAGE_PIN H26 IOSTANDARD LVCMOS18} [get_ports asicSync]
set_property -dict {PACKAGE_PIN J25 IOSTANDARD LVCMOS18} [get_ports saciRsp]

set_property -dict {PACKAGE_PIN K26 IOSTANDARD LVCMOS18} [get_ports {saciSel[3]}]
set_property -dict {PACKAGE_PIN K27 IOSTANDARD LVCMOS18} [get_ports {saciSel[2]}]
set_property -dict {PACKAGE_PIN G25 IOSTANDARD LVCMOS18} [get_ports {saciSel[1]}]
set_property -dict {PACKAGE_PIN G26 IOSTANDARD LVCMOS18} [get_ports {saciSel[0]}]

set_property -dict {PACKAGE_PIN H27 IOSTANDARD LVCMOS18} [get_ports saciCmd]
set_property -dict {PACKAGE_PIN G27 IOSTANDARD LVCMOS18} [get_ports saciClk]


##########################
##	Bank 64
##########################
set_property -dict {PACKAGE_PIN AF14 IOSTANDARD LVCMOS18} [get_ports {pwrAnaEn[1]}]
set_property -dict {PACKAGE_PIN AD19 IOSTANDARD LVCMOS18} [get_ports {pwrAnaEn[0]}]

set_property -dict {PACKAGE_PIN AD18 IOSTANDARD LVCMOS18} [get_ports {syncDcdc[6]}]
set_property -dict {PACKAGE_PIN AG15 IOSTANDARD LVCMOS18} [get_ports {syncDcdc[5]}]
set_property -dict {PACKAGE_PIN AG14 IOSTANDARD LVCMOS18} [get_ports {syncDcdc[4]}]
set_property -dict {PACKAGE_PIN AG19 IOSTANDARD LVCMOS18} [get_ports {syncDcdc[3]}]
set_property -dict {PACKAGE_PIN AH19 IOSTANDARD LVCMOS18} [get_ports {syncDcdc[2]}]
set_property -dict {PACKAGE_PIN AJ15 IOSTANDARD LVCMOS18} [get_ports {syncDcdc[1]}]
set_property -dict {PACKAGE_PIN AJ14 IOSTANDARD LVCMOS18} [get_ports {syncDcdc[0]}]

set_property -dict {PACKAGE_PIN AH16 IOSTANDARD LVCMOS18} [get_ports fpgaClkInP]
set_property -dict {PACKAGE_PIN AJ16 IOSTANDARD LVCMOS18} [get_ports fpgaClkInM]

set_property -dict {PACKAGE_PIN AH18 IOSTANDARD LVCMOS18} [get_ports fpgaClkOutP]
set_property -dict {PACKAGE_PIN AH17 IOSTANDARD LVCMOS18} [get_ports fpgaClkOutM]

set_property -dict {PACKAGE_PIN AL18 IOSTANDARD LVCMOS18} [get_ports biasDacDin]
set_property -dict {PACKAGE_PIN AL17 IOSTANDARD LVCMOS18} [get_ports biasDacSclk]
set_property -dict {PACKAGE_PIN AK15 IOSTANDARD LVCMOS18} [get_ports biasDacCsb]
set_property -dict {PACKAGE_PIN AL15 IOSTANDARD LVCMOS18} [get_ports biasDacClrb]

set_property -dict {PACKAGE_PIN AL19 IOSTANDARD LVCMOS18} [get_ports hsDacSclk]
set_property -dict {PACKAGE_PIN AM19 IOSTANDARD LVCMOS18} [get_ports hsDacDin]
set_property -dict {PACKAGE_PIN AL14 IOSTANDARD LVCMOS18} [get_ports hsCsb]
set_property -dict {PACKAGE_PIN AM14 IOSTANDARD LVCMOS18} [get_ports hsLdacb]

set_property -dict {PACKAGE_PIN AP16 IOSTANDARD LVCMOS18} [get_ports jitclnrCsL]
set_property -dict {PACKAGE_PIN AP15 IOSTANDARD LVCMOS18} [get_ports jitclnrIntr]
set_property -dict {PACKAGE_PIN AM16 IOSTANDARD LVCMOS18} [get_ports jitclnrLolL]
set_property -dict {PACKAGE_PIN AM15 IOSTANDARD LVCMOS18} [get_ports jitclnrOeL]
set_property -dict {PACKAGE_PIN AN18 IOSTANDARD LVCMOS18} [get_ports jitclnrRstL]
set_property -dict {PACKAGE_PIN AN17 IOSTANDARD LVCMOS18} [get_ports jitclnrSclk]
set_property -dict {PACKAGE_PIN AM17 IOSTANDARD LVCMOS18} [get_ports jitclnrSdio]
set_property -dict {PACKAGE_PIN AN16 IOSTANDARD LVCMOS18} [get_ports jitclnrSdo]

set_property -dict {PACKAGE_PIN AN19 IOSTANDARD LVCMOS18} [get_ports {jitclnrSel[1]}]
set_property -dict {PACKAGE_PIN AP18 IOSTANDARD LVCMOS18} [get_ports {jitclnrSel[0]}]

set_property -dict {PACKAGE_PIN AN14 IOSTANDARD LVCMOS18} [get_ports pllClkScl]
set_property -dict {PACKAGE_PIN AP14 IOSTANDARD LVCMOS18} [get_ports pllClkSda]

##########################
##	Bank 91
##########################
set_property -dict {PACKAGE_PIN AK8 IOSTANDARD LVCMOS33} [get_ports obTransScl]
set_property -dict {PACKAGE_PIN AL8 IOSTANDARD LVCMOS33} [get_ports obTransSda]
set_property -dict {PACKAGE_PIN AJ9 IOSTANDARD LVCMOS33} [get_ports obTransResetL]
set_property -dict {PACKAGE_PIN AJ8 IOSTANDARD LVCMOS33} [get_ports obTransIntL]
set_property -dict {PACKAGE_PIN AN8 IOSTANDARD LVCMOS33} [get_ports {pwrGood[0]}]
set_property -dict {PACKAGE_PIN AP8 IOSTANDARD LVCMOS33} [get_ports {pwrGood[1]}]

##########################
##	Bank 90
##########################
set_property -dict {PACKAGE_PIN AP13 IOSTANDARD LVCMOS33} [get_ports fpgaTtlOut]
set_property -dict {PACKAGE_PIN AP11 IOSTANDARD LVCMOS33} [get_ports fpgaTg]
set_property -dict {PACKAGE_PIN AP10 IOSTANDARD LVCMOS33} [get_ports fpgaMps]

##########################
##	Bank 129
##########################
# NO PINS CONNECTED

##########################
##	Bank 130
##########################
# NO PINS CONNECTED

##########################
##	Bank 224
##########################
# NO PINS CONNECTED

##########################
##	Bank 225
##########################
# NO PINS CONNECTED

##########################
##	Bank 226
##########################
set_property PACKAGE_PIN AA4 [get_ports {fpgaOutObTransInP[4]}]
set_property PACKAGE_PIN AA3 [get_ports {fpgaOutObTransInM[4]}]
set_property PACKAGE_PIN Y2 [get_ports {fpgaInObTransOutP[4]}]
set_property PACKAGE_PIN Y1 [get_ports {fpgaInObTransOutM[4]}]

set_property PACKAGE_PIN V2 [get_ports {fpgaInObTransOutP[5]}]
set_property PACKAGE_PIN V1 [get_ports {fpgaInObTransOutM[5]}]
set_property PACKAGE_PIN W4 [get_ports {fpgaOutObTransInP[5]}]
set_property PACKAGE_PIN W3 [get_ports {fpgaOutObTransInM[5]}]

set_property PACKAGE_PIN T2 [get_ports {fpgaInObTransOutP[6]}]
set_property PACKAGE_PIN T1 [get_ports {fpgaInObTransOutM[6]}]
set_property PACKAGE_PIN U4 [get_ports {fpgaOutObTransInP[6]}]
set_property PACKAGE_PIN U3 [get_ports {fpgaOutObTransInM[6]}]

set_property PACKAGE_PIN P2 [get_ports {fpgaInObTransOutP[7]}]
set_property PACKAGE_PIN P1 [get_ports {fpgaInObTransOutM[7]}]
set_property PACKAGE_PIN R4 [get_ports {fpgaOutObTransInP[7]}]
set_property PACKAGE_PIN R3 [get_ports {fpgaOutObTransInM[7]}]

# set_property PACKAGE_PIN V6  [get_ports {gtPllClkP}]
# set_property PACKAGE_PIN V5  [get_ports {gtPllClkM}]

set_property PACKAGE_PIN T5 [get_ports {gtRefClkM[1]}]
set_property PACKAGE_PIN T6 [get_ports {gtRefClkP[1]}]


##########################
##	Bank 227
##########################
set_property PACKAGE_PIN M2 [get_ports {fpgaInObTransOutP[8]}]
set_property PACKAGE_PIN M1 [get_ports {fpgaInObTransOutM[8]}]
set_property PACKAGE_PIN N4 [get_ports {fpgaOutObTransInP[8]}]
set_property PACKAGE_PIN N3 [get_ports {fpgaOutObTransInM[8]}]

set_property PACKAGE_PIN K2 [get_ports {fpgaInObTransOutP[9]}]
set_property PACKAGE_PIN K1 [get_ports {fpgaInObTransOutM[9]}]
set_property PACKAGE_PIN L4 [get_ports {fpgaOutObTransInP[9]}]
set_property PACKAGE_PIN L3 [get_ports {fpgaOutObTransInM[9]}]

set_property PACKAGE_PIN H2 [get_ports {fpgaInObTransOutP[10]}]
set_property PACKAGE_PIN H1 [get_ports {fpgaInObTransOutM[10]}]
set_property PACKAGE_PIN J4 [get_ports {fpgaOutObTransInP[10]}]
set_property PACKAGE_PIN J3 [get_ports {fpgaOutObTransInM[10]}]

set_property PACKAGE_PIN F2 [get_ports {fpgaInObTransOutP[11]}]
set_property PACKAGE_PIN F1 [get_ports {fpgaInObTransOutM[11]}]
set_property PACKAGE_PIN G4 [get_ports {fpgaOutObTransInP[11]}]
set_property PACKAGE_PIN G3 [get_ports {fpgaOutObTransInM[11]}]

#set_property PACKAGE_PIN P6 [get_ports {altTimingClkP}]
#set_property PACKAGE_PIN P5 [get_ports {altTimingClkM}]

set_property PACKAGE_PIN M5 [get_ports gtLclsClkM]
set_property PACKAGE_PIN M6 [get_ports gtLclsClkP]

##########################
##	Bank 228
##########################
set_property PACKAGE_PIN E4 [get_ports {fpgaInObTransOutP[0]}]
set_property PACKAGE_PIN E3 [get_ports {fpgaInObTransOutM[0]}]
set_property PACKAGE_PIN F6 [get_ports {fpgaOutObTransInP[0]}]
set_property PACKAGE_PIN F5 [get_ports {fpgaOutObTransInM[0]}]

set_property PACKAGE_PIN D2 [get_ports {fpgaInObTransOutP[1]}]
set_property PACKAGE_PIN D1 [get_ports {fpgaInObTransOutM[1]}]
set_property PACKAGE_PIN D6 [get_ports {fpgaOutObTransInP[1]}]
set_property PACKAGE_PIN D5 [get_ports {fpgaOutObTransInM[1]}]

set_property PACKAGE_PIN B2 [get_ports {fpgaInObTransOutP[2]}]
set_property PACKAGE_PIN B1 [get_ports {fpgaInObTransOutM[2]}]
set_property PACKAGE_PIN C4 [get_ports {fpgaOutObTransInP[2]}]
set_property PACKAGE_PIN C3 [get_ports {fpgaOutObTransInM[2]}]

set_property PACKAGE_PIN A4 [get_ports {fpgaInObTransOutP[3]}]
set_property PACKAGE_PIN A3 [get_ports {fpgaInObTransOutM[3]}]
set_property PACKAGE_PIN B6 [get_ports {fpgaOutObTransInP[3]}]
set_property PACKAGE_PIN B5 [get_ports {fpgaOutObTransInM[3]}]

set_property PACKAGE_PIN K5 [get_ports gtPllClkM]
set_property PACKAGE_PIN K6 [get_ports gtPllClkP]

set_property PACKAGE_PIN H5 [get_ports {gtRefClkM[0]}]
set_property PACKAGE_PIN H6 [get_ports {gtRefClkP[0]}]

