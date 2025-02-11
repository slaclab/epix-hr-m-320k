##############################################################################
## This file is part of 'epix-uhr-dev'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'epix-uhr-dev', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

##############################
# Get variables and procedures
##############################
source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Bypass the debug chipscope generation
return

############################
## Open the synthesis design
############################
open_run synth_1

# ##############################################################################

# ###############################
# ## Set the name of the ILA core
# ###############################
set ila0Name u_ila_0

# ##################
# ## Create the core
# ##################
CreateDebugCore ${ila0Name}

# #######################
# ## Set the record depth
# #######################
set_property C_DATA_DEPTH 1024 [get_debug_cores ${ila0Name}]

# #################################
# ## Set the clock for the ILA core
# #################################
#SetDebugCoreClk ${ila0Name} {U_App/U_Deser/GEN_VEC[1].U_Deser_Group/sspClk}
#SetDebugCoreClk ${ila0Name} {U_App/U_DelayDeterminationGrp/G_DELAYDETERMINATION[1].U_DelayDetermination/axilClk}

SetDebugCoreClk ${ila0Name} {U_App/U_AdcMon/GEN_FAST_ADC[0].U_MonAdcReadout/axilClk}
# #######################
# ## Set the debug Probes
#######################

ConfigProbe ${ila0Name} {U_App/U_AdcMon/GEN_FAST_ADC[0].U_MonAdcReadout/adcStreams[0][tData][*]} 0 13
ConfigProbe ${ila0Name} {U_App/U_AdcMon/GEN_FAST_ADC[0].U_MonAdcReadout/adcStreams[0][tValid]}

ConfigProbe ${ila0Name} {U_App/U_AdcMon/GEN_FAST_ADC[0].U_MonAdcReadout/adcStreams[1][tData][*]} 0 13
ConfigProbe ${ila0Name} {U_App/U_AdcMon/GEN_FAST_ADC[0].U_MonAdcReadout/adcStreams[1][tValid]}

ConfigProbe ${ila0Name} {U_App/U_AdcMon/GEN_FAST_ADC[0].U_MonAdcReadout/adcStreams[2][tData][*]} 0 13
ConfigProbe ${ila0Name} {U_App/U_AdcMon/GEN_FAST_ADC[0].U_MonAdcReadout/adcStreams[2][tValid]}

ConfigProbe ${ila0Name} {U_App/U_AdcMon/GEN_FAST_ADC[0].U_MonAdcReadout/adcStreams[3][tData][*]} 0 13
ConfigProbe ${ila0Name} {U_App/U_AdcMon/GEN_FAST_ADC[0].U_MonAdcReadout/adcStreams[3][tValid]}

ConfigProbe ${ila0Name} {U_App/U_AdcMon/GEN_FAST_ADC[0].U_MonAdcReadout/adcStreams[4][tData][*]} 0 13
ConfigProbe ${ila0Name} {U_App/U_AdcMon/GEN_FAST_ADC[0].U_MonAdcReadout/adcStreams[4][tValid]}

ConfigProbe ${ila0Name} {U_App/U_AdcMon/GEN_FAST_ADC[0].U_MonAdcReadout/adcStreams[5][tData][*]} 0 13
ConfigProbe ${ila0Name} {U_App/U_AdcMon/GEN_FAST_ADC[0].U_MonAdcReadout/adcStreams[5][tValid]}

ConfigProbe ${ila0Name} {U_App/U_AdcMon/GEN_FAST_ADC[0].U_MonAdcReadout/adcStreams[6][tData][*]} 0 13
ConfigProbe ${ila0Name} {U_App/U_AdcMon/GEN_FAST_ADC[0].U_MonAdcReadout/adcStreams[6][tValid]}

ConfigProbe ${ila0Name} {U_App/U_AdcMon/GEN_FAST_ADC[0].U_MonAdcReadout/adcStreams[7][tData][*]} 0 13
ConfigProbe ${ila0Name} {U_App/U_AdcMon/GEN_FAST_ADC[0].U_MonAdcReadout/adcStreams[7][tValid]}


#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/r[state][*]} 0 2
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/r[sroReceived]}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/sro}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/sroSync}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/daqTrigger}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/daqTriggerSync}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/dFifoSof[*]} 0 23
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/dFifoValid[*]} 0 23
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/rdDataCount[0][*]} 0 8
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/rdDataCount[3][*]} 0 8
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/rdDataCount[6][*]} 0 8
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/rdDataCount[10][*]} 0 8
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/rdDataCount[15][*]} 0 8
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/rdDataCount[20][*]} 0 8
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/dFifoRst}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/acqStart}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/acqStartSync}


#156.25 clock domain

