import pyrogue as pr

class DelayDetermination(pr.Device):
    def __init__(self, numAsics, **kwargs):      
        super().__init__(**kwargs)

        stateEnum  = { 0: "Idle", 1: "Running"}
                
        self.add(pr.RemoteVariable(
            name         = 'Step',
            offset       = 0x0,
            bitSize      = 9,
            mode         = 'RW',
            base         = pr.UInt,
            disp         = '{}',
        ))

        self.add(pr.RemoteVariable(
            name         = 'triggerTimeout',
            offset       = 0x4,
            bitSize      = 32,
            mode         = 'RW',
            base         = pr.UInt,
            disp         = '{}',
        ))


        self.add(pr.RemoteVariable(
            name         = 'asicEn',
            offset       = 0x8,
            bitSize      = numAsics,
            mode         = 'RW'
        ))

        self.add(pr.RemoteCommand(
            name         = 'Start',
            offset       = 0xC,
            bitSize      = 1,
            bitOffset    = 0,
            function     = pr.Command.touchOne
        ))

        self.add(pr.RemoteCommand(
            name         = 'Stop',
            offset       = 0x10,
            bitSize      = 1,
            bitOffset    = 0,
            function     = pr.Command.touchOne
        ))

        self.add(pr.RemoteVariable(
            name         = 'state',
            offset       = 0x14,
            bitSize      = 1,
            mode         = 'RO',
            bitOffset    = 0,
            pollInterval = 1,
            enum         = stateEnum,
        ))   