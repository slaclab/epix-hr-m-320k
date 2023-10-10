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

class Adc(pr.Device):
    def __init__( self,**kwargs):
        super().__init__(**kwargs)

        # TODO: Someone should update these emulation in the future then delete this comment
        trigChEnum={0:'TrigReg', 1:'ThresholdChA', 2:'ThresholdChB', 3:'AcqStart', 4:'AsicAcq', 5:'AsicR0', 6:'AsicRoClk', 7:'AsicPpmat', 8:'AsicPpbe', 9:'AsicSync', 10:'AsicGr', 11:'AsicSaciSel0', 12:'AsicSaciSel1'}
        inChaEnum={0:'Off', 0:'Asic0TpsMux', 1:'Asic1TpsMux'}
        inChbEnum={0:'Off', 0:'Asic0TpsMux', 1:'Asic1TpsMux'}
        HsDacEnum={0:'None', 1:'DAC A (SE)', 2:'DAC B (Diff)', 3:'DAC A & DAC B'}

        AdcChannelEnum =[  ["Therm[0]", "Therm[1]", "ANA_PWR_RAW_DIVIDED", "ASIC_C0_AVDD_IMON", "ASIC_C0_DVDD_IMON", "ASIC_C1_AVDD_IMON", "ASIC_C1_DVDD_IMON","ASIC_C2_AVDD_IMON", "Unused" ],
                            ["Therm[2]", "Therm[3]", "ASIC_C2_DVDD_IMON", "ASIC_C3_DVDD_IMON", "ASIC_C3_AVDD_IMON", "ASIC_C4_DVDD_IMON", "ASIC_C4_AVDD_IMON","HUMIDITY", "Unused" ],
                            ["Therm[4]", "Therm[5]", "ASIC_C0_V2_5A", "ASIC_C1_V2_5A", "ASIC_C2_V2_5A", "ASIC_C3_V2_5A", "ASIC_C4_V2_5A","DIG_PWR_RAW_DIVIDED", "Unused" ],
                            ["THERMISTOR_SENSE[0]", "THERMISTOR_SENSE[1]", "HUMIDITY", "MON_V_1V8", "MON_V_2V5", "7 Vout_6V_10A_IMON", "MON_V_VCC","RAW_VOLTAGE_MON", "Unused" ] ]

        for i in range(2):
            #ADC 1  Digital board
            #ADC 2  Power Communication board
            self.add(epixHr.SlowAdcRegisters(
                name    = f'AnSlowAdc[{i}]' if i != 3 else f'DigSlowAdc',
                offset  = i*0x0001_0000,
                AdcChannelEnum = AdcChannelEnum[i],
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
