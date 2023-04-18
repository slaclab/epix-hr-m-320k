import pyrogue as pr

class PowerControl(pr.Device):
    def __init__(self, **kwargs):      
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name         = 'PwrEnAna',
            offset       = 0x0,
            bitSize      = 2,
            mode         = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name         = 'PwrGood',
            offset       = 0x4,
            bitSize      = 2,
            mode         = 'RO',
            pollInterval = 1,
        ))