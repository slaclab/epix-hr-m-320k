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
SetDebugCoreClk ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/axilClk}

# #######################
# ## Set the debug Probes
#######################

ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[state][0]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[state][1]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[locked]} 
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[rst]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[rstlen][0]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[rstlen][1]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[rstlen][2]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[rstlen][3]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[tgt][0]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[tgt][1]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[tgt][2]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[tgt][3]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[tgt][4]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[tgt][5]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[tgt][6]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[rstcnt][0]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[rstcnt][1]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[rstcnt][2]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[rstcnt][3]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[mask][0]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[mask][1]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[mask][2]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[mask][3]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[mask][4]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[mask][5]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/r[mask][6]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/resetErr}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/resetDone}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/ack[done]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/ack[rdData][0]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/ack[rdData][1]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/ack[rdData][2]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/ack[rdData][3]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/ack[rdData][4]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/ack[rdData][5]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/ack[rdData][6]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/ack[rdData][7]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/ack[rdData][8]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/ack[rdData][9]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/ack[rdData][10]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/ack[rdData][11]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/ack[rdData][12]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/ack[rdData][13]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/ack[rdData][14]}
ConfigProbe ${ila0Name} {U_App/U_TimingRx/GEN_GT.U_GTH/U_AlignCheck/ack[rdData][15]}


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
