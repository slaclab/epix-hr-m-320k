##############################################################################
## This file is part of 'epix-320kM'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'ATLAS ATCA LINK AGG DEV', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

###############
# Common Clocks
###############

create_clock -period 4.000 -name gtPllClkP [get_ports gtPllClkP]
create_clock -period 6.400 -name gtRefClkP0 [get_ports {gtRefClkP[0]}]
create_clock -period 6.400 -name gtRefClkP1 [get_ports {gtRefClkP[1]}]
#create_clock -name fpgaClkInP    -period 4     [get_ports { fpgaClkInP }]
create_clock -period 2.691 -name gtLclsClkP [get_ports gtLclsClkP]
create_clock -period 2.857 -name adcMonClkP0 [get_ports {adcMonDataClkP[0]}]
create_clock -period 2.857 -name adcMonClkP1 [get_ports {adcMonDataClkP[1]}]

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks gtLclsClkP] -group [get_clocks -include_generated_clocks gtRefClkP0] -group [get_clocks -include_generated_clocks gtRefClkP1] -group [get_clocks -include_generated_clocks adcMonClkP0] -group [get_clocks -include_generated_clocks adcMonClkP1]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/GEN_PGP.U_axilClock/PllGen.U_Pll/CLKOUT0]] -group [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe4_top.Pgp3GthUsIp10G_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O}]] -group [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe4_top.Pgp3GthUsIp10G_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O}]] -group [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *U_Pgp3GthUsIpWrapper_1/GEN_10G.U_Pgp3GthUsIp/inst/gen_gtwizard_gthe4_top.Pgp3GthUsIp10G_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[2].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST/RXOUTCLKPCS}]]

create_generated_clock -name timingGtRxOut [get_pins {U_App/U_TimingRx/GEN_GT.U_GTH/LOCREF_G.U_TimingGthCore/inst/gen_gtwizard_gthe4_top.TimingGth_fixedlat_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST/RXOUTCLK}]

create_generated_clock -name timingRefClkDiv2 [get_pins U_App/U_TimingRx/U_gtRefClk/ODIV2]

create_generated_clock -name timingRxRecClk -source [get_pins -hier -filter {name =~ U_App/U_TimingRx/U_rxUsrClk/I0}] -divide_by 1 -add -master_clock timingGtRxOut [get_pins -hier -filter {name =~ U_App/U_TimingRx/U_rxUsrClk/O}]

create_generated_clock -name timingEmuRxClk -source [get_pins -hier -filter {name =~ U_App/U_TimingRx/U_rxUsrClk/I1}] -divide_by 1 -add -master_clock timingRefClkDiv2 [get_pins -hier -filter {name =~ U_App/U_TimingRx/U_rxUsrClk/O}]

set_clock_groups -physically_exclusive -group timingRxRecClk -group timingEmuRxClk

set_false_path -to [get_pins -hier -filter {name =~ U_App/U_TimingRx/U_rxUsrClk/CE*}]

set_clock_groups -asynchronous -group [get_clocks timingEmuRxClk] -group [get_clocks -of_objects [get_pins U_Core/GEN_PGP.U_axilClock/PllGen.U_Pll/CLKOUT0]]

set_clock_groups -asynchronous -group [get_clocks timingRxRecClk] -group [get_clocks -of_objects [get_pins U_Core/GEN_PGP.U_axilClock/PllGen.U_Pll/CLKOUT0]]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_App/U_TimingRx/GEN_GT.U_GTH/LOCREF_G.U_TimingGthCore/inst/gen_gtwizard_gthe4_top.TimingGth_fixedlat_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST/RXOUTCLK}]] -group [get_clocks timingEmuRxClk]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_App/U_TimingRx/U_gtRefClk/ODIV2]] -group [get_clocks timingRxRecClk]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins {U_App/U_TimingRx/GEN_GT.U_GTH/LOCREF_G.U_TimingGthCore/inst/gen_gtwizard_gthe4_top.TimingGth_fixedlat_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[0].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST/RXOUTCLK}]] -group [get_clocks timingRxRecClk]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_App/U_AppClk/U_clk62p5/O]] -group [get_clocks -of_objects [get_pins U_Core/GEN_PGP.U_axilClock/PllGen.U_Pll/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U_Core/GEN_PGP.U_axilClock/PllGen.U_Pll/CLKOUT0]] -group [get_clocks gtPllClkP]
