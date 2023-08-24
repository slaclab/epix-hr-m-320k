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
#return

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
SetDebugCoreClk ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[0].DataFifo_U/wr_clk}

# #######################
# ## Set the debug Probes
#######################
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/U_RegCtrl/G_DS2411[0].U_DS2411_N/iFdSerDin}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/U_RegCtrl/G_DS2411[1].U_DS2411_N/iFdSerDin}
#ConfigProbe ${ila0Name} {U_App/U_AsicTop/U_RegCtrl/G_DS2411[2].U_DS2411_N/iFdSerDin}

#ConfigProbe ${ila0Name} {U_Core/mAxilReadMaster[rready]}
#ConfigProbe ${ila0Name} {U_Core/mAxilReadMaster[araddr][*]}

#ConfigProbe ${ila0Name} {U_Core/mAxilReadSlave[arready]}
#ConfigProbe ${ila0Name} {U_Core/mAxilReadSlave[rdata][*]}
#ConfigProbe ${ila0Name} {U_Core/mAxilReadSlave[rvalid]}

ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[0].DataFifo_U/rst}
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[0].DataFifo_U/full}
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[0].DataFifo_U/not_full}
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[0].DataFifo_U/wr_en}
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[0].DataFifo_U/wr_ack}
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[0].DataFifo_U/overflow}
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[0].DataFifo_U/rd_en}
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[0].DataFifo_U/valid}
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[0].DataFifo_U/empty}
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[0].DataFifo_U/din*} {0} {18}
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[0].DataFifo_U/wr_data_count*} {0} {8}
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[0].DataFifo_U/dout*} {0} {18}
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/G_FIFO[0].DataFifo_U/rd_data_count*} {0} {8}
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/underflow[0]}
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/r[state]*} {0} {2}
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/r[dataReqLane]*} {0} {15} 
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/r[stCnt]*} {0} {15} 
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/DeserAxisDualClockFifoFull}
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/DeserAxisDualClockFifoWrCnt*} {0} {12}
ConfigProbe ${ila0Name} {U_App/U_AsicTop/G_ASICS[0].U_DigitalAsicStreamAxiV2/startRdSync}


# ##########################
# ## Write the port map file
# ##########################
WriteDebugProbes ${ila0Name}

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
SetDebugCoreClk ${ila1Name} {U_App/U_AsicTop/U_DataSendStretcher/clk}

# #######################
# ## Set the debug Probes
#######################

ConfigProbe ${ila1Name} {U_App/U_AsicTop/U_DataSendStretcher/dataIn}
ConfigProbe ${ila1Name} {U_App/U_AsicTop/U_DataSendStretcher/dataOut}
ConfigProbe ${ila1Name} {U_App/U_AsicTop/U_TrigControl/acqStart}
ConfigProbe ${ila1Name} {U_App/U_AsicTop/U_TrigControl/U_AutoTrig/runTrigIn}
ConfigProbe ${ila1Name} {U_App/U_AsicTop/U_TrigControl/U_AutoTrig/daqTrigIn}
ConfigProbe ${ila1Name} {U_App/U_AsicTop/U_TrigControl/U_AutoTrig/runEn}
ConfigProbe ${ila1Name} {U_App/U_AsicTop/U_TrigControl/U_AutoTrig/daqEn}
ConfigProbe ${ila1Name} {U_App/U_AsicTop/U_TrigControl/U_AutoTrig/runTrigOut}
ConfigProbe ${ila1Name} {U_App/U_AsicTop/U_TrigControl/U_AutoTrig/daqTrigOut}
ConfigProbe ${ila1Name} {U_App/U_AsicTop/U_TrigControl/U_AutoTrig/trigPeriod*} {0} {31}
ConfigProbe ${ila1Name} {U_App/U_AsicTop/U_TrigControl/U_AutoTrig/numTriggers*} {0} {31}

# ##########################
# ## Write the port map file
# ##########################
WriteDebugProbes ${ila1Name}