# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

loadSource -lib epix_hr_leap_common -dir "$::DIR_PATH/epix-hr-leap_common"

# Load application
loadSource -dir  "$::DIR_PATH/application"

