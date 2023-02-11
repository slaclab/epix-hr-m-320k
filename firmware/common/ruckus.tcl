# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load application
loadSource -dir  "$::DIR_PATH/application"

