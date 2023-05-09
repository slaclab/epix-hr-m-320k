import pyrogue as pr

class PowerControl(pr.Device):
    def __init__(self, **kwargs):      
        super().__init__(**kwargs)

        self.add(pr.RemoteVariable(
            name         = 'DigitalSupplyEn',
            offset       = 0x0,
            bitSize      = 2,
            mode         = 'RW',
        ))

        self.add(pr.RemoteVariable(
            name         = 'CBSupplyGood',
            offset       = 0x4,
            bitSize      = 1,
            mode         = 'RO',
            bitOffset    = 0,
            pollInterval = 1,
        ))

        self.add(pr.RemoteVariable(
            name         = 'Analog6VGood',
            offset       = 0x4,
            bitSize      = 1,
            mode         = 'RO',
            bitOffset    = 1,
            pollInterval = 1,
        ))