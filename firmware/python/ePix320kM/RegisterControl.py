

import pyrogue as pr

##################################################################################
# ePix hr ePix M app register control
##################################################################################


class RegisterControl(pr.Device):
    def __init__(self, **kwargs):
        """Create the configuration device for HR Gen1 core FPGA registers"""
        super().__init__(description='ePix M Waveform Generation', **kwargs)

        # Creation. memBase is either the register bus server (srp, rce mapped memory, etc) or the device which
        # contains this object. In most cases the parent and memBase are the same but they can be
        # different in more complex bus structures. They will also be different for the top most node.
        # The setMemBase call can be used to update the memBase for this Device. All sub-devices and local
        # blocks will be updated.

        #############################################
        # Create block / variable combinations
        #############################################

        # Setup registers & variables

        self.add(
            pr.RemoteVariable(
                name='Version',
                description='Version',
                offset=0x00000000,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                verify=False,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='GlblRstPolarity',
                description='GlblRstPolarity',
                offset=0x0000010C,
                bitSize=1,
                bitOffset=0,
                base=pr.Bool,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='AcqPolarity',
                description='AcqPolarity',
                offset=0x00000118,
                bitSize=1,
                bitOffset=0,
                base=pr.Bool,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='AcqDelay1',
                description='AcqDelay',
                offset=0x0000011C,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='AcqWidth1',
                description='AcqWidth',
                offset=0x00000120,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='AcqDelay2',
                description='AcqDelay',
                offset=0x00000124,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='AcqWidth2',
                description='AcqWidth',
                offset=0x00000128,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='TPulsePolarity',
                description='Polarity',
                offset=0x0000012C,
                bitSize=1,
                bitOffset=0,
                base=pr.Bool,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='TPulseDelay',
                description='Delay',
                offset=0x00000130,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='TPulseWidth',
                description='Width',
                offset=0x00000134,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='R0Polarity',
                description='Polarity',
                offset=0x00000138,
                bitSize=1,
                bitOffset=0,
                base=pr.Bool,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='R0Delay',
                description='Delay',
                offset=0x0000013C,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='R0Width',
                description='Width',
                offset=0x00000140,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='PPbePolarity',
                description='PPbePolarity',
                offset=0x00000144,
                bitSize=1,
                bitOffset=0,
                base=pr.Bool,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='PPbeDelay',
                description='PPbeDelay',
                offset=0x00000148,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='PPbeWidth',
                description='PPbeWidth',
                offset=0x0000014C,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='PpmatPolarity',
                description='PpmatPolarity',
                offset=0x00000150,
                bitSize=1,
                bitOffset=0,
                base=pr.Bool,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='PpmatDelay',
                description='PpmatDelay',
                offset=0x00000154,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='PpmatWidth',
                description='PpmatWidth',
                offset=0x00000158,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='SyncPolarity',
                description='SyncPolarity',
                offset=0x0000015C,
                bitSize=1,
                bitOffset=0,
                base=pr.Bool,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='SyncDelay',
                description='SyncDelay',
                offset=0x00000160,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='SyncWidth',
                description='SyncWidth',
                offset=0x00000164,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='SaciSyncPolarity',
                description='SaciSyncPolarity',
                offset=0x00000168,
                bitSize=1,
                bitOffset=0,
                base=pr.Bool,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='SaciSyncDelay',
                description='SaciSyncDelay',
                offset=0x0000016C,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='SaciSyncWidth',
                description='SaciSyncWidth',
                offset=0x00000170,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='SR0Polarity',
                description='SR0Polarity',
                offset=0x00000174,
                bitSize=1,
                bitOffset=0,
                base=pr.Bool,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='SR0Delay1',
                description='SR0Delay1',
                offset=0x00000178,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='SR0Width1',
                description='SR0Width1',
                offset=0x0000017C,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='SR0Delay2',
                description='SR0Delay2',
                offset=0x000001AC,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='SR0Width2',
                description='SR0Width2',
                offset=0x000001B0,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='ePixAdcSHPeriod',
                description='Period',
                offset=0x000001A4,
                bitSize=16,
                bitOffset=0,
                base=pr.UInt,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='AcqCnt',
                description='AcqCnt',
                offset=0x00000200,
                bitSize=32,
                bitOffset=0,
                base=pr.UInt,
                mode='RO'
            ))

        self.add(
            pr.RemoteVariable(
                name='ResetCounters',
                description='ResetCounters',
                offset=0x00000208,
                bitSize=1,
                bitOffset=0,
                base=pr.Bool,
                mode='RW'
            ))

        self.add(
            pr.RemoteVariable(
                name='ClkEn',
                description='ClkEn',
                offset=0x000001A8,
                bitSize=1,
                bitOffset=0,
                base=pr.Bool,
                mode='RW'
            ))

        #####################################
        # Create commands
        #####################################

        # A command has an associated function. The function can be a series of
        # python commands in a string. Function calls are executed in the command scope
        # the passed arg is available as 'arg'. Use 'dev' to get to device scope.
        # A command can also be a call to a local function with local scope.
        # The command object and the arg are passed

    @staticmethod
    def frequencyConverter(self):
        def func(dev, var):
            return '{:.3f} kHz'.format(1/(self.clkPeriod * self._count(var.dependencies)) * 1e-3)
        return func
