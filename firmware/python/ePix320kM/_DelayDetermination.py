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
            name         = 'preTriggerTimeout',
            offset       = 0x4,
            bitSize      = 32,
            mode         = 'RW',
            base         = pr.UInt,
            disp         = '{}',
        ))

        self.add(pr.LinkVariable(  
            name='preTriggerTimeout_us',    
            description='PreTrigger timeout (axiLite domain - 156.25MHz)',   
            mode='RW', 
            units='uS', 
            disp='{:1.3f}', 
            linkedGet=self.timeConverter, 
            linkedSet=self.reverseTimeConverter, 
            dependencies = [self.preTriggerTimeout]
            ))
        
        self.add(pr.RemoteVariable(
            name         = 'postTriggerTimeout',
            offset       = 0x8,
            bitSize      = 32,
            mode         = 'RW',
            base         = pr.UInt,
            disp         = '{}',
        ))

        self.add(pr.LinkVariable(  
            name='postTriggerTimeout_us',    
            description='PostTrigger timeout (axiLite domain - 156.25MHz)',   
            mode='RW', 
            units='uS', 
            disp='{:1.3f}', 
            linkedGet=self.timeConverter, 
            linkedSet=self.reverseTimeConverter, 
            dependencies = [self.postTriggerTimeout]
            ))

        self.add(pr.RemoteVariable(
            name         = 'preResetTimeout',
            offset       = 0xC,
            bitSize      = 32,
            mode         = 'RW',
            base         = pr.UInt,
            disp         = '{}',
        ))

        self.add(pr.LinkVariable(  
            name='preResetTimeout_us',    
            description='PreReset timeout (axiLite domain - 156.25MHz)',   
            mode='RW', 
            units='uS', 
            disp='{:1.3f}', 
            linkedGet=self.timeConverter, 
            linkedSet=self.reverseTimeConverter, 
            dependencies = [self.preResetTimeout]
            ))


        self.add(pr.RemoteVariable(
            name         = 'asicEn',
            offset       = 0x20,
            bitSize      = numAsics,
            mode         = 'RW'
        ))

        self.add(pr.RemoteVariable(
            name         = 'state',
            offset       = 0x2C,
            bitSize      = numAsics,
            mode         = 'RO',
            bitOffset    = 0,
            pollInterval = 1,
            #enum         = stateEnum,
        ))   
        
        self.add(pr.RemoteCommand(
            name         = 'Start',
            offset       = 0x24,
            bitSize      = 1,
            bitOffset    = 0,
            function     = pr.Command.touchOne
        ))

        self.add(pr.RemoteCommand(
            name         = 'Stop',
            offset       = 0x28,
            bitSize      = 1,
            bitOffset    = 0,
            function     = pr.Command.touchOne
        ))


    @staticmethod   
    def timeConverter(var, read):
        raw = var.dependencies[0].get(read=read)
        return ((1/156.25) * raw)

    @staticmethod   
    def reverseTimeConverter(var, value, write):
        freq = 156.25
        var.dependencies[0].set(value=int(value/(1/freq)), write=write)
        return value
   