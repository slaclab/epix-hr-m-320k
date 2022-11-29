# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load core
loadSource -dir  "$::DIR_PATH/core"

# Load application
loadSource -dir  "$::DIR_PATH/application"

# Adding the default Si5345 configuration
add_files -norecurse "$::DIR_PATH/pll-config/ePix320kMPllConfig.mem"
