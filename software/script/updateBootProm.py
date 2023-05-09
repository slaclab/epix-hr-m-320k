#!/usr/bin/env python3
#-----------------------------------------------------------------------------
# This file is part of the 'Simple-PGPv4-KCU105-Example'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'Simple-PGPv4-KCU105-Example', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------
import setupLibPaths

import sys
import argparse
import glob
import time
from collections import OrderedDict as odict
import pyrogue as pr

import ePix320kM as devBoard

#################################################################

if __name__ == "__main__":

    # Convert str to bool
    argBool = lambda s: s.lower() in ['true', 't', 'yes', '1']

    # Set the argument parser
    parser = argparse.ArgumentParser()

    # Add arguments
    parser.add_argument(
        "--dev",
        type     = str,
        required = False,
        default  = '/dev/datadev_0',
        help     = "axi-pcie-core device",
    )

    parser.add_argument(
        "--mcs",
        type     = str,
        required = True,
        help     = "path to mcs file",
    )

    # Get the arguments
    args = parser.parse_args()

    #################################################################

    with devBoard.Root(     
        dev      = args.dev,
        pollEn   = False,
        initRead = True,
        promProg = True,
    ) as root:

        # Create useful pointers
        AxiVersion    = root.Core.AxiVersion
        AxiMicronN25Q = root.Core.AxiMicronN25Q

        # Printout Current AxiVersion status
        print ( '###################################################')
        print ( '#                 Old Firmware                    #')
        print ( '###################################################')
        AxiVersion.printStatus()

        # Load the primary MCS file
        AxiMicronN25Q.LoadMcsFile(args.mcs)

        # Check if programming was successful
        if (AxiMicronN25Q._progDone):
            print('\nReloading FPGA firmware from PROM ....')
            AxiVersion.FpgaReload()
            time.sleep(10)
            print('\nReloading FPGA done')

            print ( '###################################################')
            print ( '#                 New Firmware                    #')
            print ( '###################################################')
            AxiVersion.printStatus()
        else:
            print('Failed to program FPGA')

    #################################################################