#ConfigProbe ${ila0Name} {U_App/U_DelayDeterminationGrp/G_DELAYDETERMINATION[1].U_DelayDetermination/r[fstRangeEnd][0][*]} {0} {31}
#ConfigProbe ${ila0Name} {U_App/U_DelayDeterminationGrp/G_DELAYDETERMINATION[1].U_DelayDetermination/r[fstRangeStart][0][*]} {0} {31}
#ConfigProbe ${ila0Name} {U_App/U_DelayDeterminationGrp/G_DELAYDETERMINATION[1].U_DelayDetermination/r[fstRangeStarted][*]} {0} {23}
#ConfigProbe ${ila0Name} {U_App/U_DelayDeterminationGrp/G_DELAYDETERMINATION[1].U_DelayDetermination/r[scndRangeEnd][0][*]} {0} {31}
#ConfigProbe ${ila0Name} {U_App/U_DelayDeterminationGrp/G_DELAYDETERMINATION[1].U_DelayDetermination/r[scndRangeStart][0][*]} {0} {31}
#ConfigProbe ${ila0Name} {U_App/U_DelayDeterminationGrp/G_DELAYDETERMINATION[1].U_DelayDetermination/r[scndRangeStarted][0]}
#ConfigProbe ${ila0Name} {U_App/U_DelayDeterminationGrp/G_DELAYDETERMINATION[1].U_DelayDetermination/r[state][*]} {0} {31}
#ConfigProbe ${ila0Name} {U_App/U_DelayDeterminationGrp/G_DELAYDETERMINATION[1].U_DelayDetermination/r[usrDelayCfg][*]} {0} {31}
#ConfigProbe ${ila0Name} {U_App/U_DelayDeterminationGrp/G_DELAYDETERMINATION[1].U_DelayDetermination/r[regIndex][*]} {0} {4}
#ConfigProbe ${ila0Name} {U_App/U_DelayDeterminationGrp/G_DELAYDETERMINATION[1].U_DelayDetermination/rin[optimumDelay][*]} {0} {31}
#ConfigProbe ${ila0Name} {U_App/U_DelayDeterminationGrp/G_DELAYDETERMINATION[1].U_DelayDetermination/v_fstOptimumDelay_out[*]} {0} {31}
#ConfigProbe ${ila0Name} {U_App/U_DelayDeterminationGrp/G_DELAYDETERMINATION[1].U_DelayDetermination/v_scndOptimumDelay_out[*]} {0} {31}
#ConfigProbe ${ila0Name} {U_App/U_DelayDeterminationGrp/G_DELAYDETERMINATION[1].U_DelayDetermination/rin[fstDiff][*]} {0} {31}
#ConfigProbe ${ila0Name} {U_App/U_DelayDeterminationGrp/G_DELAYDETERMINATION[1].U_DelayDetermination/rin[scndDiff][*]} {0} {31}




# 42 MHz clk domain
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/r[state]*} 0 2
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[0].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[0].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[0].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[1].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[1].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[1].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[2].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[2].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[2].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[3].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[3].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[3].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[4].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[4].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[4].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[5].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[5].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[5].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[6].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[6].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[6].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[7].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[7].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[7].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[8].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[8].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[8].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[9].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[9].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[9].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[10].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[10].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[10].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[11].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[11].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[11].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[12].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[12].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[12].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[13].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[13].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[13].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[14].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[14].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[14].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[15].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[15].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[15].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[16].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[16].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[16].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[17].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[17].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[17].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[18].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[18].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[18].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[19].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[19].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[19].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[20].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[20].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[20].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[21].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[21].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[21].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[22].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[22].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[22].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[23].DataFifo_U/rd_en}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[23].DataFifo_U/valid}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[23].DataFifo_U/dout*} {0} {15}
#
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/startRdSync}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/cycleCounter*} {0} {15} 


# ##########################
# ## Write the port map file
# ##########################
WriteDebugProbes ${ila0Name}

return
##############################################################################


# ###############################
# ## Set the name of the ILA core
# ###############################
set ila1Name u_ila_1

# ##################
# ## Create the core
# ##################
CreateDebugCore ${ila1Name}

# #######################
# ## Set the record depth
# #######################
set_property C_DATA_DEPTH 1024 [get_debug_cores ${ila1Name}]

# #################################
# ## Set the clock for the ILA core
# #################################
SetDebugCoreClk ${ila1Name} {U_App/U_TimingRx/GEN_GT.U_GTH/rxoutclkb}

# #######################
# ## Set the debug Probes
#######################

ConfigProbe ${ila1Name} {U_App/U_TimingRx/GEN_GT.U_GTH/rxRst}
ConfigProbe ${ila1Name} {U_App/U_TimingRx/GEN_GT.U_GTH/rxbypassrst}


WriteDebugProbes ${ila1Name}
