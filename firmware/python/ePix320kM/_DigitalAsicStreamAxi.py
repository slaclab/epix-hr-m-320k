#-----------------------------------------------------------------------------
# This file is part of the 'ePix-320k-M'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'ePix-320k-M', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue as pr

class DigitalAsicStreamAxi(pr.Device):
   def __init__(self, numberLanes=1, **kwargs):
      super().__init__(description='Asic data packet registers', **kwargs)
      
      #Setup registers & variables
      
      self.add(
        pr.RemoteVariable(
            name='FrameCount',
            description='FrameCount',
            offset=0x00000000,
            bitSize=32,
            bitOffset=0, 
            base=pr.UInt, 
            disp = '{}', 
            mode='RO')
        )

      self.add(
        pr.RemoteVariable(
            name='FrameSize',
            description='FrameSize',
            offset=0x00000004, 
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            disp = '{}',
            mode='RO')
        )

      self.add(
        pr.RemoteVariable(
            name='FrameMaxSize',
            description='FrameMaxSize',
            offset=0x00000008, 
            bitSize=16,
            bitOffset=0,
            base=pr.UInt, 
            disp = '{}',
            mode='RO')
        )

      self.add(
        pr.RemoteVariable(
            name='FrameMinSize',
            description='FrameMinSize',
            offset=0x0000000C,
            bitSize=16,
            bitOffset=0,
            base=pr.UInt,
            disp = '{}',
            mode='RO')
        )

      #self.add
      # (pr.RemoteVariable(name='ResetCounters',   description='ResetCounters',                               offset=0x00000024, bitSize=1,   bitOffset=0, base=pr.Bool, mode='WO'))
      self.add(
        pr.RemoteVariable(
            name='asicDataReq',
            description='Number of samples requested per ADC stream.', 
            offset=0x00000028,
            bitSize=16,
            bitOffset=0, 
            base=pr.UInt, 
            disp = '{}', 
            mode='RW')
            )

      self.add(
        pr.RemoteVariable(
            name='DisableLane',
            description='Disable selected lanes.',
            offset=0x0000002C, 
            bitSize=numberLanes,
            bitOffset=0, 
            base=pr.UInt, 
            mode='RW')
            )

      self.add(
        pr.RemoteVariable(
            name='EnumerateDisLane',
            description='Insert lane number into disabled lane.',
            offset=0x00000030, 
            bitSize=numberLanes, 
            bitOffset=0, 
            base=pr.UInt,
            mode='RW')
            )
      
      self.addRemoteVariables(
         name         = 'TimeoutCntLane',
         offset       = 0x100,
         bitSize      = 16,
         mode         = 'RO',
         number       = numberLanes,
         stride       = 4,
         pollInterval = 1,
         disp         = '{}', 
      )
      
      self.addRemoteVariables(
         name         = 'DataCntLaneAct',
         offset       = 0x200,
         bitSize      = 16,
         mode         = 'RO',
         number       = numberLanes,
         stride       = 4,
         pollInterval = 1,
         disp         = '{}', 
      )
      
      self.addRemoteVariables(
         name         = 'DataCntLaneReg',
         offset       = 0x300,
         bitSize      = 16,
         mode         = 'RO',
         number       = numberLanes,
         stride       = 4,
         pollInterval = 1,
         disp         = '{}', 
      )
      
      self.addRemoteVariables(
         name         = 'DataCntLaneMin',
         offset       = 0x400,
         bitSize      = 16,
         mode         = 'RO',
         number       = numberLanes,
         stride       = 4,
         pollInterval = 1,
         disp         = '{}', 
      )
      
      self.addRemoteVariables(
         name         = 'DataCntLaneMax',
         offset       = 0x500,
         bitSize      = 16,
         mode         = 'RO',
         number       = numberLanes,
         stride       = 4,
         pollInterval = 1,
         disp         = '{}', 
      )
      
      self.addRemoteVariables(
         name         = 'DataDlyLaneReg',
         offset       = 0x600,
         bitSize      = 16,
         mode         = 'RO',
         number       = numberLanes,
         stride       = 4,
         pollInterval = 1,
         disp         = '{}',  
      )
      
      self.addRemoteVariables(
         name         = 'DataOvfLane',
         offset       = 0x700,
         bitSize      = 16,
         mode         = 'RO',
         number       = numberLanes,
         stride       = 4,
         pollInterval = 1,
         disp         = '{}', 
      )

      self.add(pr.RemoteCommand(name='CountReset', description='Resets counters', 
                             offset=0x00000024, bitSize=1, bitOffset=0, function=pr.Command.touchOne))
      