#-----------------------------------------------------------------------------
# This file is part of the 'epix-320k-m'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'Development Board Examples', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------


import pyrogue as pr

import surf
import surf.devices.micron as micron
# from  surf.xilinx import ClockManager as MMCM7Registers

from .ClockManager import MMCM7Registers
from .RegisterControl import RegisterControl
from .PowerControl  import PowerControl


class App(pr.Device):
    def __init__(self, sim=False, **kwargs):
        super().__init__(**kwargs)

        self.add(
            MMCM7Registers(
                name='MMCMRegisters',
                offset=0x0000_0000,
                expand=False,
                enabled=False
            )
        )

        self.add(
            RegisterControl(
                name='Register Control',
                offset=0x0100_0000,
                expand=False,
                enabled=False
            )
        )

        self.add(
            PowerControl(
                name='Power Control',
                offset=0x0200_0000,
                expand=False,
                enabled=False
            )
        )
