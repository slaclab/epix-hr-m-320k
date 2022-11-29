############################
# DO NOT EDIT THE CODE BELOW
############################

# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodules' code and constraints
# loadRuckusTcl $::env(TOP_DIR)/submodules/axi-pcie-core
loadRuckusTcl $::env(TOP_DIR)/submodules/epix-hr-core/shared
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
# loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/common

# Load target's source code and constraints
loadSource      -dir  "$::DIR_PATH/hdl/"
loadConstraints -dir  "$::DIR_PATH/hdl/"