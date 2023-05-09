#-----------------------------------------------------------------------------
# This file is part of the 'epix-320k-m'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'Development Board Examples', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------


import pyrogue  as pr
import pyrogue.protocols
import pyrogue.utilities.fileio

import rogue
import rogue.hardware.axi
import rogue.interfaces.stream
import rogue.utilities.fileio

import os
import numpy as np
import time
import subprocess

import ePix320kM as fpgaBoard
import epix_hr_leap_common as leapCommon

rogue.Version.minVersion('5.15.3')


class Root(pr.Root):
    def __init__(   self,
            top_level = '',
            dev       = '/dev/datadev_0',
            pollEn    = True,  # Enable automatic polling registers
            initRead  = True,  # Read all registers at start of the system
            promProg  = False, # Flag to disable all devices not related to PROM programming
            **kwargs):

        #################################################################

        self.promProg = promProg
        self.sim      = (dev == 'sim')

        self.top_level = top_level
        
        numOfAsics = 4
        
        if (self.sim):
            # Set the timeout
            kwargs['timeout'] = 5.0 # firmware simulation slow and timeout base on real time (not simulation time)

        else:
            # Set the timeout
            kwargs['timeout'] = 1.0 # 5.0 seconds default

        super().__init__(**kwargs)

        #################################################################

        # Create an empty list to be filled
        self.dataStream    = [None for i in range(numOfAsics)]
        self.adcMonStream  = [None for i in range(4)]
        self.oscopeStream  = [None for i in range(4)]
        self._cmd          = [None]

        # Check if not VCS simulation
        if (not self.sim):

            # # Start up flags
            self._pollEn   = pollEn
            self._initRead = initRead

            # # Map the DMA streams
            for lane in range(numOfAsics):
                self.dataStream[lane] = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * lane + 0, 1)
            
            self.srpStream = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 5 + 0, 1)
            
            self.ssiCmdStream = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 5 + 1, 1)

            #self.xvcStream = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 5 + 2, 1)
            for vc in range(4):
                self.adcMonStream[vc] = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 6 + vc, 1)
                self.oscopeStream[vc] = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 7 + vc, 1)

            # # Create (Xilinx Virtual Cable) XVC on localhost
            #self.xvc = rogue.protocols.xilinx.Xvc(2542)
            #self.addProtocol(self.xvc)

            # # Connect xvcStream to XVC module
            #self.xvcStream == self.xvc

            # # Create SRPv3
            self.srp = rogue.protocols.srp.SrpV3()

            # # Connect SRPv3 to srpStream
            pyrogue.streamConnectBiDir(self.srpStream,self.srp)

        else:

            # Start up flags are FALSE for simulation mode
            self._pollEn   = False
            self._initRead = False

            # Map the simulation DMA streams
            # 2 TCP ports per stream
            self.srp = rogue.interfaces.memory.TcpClient('localhost', 24000)

            for lane in range(numOfAsics):
                # 2 TCP ports per stream
                self.dataStream[lane] = rogue.interfaces.stream.TcpClient('localhost', 24002 + 2 * lane)

            # 2 TCP ports per stream
            self.ssiCmdStream = rogue.interfaces.stream.TcpClient('localhost', 24012)

        self._cmd = rogue.protocols.srp.Cmd()

        # Connect ssiCmd to ssiCmdStream
        pyrogue.streamConnect(self._cmd, self.ssiCmdStream)

        @self.command()
        def Trigger():
            self._cmd.sendCmd(0, 0)
        #################################################################

        # File writer
        self.dataWriter = pr.utilities.fileio.StreamWriter()
        self.add(self.dataWriter)
        self.add(pyrogue.RunControl(name = 'runControl',
                                    description='Run Controller hr',
                                    cmd=self.Trigger,
                                    rates={1: '1 Hz', 2: '2 Hz', 4: '4 Hz', 8: '8 Hz', 10: '10 Hz', 30: '30 Hz', 60: '60 Hz', 120: '120 Hz'}))
        # Connect dataStream to data writer
        for lane in range(numOfAsics):
            self.dataStream[lane] >> self.dataWriter.getChannel(lane)

        # Check if not VCS simulation
        if (not self.sim):
            for vc in range(4):
                self.adcMonStream[vc] >> self.dataWriter.getChannel(vc + 8)
                self.oscopeStream[vc] >> self.dataWriter.getChannel(lane + 12)

        #################################################################

        # Add Devices
        self.add(leapCommon.Core(
            offset   = 0x0000_0000,
            memBase  = self.srp,
            sim      = self.sim,
            promProg = self.promProg,
            expand   = False,
        ))

        self.add(fpgaBoard.App(
            offset   = 0x8000_0000,
            memBase  = self.srp,
            sim      = self.sim,
            enabled  = not self.promProg,
            expand   = False,
        ))

        self.add(pr.LocalCommand(name='InitASIC',
                                 description='[routine, asic0, asic1, asic2, asic3]',
                                 value=[0,0,0,0,0],
                                 function=self.fnInitAsic
        ))

        #################################################################

    def start(self, **kwargs):
        super().start(**kwargs)
        # Check if not simulation and not PROM programming
        if not self.sim and not self.promProg:
            self.CountReset()


    def fnInitAsic(self, dev,cmd,arg):
        """SetTestBitmap command function"""       
        print("Rysync ASIC started")
        arguments = np.asarray(arg)
        if arguments[0] == 1:
            self.filenamePll              = self.root.top_level + "../config/EPixHR10k2MPllConfigClk5En-Registers.csv"
            self.filenamePowerSupply       = self.root.top_level + "../config/ePixHr10k2M_PowerSupply_Enable.yml"
            self.filenameRegisterControl   = self.root.top_level + "../config/ePixHr10k2M_RegisterControl.yml"
            self.filenameASIC              = self.root.top_level + "../config/ePixHr10kT_PLLBypass_320MHz_ASIC_0.yml"
            self.filenamePacketReg         = self.root.top_level + "../config/ePixHr10k2M_PacketRegisters.yml"
            self.filenameTriggerReg        = self.root.top_level + "../config/ePixHr10k2M_TriggerRegisters.yml"
            self.filenameBatcher           = self.root.top_level + "../config/ePixHr10k2M_BatcherEventBuilder.yml"
