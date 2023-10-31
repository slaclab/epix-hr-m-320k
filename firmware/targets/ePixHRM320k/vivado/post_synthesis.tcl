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
SetDebugCoreClk ${ila0Name} {U_Core/GEN_PGP.U_Pgp/U_Pgp_Lane6/pgpClk}

# #######################
# ## Set the debug Probes
#######################

ConfigProbe ${ila0Name} {U_Core/GEN_PGP.U_Pgp/U_Pgp_Lane6/pgpTxMasters[0][tData]*} 0 63
ConfigProbe ${ila0Name} {U_Core/GEN_PGP.U_Pgp/U_Pgp_Lane6/pgpTxMasters[0][tKeep]*} 0 7
ConfigProbe ${ila0Name} {U_Core/GEN_PGP.U_Pgp/U_Pgp_Lane6/pgpTxMasters[0][tUser]*} 0 15
ConfigProbe ${ila0Name} {U_Core/GEN_PGP.U_Pgp/U_Pgp_Lane6/pgpTxMasters[0][tLast]}
ConfigProbe ${ila0Name} {U_Core/GEN_PGP.U_Pgp/U_Pgp_Lane6/pgpTxMasters[0][tValid]}
ConfigProbe ${ila0Name} {U_Core/GEN_PGP.U_Pgp/U_Pgp_Lane6/pgpTxSlaves[0][tReady]}


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
