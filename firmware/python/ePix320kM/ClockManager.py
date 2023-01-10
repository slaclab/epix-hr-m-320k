


import pyrogue as pr




class MMCM7Registers(pr.Device):
   def __init__(self, **kwargs):
      super().__init__(description='MMCM Registers', **kwargs)

      # Creation. memBase is either the register bus server (srp, rce mapped memory, etc) or the device which
      # contains this object. In most cases the parent and memBase are the same but they can be
      # different in more complex bus structures. They will also be different for the top most node.
      # The setMemBase call can be used to update the memBase for this Device. All sub-devices and local
      # blocks will be updated.

      #############################################
      # Create block / variable combinations
      #############################################


      #Setup registers & variables

      self.add((
         pr.RemoteVariable(name='CLKOUT0PhaseMux',  description='CLKOUT0Reg1', offset=0x0000008*4, bitSize=3, bitOffset=13, base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT0HighTime',  description='CLKOUT0Reg1', offset=0x0000008*4, bitSize=6, bitOffset=6,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT0LowTime',   description='CLKOUT0Reg1', offset=0x0000008*4, bitSize=6, bitOffset=0,  base=pr.UInt, mode='RW')))
      self.add((
         pr.RemoteVariable(name='CLKOUT0Frac',      description='CLKOUT0Reg2', offset=0x0000009*4, bitSize=3, bitOffset=12, base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT0FracEn',    description='CLKOUT0Reg2', offset=0x0000009*4, bitSize=1, bitOffset=11, base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT0Edge',      description='CLKOUT0Reg2', offset=0x0000009*4, bitSize=1, bitOffset=7,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT0NoCount',   description='CLKOUT0Reg2', offset=0x0000009*4, bitSize=1, bitOffset=6,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT0DelayTime', description='CLKOUT0Reg2', offset=0x0000009*4, bitSize=6, bitOffset=0,  base=pr.UInt, mode='RW')))
      self.add((
         pr.RemoteVariable(name='CLKOUT1PhaseMux',  description='CLKOUT1Reg1', offset=0x000000A*4, bitSize=3, bitOffset=13, base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT1HighTime',  description='CLKOUT1Reg1', offset=0x000000A*4, bitSize=6, bitOffset=6,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT1LowTime',   description='CLKOUT1Reg1', offset=0x000000A*4, bitSize=6, bitOffset=0,  base=pr.UInt, mode='RW')))
      self.add((
         pr.RemoteVariable(name='CLKOUT1Edge',      description='CLKOUT1Reg2', offset=0x000000B*4, bitSize=1, bitOffset=7,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT1NoCount',   description='CLKOUT1Reg2', offset=0x000000B*4, bitSize=1, bitOffset=6,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT1DelayTime', description='CLKOUT1Reg2', offset=0x000000B*4, bitSize=6, bitOffset=0,  base=pr.UInt, mode='RW')))
      self.add((
         pr.RemoteVariable(name='CLKOUT2PhaseMux',  description='CLKOUT2Reg1', offset=0x000000C*4, bitSize=3, bitOffset=13, base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT2HighTime',  description='CLKOUT2Reg1', offset=0x000000C*4, bitSize=6, bitOffset=6,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT2LowTime',   description='CLKOUT2Reg1', offset=0x000000C*4, bitSize=6, bitOffset=0,  base=pr.UInt, mode='RW')))
      self.add((
         pr.RemoteVariable(name='CLKOUT2Edge',      description='CLKOUT2Reg2', offset=0x000000D*4, bitSize=1, bitOffset=7,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT2NoCount',   description='CLKOUT2Reg2', offset=0x000000D*4, bitSize=1, bitOffset=6,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT2DelayTime', description='CLKOUT2Reg2', offset=0x000000D*4, bitSize=6, bitOffset=0,  base=pr.UInt, mode='RW')))
      self.add((
         pr.RemoteVariable(name='CLKOUT3PhaseMux',  description='CLKOUT3Reg1', offset=0x000000E*4, bitSize=3, bitOffset=13, base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT3HighTime',  description='CLKOUT3Reg1', offset=0x000000E*4, bitSize=6, bitOffset=6,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT3LowTime',   description='CLKOUT3Reg1', offset=0x000000E*4, bitSize=6, bitOffset=0,  base=pr.UInt, mode='RW')))
      self.add((
         pr.RemoteVariable(name='CLKOUT3Edge',      description='CLKOUT3Reg2', offset=0x000000F*4, bitSize=1, bitOffset=7,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT3NoCount',   description='CLKOUT3Reg2', offset=0x000000F*4, bitSize=1, bitOffset=6,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT3DelayTime', description='CLKOUT3Reg2', offset=0x000000F*4, bitSize=6, bitOffset=0,  base=pr.UInt, mode='RW')))
      self.add((
         pr.RemoteVariable(name='CLKOUT4PhaseMux',  description='CLKOUT4Reg1', offset=0x0000010*4, bitSize=3, bitOffset=13, base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT4HighTime',  description='CLKOUT4Reg1', offset=0x0000010*4, bitSize=6, bitOffset=6,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT4LowTime',   description='CLKOUT4Reg1', offset=0x0000010*4, bitSize=6, bitOffset=0,  base=pr.UInt, mode='RW')))
      self.add((
         pr.RemoteVariable(name='CLKOUT4Edge',      description='CLKOUT4Reg2', offset=0x0000011*4, bitSize=1, bitOffset=7,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT4NoCount',   description='CLKOUT4Reg2', offset=0x0000011*4, bitSize=1, bitOffset=6,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT4DelayTime', description='CLKOUT4Reg2', offset=0x0000011*4, bitSize=6, bitOffset=0,  base=pr.UInt, mode='RW')))
      self.add((
         pr.RemoteVariable(name='CLKOUT5PhaseMux',  description='CLKOUT5Reg1', offset=0x0000006*4, bitSize=3, bitOffset=13, base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT5HighTime',  description='CLKOUT5Reg1', offset=0x0000006*4, bitSize=6, bitOffset=6,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT5LowTime',   description='CLKOUT5Reg1', offset=0x0000006*4, bitSize=6, bitOffset=0,  base=pr.UInt, mode='RW')))
      self.add((
         pr.RemoteVariable(name='CLKOUT5Edge',      description='CLKOUT5Reg2', offset=0x0000007*4, bitSize=1, bitOffset=7,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT5NoCount',   description='CLKOUT5Reg2', offset=0x0000007*4, bitSize=1, bitOffset=6,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT5DelayTime', description='CLKOUT5Reg2', offset=0x0000007*4, bitSize=6, bitOffset=0,  base=pr.UInt, mode='RW')))
      self.add((
         pr.RemoteVariable(name='CLKOUT6PhaseMux',  description='CLKOUT6Reg1', offset=0x0000012*4, bitSize=3, bitOffset=13, base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT6HighTime',  description='CLKOUT6Reg1', offset=0x0000012*4, bitSize=6, bitOffset=6,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT6LowTime',   description='CLKOUT6Reg1', offset=0x0000012*4, bitSize=6, bitOffset=0,  base=pr.UInt, mode='RW')))
      self.add((
         pr.RemoteVariable(name='CLKOUT6Edge',      description='CLKOUT6Reg2', offset=0x0000013*4, bitSize=1, bitOffset=7,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT6NoCount',   description='CLKOUT6Reg2', offset=0x0000013*4, bitSize=1, bitOffset=6,  base=pr.UInt, mode='RW'),
         pr.RemoteVariable(name='CLKOUT6DelayTime', description='CLKOUT6Reg2', offset=0x0000013*4, bitSize=6, bitOffset=0,  base=pr.UInt, mode='RW')))


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
