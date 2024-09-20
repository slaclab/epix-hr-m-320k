import pyrogue as pr

class ChargeInjection(pr.Device):
    def __init__(self, **kwargs):      
        super().__init__(**kwargs)

        statusEnum = {0: "IDLE_S", 1: "RUNNING_S", 2: "SUCCESS_S", 3: "ERROR_S"}

        self.add(pr.RemoteVariable(
            name         = 'startCol',
            offset       = 0x0,
            bitSize      = 9,
            mode         = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name         = 'endCol',
            offset       = 0x4,
            bitSize      = 9,
            mode         = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name         = 'step',
            offset       = 0x8,
            bitSize      = 9,
            mode         = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name         = 'start',
            offset       = 0xC,
            bitSize      = 1,
            mode         = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name         = 'triggerWaitCycles',
            offset       = 0x10,
            bitSize      = 32,
            mode         = 'RW',
            base         = pr.UInt
        ))


        self.add(pr.RemoteVariable(
            name         = 'currentAsic',
            offset       = 0x14,
            bitSize      = 2,
            mode         = 'RW',
        ))


        self.add(pr.RemoteVariable(
            name         = 'pulser',
            offset       = 0x20,
            bitSize      = 10,
            mode         = 'RO',
            bitOffset    = 0,
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'currentCol',
            offset       = 0x24,
            bitSize      = 9,
            mode         = 'RO',
            bitOffset    = 0,
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'activated',
            offset       = 0x28,
            bitSize      = 1,
            mode         = 'RO',
            bitOffset    = 0,
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'status',
            offset       = 0x2C,
            bitSize      = 2,
            mode         = 'RO',
            bitOffset    = 0,
            pollInterval = 1,
            enum         = statusEnum,
        ))                
