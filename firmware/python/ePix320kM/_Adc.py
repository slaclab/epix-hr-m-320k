#-----------------------------------------------------------------------------
# This file is part of the 'Simple-PGPv4-KCU105-Example'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'Simple-PGPv4-KCU105-Example', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr

import epix_hr_core                 as epixHr
import surf.devices.analog_devices  as adi
import ePix320kM as fpga

class Adc(pr.Device):
    def __init__( self,**kwargs):
        super().__init__(**kwargs)

        # TODO: Someone should update these emulation in the future then delete this comment
        trigChEnum={0:'TrigReg', 1:'ThresholdChA', 2:'ThresholdChB', 3:'AcqStart'}
        inChEnum=[ [ {0:'ASIC0_ANA_MON', 1:'ASIC1_ANA_MON'}, {0:'ASIC2_ANA_MON', 1:'ASIC3_ANA_MON'} ],
                   [ {0:'VAn2V5_ASIC0',  1:'VAn2V5_ASIC1' }, {0:'VAn2V5_ASIC2',  1:'VAn2V5_ASIC3' } ],
                   [ {0:'V_An1V8_0',     1:'V_An1V8_1'    }, {0:'VDig2V5',       1:'V_DS_PLL'} ]]


        AdcChannelEnum =[   ["CarrierTherm", "DigitalTherm", "Humidity", "I_1V8A_0",     "I_An_ASIC0", "6AV",  "V_An1V8_0", "V_An2V5_ASIC0" ],
                            ["",             "",             "",         "I_1V8A_1",     "I_An_ASIC1", "VCCA", "V_An1V8_1", "V_An2V5_ASIC1" ],
                            ["",             "",             "",         "I_Dig2V5",     "I_An_ASIC2", "6DV",  "V_Dig2V5",  "V_An2V5_ASIC2" ],
                            ["",             "",             "",         "I_DS_PLL",     "I_An_ASIC3", "VCC",  "V_DS_PLL",  "V_An2V5_ASIC3" ] ]

        #ADC 1  Digital board
        #ADC 2  Power Communication board
        self.add(fpga.SlowADC(
            name='DigSlowADC',
            offset= 0x00000_0000,
            deviceCount=4,
            channelEnum=AdcChannelEnum
        ))

        self.add(fpga.SlowADC(
            name='PCBSlowADC',
            offset= 0x00001_0000,
            deviceCount=1,
        ))

        for i in range(3):
            self.add(epixHr.OscilloscopeRegisters(
                name       = f'Oscope[{i}]',
                offset     = (i+2)*0x0001_0000,
                trigChEnum = trigChEnum,
                inChaEnum  = inChEnum[i][0],
                inChbEnum  = inChEnum[i][1],
            ))

        for i in range(2):
            self.add(epixHr.MonAdcRegisters(
                name   = f'FastADCsDebug[{i}]',
                offset = (6+i)*0x0001_0000,
                enabled=True
            ))

        self.add(adi.Ad9249ConfigGroup(
            name   = 'FastADCsConfig',
            offset = 8*0x0001_0000,
            enabled= True
        ))
