# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load Source Code
loadSource    -path "$::DIR_PATH/rtl/AxiStreamePixHrMv2DescrambleDescrambleWrapper.vhd"

# Load HLS zip
if { [get_ips AxiStreamePixHrMv2Descramble_0] eq ""  } {
   loadZipIpCore -dir "$::DIR_PATH/ip" -repo_path $::env(IP_REPO)
   create_ip -name AxiStreamePixHrMv2Descramble -vendor SLAC -library hls -version 1.0 -module_name AxiStreamePixHrMv2Descramble_0
}
