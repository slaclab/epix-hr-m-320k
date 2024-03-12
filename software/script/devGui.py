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
import time
import argparse

import pyrogue as pr
import pyrogue.pydm
import os

import ePix320kM as devBoard

#################################################################

top_level=f'{os.getcwd()}/'# point to the software folder

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
        "--pciePgpEn",
        type     = str,
        required = False,
        default  = False,
        help     = "Enable axi-pcie-core reading",
    )

    

    parser.add_argument(
        "--pollEn",
        type     = argBool,
        required = False,
        default  = True,
        help     = "Enable auto-polling",
    )

    parser.add_argument(
        "--initRead",
        type     = argBool,
        required = False,
        default  = True,
        help     = "Enable read all variables at start",
    )

    parser.add_argument(
        "--guiType",
        type     = str,
        required = False,
        default  = 'PyDM',
        help     = "Sets the GUI type (PyDM or None)",
    )

    parser.add_argument(
        "--serverPort",
        type     = int,
        required = False,
        default  = 9099,
        help     = "Zeromq server port",
    )

    parser.add_argument(
        "--justCtrl",
        type     = argBool,
        required = False,
        default  = False,
        help     = "Enable acessing AXI registers only",
    )

    # Get the arguments
    args = parser.parse_args()

    #################################################################

    with devBoard.Root(
        top_level  = top_level,
        dev        = args.dev,
        pollEn     = args.pollEn,
        initRead   = args.initRead,
        pciePgpEn  = args.pciePgpEn,
        justCtrl   = args.justCtrl,
        fullRateDataReceiverEn = False
    ) as root:

        ######################
        # Development PyDM GUI
        ######################
        if (args.guiType == 'PyDM'):
            pyrogue.pydm.runPyDM(
                serverList=root.zmqServer.address,
                root  = root,
                sizeX = 800,
                sizeY = 800,
            )

        #################
        # No GUI
        #################
        elif (args.guiType == 'None'):

            # Wait to be killed via Ctrl-C
            print('Running root server.  Hit Ctrl-C to exit')
            while (root._running):
                time.sleep(1)

        ####################
        # Undefined GUI type
        ####################
        else:
            raise ValueError("Invalid GUI type (%s)" % (args.guiType) )

      
    #################################################################
