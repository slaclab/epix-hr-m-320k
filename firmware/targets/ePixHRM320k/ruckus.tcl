############################
# DO NOT EDIT THE CODE BELOW
############################

# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodules' code and constraints
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/submodules/lcls-timing-core
loadRuckusTcl $::env(TOP_DIR)/submodules/epix-hr-core/shared
loadRuckusTcl $::env(TOP_DIR)/submodules/epix-hr-leap-common
loadRuckusTcl $::env(TOP_DIR)/common

# Load the l2si-core source code
loadSource -lib l2si_core -dir "$::env(TOP_DIR)/submodules/l2si-core/xpm/rtl"
loadSource -lib l2si_core -dir "$::env(TOP_DIR)/submodules/l2si-core/base/rtl"

# Load target's source code and constraints
loadSource      -dir  "$::DIR_PATH/hdl/"
loadConstraints -dir  "$::DIR_PATH/hdl/"

# Load local SIM source Code
loadSource -sim_only -dir "$::DIR_PATH/tb"
set_property top {ePixHRM320kTb} [get_filesets sim_1]
#set_property top {chargeInjectionTb} [get_filesets sim_1]

