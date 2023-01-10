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

create_clock -name gtPllClkP0    -period 3.125 [get_ports { gtPllClkP[0] }]
create_clock -name gtPllClkP1    -period 3.125 [get_ports { gtPllClkP[1] }]
create_clock -name gtRefClkP0    -period 6.400 [get_ports { gtRefClkP[0] }]
create_clock -name gtRefClkP1    -period 6.400 [get_ports { gtRefClkP[1] }]
create_clock -name gtLclsClkP    -period 2.691 [get_ports { gtLclsClkP }]
create_clock -name adcMonClkP0   -period 2.857 [get_ports { adcMonDataClkP[0] }]
create_clock -name adcMonClkP1   -period 2.857 [get_ports { adcMonDataClkP[1] }]

set_clock_groups -asynchronous \
   -group [get_clocks -include_generated_clocks {gtLclsClkP}] \
   -group [get_clocks -include_generated_clocks {gtRefClkP0}] \
   -group [get_clocks -include_generated_clocks {gtRefClkP1}] \
   -group [get_clocks -include_generated_clocks {adcMonClkP0}] \
   -group [get_clocks -include_generated_clocks {adcMonClkP1}]