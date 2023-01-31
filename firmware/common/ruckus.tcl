# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# loadSource -lib epix_hr_core -dir "$::DIR_PATH/epix-hr-core"

# Load application
loadSource -dir  "$::DIR_PATH/application"

