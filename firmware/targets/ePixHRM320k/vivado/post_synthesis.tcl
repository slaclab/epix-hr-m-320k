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
set ilaName u_ila_0

# ##################
# ## Create the core
# ##################
CreateDebugCore ${ilaName}

# #######################
# ## Set the record depth
# #######################
set_property C_DATA_DEPTH 1024 [get_debug_cores ${ilaName}]

# #################################
# ## Set the clock for the ILA core
# #################################
SetDebugCoreClk ${ilaName} {U_Core/GEN_PGP.U_axilClock/clkOut[0]}

# #######################
# ## Set the debug Probes
#######################
ConfigProbe ${ilaName} {U_Core/mAxilReadMaster[arvalid]}
ConfigProbe ${ilaName} {U_Core/mAxilReadMaster[rready]}
ConfigProbe ${ilaName} {U_Core/mAxilReadMaster[araddr][*]}

ConfigProbe ${ilaName} {U_Core/mAxilReadSlave[arready]}
ConfigProbe ${ilaName} {U_Core/mAxilReadSlave[rdata][*]}
ConfigProbe ${ilaName} {U_Core/mAxilReadSlave[rvalid]}

# ##########################
# ## Write the port map file
# ##########################
WriteDebugProbes ${ilaName}

##############################################################################
