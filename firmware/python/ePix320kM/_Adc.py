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
        trigChEnum={0:'TrigReg', 1:'ThresholdChA', 2:'ThresholdChB', 3:'AcqStart', 4:'AsicAcq', 5:'AsicR0', 6:'AsicRoClk', 7:'AsicPpmat', 8:'AsicPpbe', 9:'AsicSync', 10:'AsicGr', 11:'AsicSaciSel0', 12:'AsicSaciSel1'}
        inChaEnum={0:'Off', 0:'Asic0TpsMux', 1:'Asic1TpsMux'}
        inChbEnum={0:'Off', 0:'Asic0TpsMux', 1:'Asic1TpsMux'}
        HsDacEnum={0:'None', 1:'DAC A (SE)', 2:'DAC B (Diff)', 3:'DAC A & DAC B'}

        AdcChannelEnum =[   ["CarrierTherm", "DigitalTherm", "Humidity", "I1V8A_0",     "IAn_ASIC0", "6AV",  "VAn1V8_0", "VAn2V5_ASIC0" ],
                            ["",             "",             "",         "I1V8A_1",     "IAn_ASIC1", "VCCA", "VAn1V8_1", "VAn2V5_ASIC1" ],
                            ["",             "",             "",         "IDig2V5",     "IAn_ASIC2", "6DV",  "VDig2V5",  "VAn2V5_ASIC2" ],
                            ["",             "",             "",         "DS_PLL_I",    "IAn_ASIC3", "VCC",  "VDS_PLL",  "VAn2V5_ASIC3" ] ]

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

        for i in range(4):
            self.add(epixHr.OscilloscopeRegisters(
                name       = f'Oscope[{i}]',
                offset     = (i+2)*0x0001_0000,
                trigChEnum = trigChEnum,
                inChaEnum  = inChaEnum,
                inChbEnum  = inChbEnum,
            ))

        for i in range(2):
            self.add(epixHr.MonAdcRegisters(
                name   = f'FastADCsDebug[{i}]',
                offset = (6+i)*0x0001_0000,
                enabled=False
            ))

        self.add(adi.Ad9249ConfigGroup(
            name   = 'FastADCsConfig',
            offset = 8*0x0001_0000,
            enabled= False
        ))
