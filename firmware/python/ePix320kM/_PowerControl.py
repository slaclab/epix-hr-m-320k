import pyrogue as pr

class PowerControl(pr.Device):
    def __init__(self, **kwargs):      
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name         = 'PwrEnable6V',
            offset       = 0x0,
            bitSize      = 1,
            mode         = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name         = 'PwrEnAna',
            offset       = 0x4,
            bitSize      = 2,
            mode         = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name         = 'PwrEnDig',
            offset       = 0x8,
            bitSize      = 5,
            mode         = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name         = 'PwrGood',
            offset       = 0xC,
            bitSize      = 2,
            mode         = 'RO',
            pollInterval = 1,
        ))