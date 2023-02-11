# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodules' code and constraints
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/submodules/l2si-core
loadRuckusTcl $::env(TOP_DIR)/submodules/lcls-timing-core
loadRuckusTcl $::env(TOP_DIR)/submodules/epix-hr-leap-common

# Load the l2si-core source code
loadSource -lib l2si_core -dir "$::env(TOP_DIR)/submodules/l2si-core/xpm/rtl"
loadSource -lib l2si_core -dir "$::env(TOP_DIR)/submodules/l2si-core/base/rtl"
loadSource -lib epix_hr_leap_core -dir "$::DIR_PATH/epix-hr-leap-common/core/rtl"
loadSource -lib epix_hr_leap_common -dir "$::DIR_PATH/epix-hr-leap-common/shared/rtl"