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

#    constant SACI_INDEX_C         : natural  := 0;  -- 0:3
#    constant DESER_INDEX_C        : natural  := 4;
#    constant ASIC_INDEX_C         : natural  := 5;
#    constant PWR_INDEX_C          : natural  := 6;
#    constant ADC_INDEX_C          : natural  := 7;
#    constant DAC_INDEX_C          : natural  := 8;
#    constant TIMING_INDEX_C       : natural  := 9;


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
                offset      = 0x0500_0000+i*0x1000,
                numberLanes = 24,
            ))
        
        self.add(
            fpga.AsicTop(
                name='Asic Top',
                offset=0x0600_0000,
                expand=False,
                enabled=False
            )
        )

        self.add(
            fpga.PowerControl(
                name='Power Control',
                offset=0x0600_0000,
                expand=False,
                enabled=False
            )
        )
    
        # self.add(
        #     AdcGroup(
        #         name='Adcs',
        #         offset=0x0700_0000,
        #         expand=False,
        #         enabled=False
        #     )
        # )

        # self.add(
        #     DacGroup(
        #         name='Dacs',
        #         offset=0x0800_0000,
        #         expand=False,
        #         enabled=False
        #     )
        # )

        self.add(
            fpga.TimingRx(
                name='Timing Rx',
                offset=0x0900_0000,
                expand=False,
                enabled=False
            )
        )