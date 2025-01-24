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

class SlowADC(pr.Device):
    def __init__( self, deviceCount=1,channelEnum={}, **kwargs):
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(name='enableADC',     offset=0x00,     bitOffset=0,   bitSize=1,   mode='RW',    base=pr.Bool,))
        self.add(pr.RemoteVariable(name='adcCoreRst',    offset=0x00,     bitOffset=1,   bitSize=1,   mode='RO',    base=pr.Bool,))
        self.add(pr.RemoteVariable(name='adcCoreStart',  offset=0x00,     bitOffset=2,   bitSize=1,   mode='RO',    base=pr.Bool,))
        self.add(pr.RemoteVariable(name='adcRdDone',     offset=0x00,     bitOffset=3,   bitSize=1,   mode='RO',    base=pr.Bool,))
        self.add(pr.RemoteVariable(name='adcDrdy',       offset=0x00,     bitOffset=4,   bitSize=1,   mode='RO',    base=pr.Bool,))
        self.add(pr.RemoteVariable(name='adcDeviceSel',  offset=0x00,     bitOffset=16,  bitSize=16,  mode='RO',    base=pr.UInt,))
        self.add(pr.RemoteVariable(name='selectedCh',    offset=0x04,     bitOffset=0,   bitSize=32,  mode='RO',    base=pr.UInt,))
        self.add(pr.RemoteVariable(name='autoTrig',      offset=0x08,     bitOffset=0,   bitSize=32,  mode='RW',    base=pr.UInt, disp = '{}'))
        self.add(pr.LinkVariable(  name='autoTrig_us',    description='autoTrig in us (AXI clk domain)',    mode='RW', units='uS', disp='{:1.3f}', linkedGet=self.timeConverterAppClock, linkedSet=self.reverseTimeConverterAppClock, dependencies = [self.autoTrig]))
        self.add(pr.RemoteVariable(name='doutreg',       offset=0x10,     bitOffset=0,   bitSize=8,   mode='RW',    base=pr.UInt,))

        for deviceIndex in range(deviceCount):
            for registerIndex in range(8): 
                if not channelEnum :
                    self.add(pr.RemoteVariable(name=f'ADC[{deviceIndex}][{registerIndex}]',         offset=0x20 * (deviceIndex+1) + registerIndex * 4,     bitOffset=0,   bitSize=32,  mode='RO',    base=pr.UInt, pollInterval = 1))
                else:
                    channelName = channelEnum[deviceIndex][registerIndex]
                    if channelName:
                        self.add(pr.RemoteVariable(name=f'ADC[{deviceIndex}][{registerIndex}]_{channelName}',         offset=0x20 * (deviceIndex+1) + registerIndex * 4,     bitOffset=0,   bitSize=32,  mode='RO',    base=pr.UInt, pollInterval = 1))


        self.add(pr.RemoteVariable(name='cmd_counter',   offset=0x14,     bitOffset=0,    bitSize=8,  mode='RO',    base=pr.Int,))
        self.add(pr.RemoteVariable(name='ch_counter',    offset=0x14,     bitOffset=8,    bitSize=8,  mode='RO',    base=pr.Int,))
        self.add(pr.RemoteVariable(name='wait_counter',  offset=0x14,     bitOffset=16,   bitSize=10, mode='RO',    base=pr.Int,))

        self.add(pr.RemoteVariable(name='csl_master',    offset=0x14,     bitOffset=31,   bitSize=1,  mode='RO',    base=pr.Bool,))
        self.add(pr.RemoteVariable(name='csl_cmd',       offset=0x14,     bitOffset=30,   bitSize=1,  mode='RO',    base=pr.Bool,))
        self.add(pr.RemoteVariable(name='spi_rd_en',     offset=0x14,     bitOffset=29,   bitSize=1,  mode='RO',    base=pr.Bool,))
        self.add(pr.RemoteVariable(name='wait_done',     offset=0x14,     bitOffset=28,   bitSize=1,  mode='RO',    base=pr.Bool,))
        self.add(pr.RemoteVariable(name='ref_clk_en',     offset=0x14,    bitOffset=27,   bitSize=1,  mode='RO',    base=pr.Bool,))

    @staticmethod   
    def timeConverterAppClock(var, read):
        """Converts a number of cycles in micro seconds."""
        raw = var.dependencies[0].get(read=read)
        #freq 156.25MHz
        return (raw / 156.25)

    @staticmethod   
    def reverseTimeConverterAppClock(var, value, write):
        """Converts micro seconds to cycles."""
        uS = value

        #freq 156.25MHz
        var.dependencies[0].set(value = int(uS * 156.25), write=write)
        return value