#/afs/slac/g/controls/development/users/dnajjar/sandBox/ePixHR10k-2M-dev/software/config/ePixHr10kT_PLLBypass_320MHz_ASIC_0.yml
        if arguments[0] != 0:
            self.fnInitAsicScript(dev,cmd,arg)

    def fnInitAsicScript(self, dev,cmd,arg):
        """SetTestBitmap command function"""       
        print("Init ASIC script started")

        # load config that sets prog supply
        print("Loading supply configuration")
        self.root.LoadConfig(self.filenamePowerSupply)
        print(self.filenamePowerSupply)
        print("Loaded supply configuration")

        # load config that sets waveforms
        print("Loading register control (waveforms) configuration")
        self.root.LoadConfig(self.filenameRegisterControl)
        print(self.filenameRegisterControl)
        print("Loaded register control (waveforms) configuration")


        # load config that sets packet registers
        print("Loading packet registers")
        self.root.LoadConfig(self.filenamePacketReg)

        delay = 1

        #Make sure clock is disabled at the ASIC level
        self.App.AsicTop.RegisterControl.ClkSyncEn.set(False)

        self.App.AsicTop.RegisterControl.GlblRstPolarityN.set(False)
        time.sleep(delay) 
        self.App.AsicTop.RegisterControl.GlblRstPolarityN.set(True)
        time.sleep(delay) 

       
        ## load config for the asic
        print("Loading ASIC and timing configuration")
        #disable all asic to let the files define which ones should be set
        
        print("Loading ASIC configurations")
        self.root.LoadConfig(self.filenameASIC)

        self.App.AsicTop.RegisterControl.RoLogicRstN.set(False)
        time.sleep(delay)
        self.App.AsicTop.RegisterControl.RoLogicRstN.set(True)
        time.sleep(delay)
        
        # starting clock inside the ASIC
        self.App.AsicTop.RegisterControl.ClkSyncEn.set(True)


        print("Initialization routine completed.")
        
        '''
        # batcher settings
        self.root.LoadConfig(self.filenameBatcher)

        ## load config for the asic
        print("Loading Trigger settings")
        self.root.LoadConfig(self.filenameTriggerReg)
        print(self.filenameTriggerReg)

        
        '''
