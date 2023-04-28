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
import surf.protocols.ssp as ssp

import ePix320kM as fpga

class App(pr.Device):
    def __init__(self, sim=False, **kwargs):
        super().__init__(**kwargs)
        
        num_of_asics = 4
        
        for i in range(num_of_asics):
            self.add(
                fpga.EpixMv2Asic(
                    name='Mv2Asic[{}]'.format(i),
                    offset=0x0000_0000 + 0x0100_0000 * i,
                    expand=False,
                    enabled=False
                )
            )

        for i in range(num_of_asics):
            self.add(ssp.SspLowSpeedDecoderReg(
                name        = f'SspMonGrp[{i}]',
                offset      = 0x0400_0000+i*0x1000,
                numberLanes = 24,
                enabled=False
            ))
        
        self.add(
            fpga.AsicTop(
                name='AsicTop',
                offset=0x0500_0000,
                expand=False,
                enabled=False
            )
        )

        self.add(
            fpga.PowerControl(
                name='PowerControl',
                offset=0x0600_0000,
                expand=False,
                enabled=False
            )
        )
    
        self.add(
            fpga.Adc(
                name='Adcs',
                offset=0x0700_0000,
                expand=False,
                enabled=False
            )
        )

        self.add(
            fpga.TimingRx(
                name='TimingRx',
                offset=0x0900_0000,
                expand=False,
                enabled=False
            )
        )
