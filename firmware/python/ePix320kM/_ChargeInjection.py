import pyrogue as pr

class ChargeInjection(pr.Device):
    def __init__(self, **kwargs):      
        super().__init__(**kwargs)

        statusEnum = {0: "IDLE_S", 1: "RUNNING_S", 2: "SUCCESS_S", 3: "AXI_ERROR_S",
                      4: "COL_ERROR_S", 5: "STEP_ERROR_S", 6: "STOP_S"}
        stateEnum  = { 0: "WAIT_START_S", 1: "FE_XX2GR_S", 2: "TEST_START_S", 3: "PULSER_S", 
                   4: "CHARGE_COL_S", 5: "CLK_NEGEDGE_S", 6: "CLK_POSEDGE_S", 7: "TRIGGER_S",
                   8: "TEST_END_S" , 9: "ERROR_S", 10: "INIT_S", 11: "CACHE408C_S",
                    12 : "CACHE400C_S", 13: "CACHE4068_S"}

        self.add(pr.RemoteVariable(
            name         = 'startCol',
            offset       = 0x0,
            bitSize      = 9,
            mode         = 'RW',
            base         = pr.UInt,
            disp         = '{}',
        ))

        self.add(pr.RemoteVariable(
            name         = 'endCol',
            offset       = 0x4,
            bitSize      = 9,
            mode         = 'RW',
            base         = pr.UInt,
            disp         = '{}',
        ))

        self.add(pr.RemoteVariable(
            name         = 'step',
            offset       = 0x8,
            bitSize      = 9,
            mode         = 'RW',
            base         = pr.UInt,
            disp         = '{}',
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
            name         = 'triggerWaitCycles',
            offset       = 0x14,
            bitSize      = 32,
            mode         = 'RW',
            base         = pr.UInt,
            disp         = '{}',
        ))


        self.add(pr.RemoteVariable(
            name         = 'currentAsic',
            offset       = 0x18,
            bitSize      = 2,
            mode         = 'RW',
            base         = pr.UInt,
            disp         = '{}',
        ))


        self.add(pr.RemoteVariable(
            name         = 'pulser',
            offset       = 0x20,
            bitSize      = 10,
            mode         = 'RO',
            bitOffset    = 0,
            pollInterval = 1,
            base         = pr.UInt,
            disp         = '{}',            
        ))

        self.add(pr.RemoteVariable(
            name         = 'currentCol',
            offset       = 0x24,
            bitSize      = 9,
            mode         = 'RO',
            bitOffset    = 0,
            pollInterval = 1,
            base         = pr.UInt,
            disp         = '{}',
        ))

        self.add(pr.RemoteVariable(
            name         = 'failingRegister',
            offset       = 0x28,
            bitSize      = 32,
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


        self.add(pr.RemoteVariable(
            name         = 'state',
            offset       = 0x30,
            bitSize      = 8,
            mode         = 'RO',
            bitOffset    = 0,
            pollInterval = 1,
            enum         = stateEnum,
        ))       

        self.add(pr.RemoteVariable(
            name         = 'stateLast',
            offset       = 0x34,
            bitSize      = 8,
            mode         = 'RO',
            bitOffset    = 0,
            pollInterval = 1,
            enum         = stateEnum,
        ))

        self.add(pr.RemoteVariable(
            name         = 'triggerStateCounter',
            offset       = 0x38,
            bitSize      = 32,
            mode         = 'RO',
            bitOffset    = 0,
            pollInterval = 1,
            base         = pr.UInt,
            disp         = '{}',
        ))