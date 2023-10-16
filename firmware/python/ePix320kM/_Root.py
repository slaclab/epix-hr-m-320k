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

import axipcie            as pcie

import os
import numpy as np
import time
import subprocess

import ePix320kM as fpgaBoard
import epix_hr_leap_common as leapCommon

import surf.protocols.pgp as pgp
import pciePgpCard

from ePixViewer.software.deviceFiles import ePixHrMv2

rogue.Version.minVersion('5.14.0')

class fullRateDataReceiver(ePixHrMv2.DataReceiverEpixHrMv2):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.dataAcc = np.zeros((192,384,1000), dtype='int32')
        self.currentFrameCount = 0

    def process(self,frame):
        if (self.currentFrameCount >= 1000) :
            print("Max acquistion size of fullRateDataReceiver of 1000 reached. Cleanup dataDebug. Discarding new data.")
        else :
            super().process(frame)
            self.dataAcc[:,:,self.currentFrameCount] = np.intc(self.Data.get())
            self.currentFrameCount = self.currentFrameCount + 1

    def cleanData(self):
        self.dataAcc = np.zeros((192,384,1000), dtype='int32')
        self.currentFrameCount = 0

    def getData(self):
        return self.dataAcc[:,:,0:self.currentFrameCount]     


class Root(pr.Root):
    def __init__(   self,
            top_level = '',
            dev       = '/dev/datadev_0',
            pollEn    = True,  # Enable automatic polling registers
            initRead  = True,  # Read all registers at start of the system
            promProg  = False, # Flag to disable all devices not related to PROM programming
            pciePgpEn = False, # Enable PCIE PGP card register space access
            **kwargs):

        #################################################################

        self.promProg = promProg
        self.sim      = (dev == 'sim')
        self.top_level = top_level
        
        self.numOfAsics = 4
        
        if (self.sim):
            # Set the timeout
            kwargs['timeout'] = 10.0 # firmware simulation slow and timeout base on real time (not simulation time)

        else:
            # Set the timeout
            kwargs['timeout'] = 10.0 # 5.0 seconds default

        super().__init__(**kwargs)

        #################################################################

        # Create an empty list to be filled
        self.dataStream    = [None for i in range(self.numOfAsics)]
        self.adcMonStream  = [None for i in range(4)]
        self.oscopeStream  = [None for i in range(4)]
        self._cmd          = [None]
        self.rate          = [rogue.interfaces.stream.RateDrop(True,1) for i in range(self.numOfAsics)]
        self.unbatchers    = [rogue.protocols.batcher.SplitterV1() for lane in range(self.numOfAsics)]
        self.streamUnbatchers    = [rogue.protocols.batcher.SplitterV1() for lane in range(self.numOfAsics)]
        self._dbg          = [fpgaBoard.DataDebug(name='DataDebug[{}]'.format(lane)) for lane in range(self.numOfAsics)]

        # Check if not VCS simulation
        if (not self.sim):

            # # Start up flags
            self._pollEn   = pollEn
            self._initRead = initRead

            # # Map the DMA streams
            for lane in range(self.numOfAsics):
                self.dataStream[lane] = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * lane + 0, 1)
            
            self.srpStream = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 5 + 0, 1)
            
            self.ssiCmdStream = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 5 + 1, 1)

            self.xvcStream = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 5 + 2, 1)
            for vc in range(4):
                self.adcMonStream[vc] = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 6 + vc, 1)
                self.oscopeStream[vc] = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 7 + vc, 1)

            # # Create (Xilinx Virtual Cable) XVC on localhost
            self.xvc = rogue.protocols.xilinx.Xvc(2542)
            self.addProtocol(self.xvc)

            # # Connect xvcStream to XVC module
            self.xvcStream == self.xvc

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

            for lane in range(self.numOfAsics):
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
        for asicIndex in range(self.numOfAsics):
            self.dataStream[asicIndex] >> self.dataWriter.getChannel(asicIndex)
            self.add(fullRateDataReceiver(
                name = f"fullRateDataReceiver[{asicIndex}]"
                ))
            self.dataStream[asicIndex] >> self.streamUnbatchers[asicIndex]
            self.streamUnbatchers[asicIndex] >> self._dbg[asicIndex]
            self.streamUnbatchers[asicIndex] >> self.fullRateDataReceiver[asicIndex]

        # Check if not VCS simulation
        if (not self.sim):
            for vc in range(4):
                self.adcMonStream[vc] >> self.dataWriter.getChannel(vc + 8)
                self.oscopeStream[vc] >> self.dataWriter.getChannel(lane + 12)

        # Read file stream. 
        self.readerReceiver = [fpgaBoard.DataDebug(name = "readerReceiver[{}]".format(lane), size = 10000) for lane in range(self.numOfAsics)]
        self.filter =  [rogue.interfaces.stream.Filter(False, lane) for lane in range(self.numOfAsics)]
        self.fread = rogue.utilities.fileio.StreamReader()
        self.readUnbatcher = [rogue.protocols.batcher.SplitterV1() for lane in range(self.numOfAsics)]
        for i in range(self.numOfAsics):
            self.readerReceiver[i] << self.readUnbatcher[i] << self.filter[i] << self.fread
            self.readerReceiver[i].enableDataDebug(True)
            #self.readerReceiver[i].enableDebugPrint(True)


        for lane in range(self.numOfAsics):
            self.add(ePixHrMv2.DataReceiverEpixHrMv2(name = f"DataReceiver{lane}"))
            self.dataStream[lane] >> self.rate[lane] >> self.unbatchers[lane] >> getattr(self, f"DataReceiver{lane}")

        @self.command()
        def DisplayViewer0():
            subprocess.Popen(["python", self.top_level+"/../../firmware/python/ePixViewer/software/runLiveDisplay.py", "--dataReceiver", "rogue://0/root.DataReceiver0", "image", "--title", "DataReceiver0", "--sizeY", "192", "--sizeX", "384", "--serverList","localhost:{}".format(kwargs["serverPort"]) ], shell=False)

        @self.command()
        def DisplayViewer1():
            subprocess.Popen(["python", self.top_level+"/../../firmware/python/ePixViewer/software/runLiveDisplay.py", "--dataReceiver", "rogue://0/root.DataReceiver1", "image", "--title", "DataReceiver1", "--sizeY", "192", "--sizeX", "384", "--serverList","localhost:{}".format(kwargs["serverPort"])], shell=False)

        @self.command()
        def DisplayViewer2():
            subprocess.Popen(["python", self.top_level+"/../../firmware/python/ePixViewer/software/runLiveDisplay.py", "--dataReceiver", "rogue://0/root.DataReceiver2", "image", "--title", "DataReceiver2", "--sizeY", "192", "--sizeX", "384", "--serverList","localhost:{}".format(kwargs["serverPort"])], shell=False)

        @self.command()
        def DisplayViewer3():
            subprocess.Popen(["python", self.top_level+"/../../firmware/python/ePixViewer/software/runLiveDisplay.py", "--dataReceiver", "rogue://0/root.DataReceiver3", "image", "--title", "DataReceiver3", "--sizeY", "192", "--sizeX", "384", "--serverList","localhost:{}".format(kwargs["serverPort"])], shell=False)

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

        if (not self.sim and pciePgpEn):
            self.add(pciePgpCard.pciePgp(        
                                    dev      = dev,
                                    expand   = False,
                                    numDmaLanes = 8,
            ))



    def start(self, **kwargs):
        super().start(**kwargs)
        # Check if not simulation and not PROM programming
        if not self.sim and not self.promProg:
            self.CountReset()
        for asicIndex in range(self.numOfAsics):    
            getattr(self, f"fullRateDataReceiver[{asicIndex}]").RxEnable.set(False)
        for asicIndex in range(self.numOfAsics):    
            getattr(self, f"DataReceiver{asicIndex}").RxEnable.set(False)

    def enableAllAsics(self, enable) :
        for batcherIndex in range(self.numOfAsics) :
            self.enableAsic(batcherIndex, enable)

    def enableAsic(self, batcherIndex, enable) :
        getattr(self.App.AsicTop, f"BatcherEventBuilder{batcherIndex}").Blowoff.set(not enable)

    def disableAndCleanAllFullRateDataRcv(self) :
        for asicIndex in range(self.numOfAsics) :
            self.fullRateDataReceiver[asicIndex].cleanData()
            self.fullRateDataReceiver[asicIndex].RxEnable.set(False)

    def enableFullRateDataRcv(self, index, enable) :
        self.fullRateDataReceiver[index].RxEnable.set(enable)

    def enableDataRcv(self, enable) :
        for asicIndex in range(self.numOfAsics) :
            getattr(self, f"DataReceiver{asicIndex}").RxEnable.set(enable)

    def enableDataDebug(self, enable) :
        for asicIndex in range(self.numOfAsics) :
            self._dbg[asicIndex].enableDataDebug(enable)

    def hwTrigger(self, frames, rate) :
        with self.root.updateGroup(.25):
            # precaution in case someone stops the acquire function in the middle
            self.App.AsicTop.TriggerRegisters.StopTriggers() 
            
            self.App.AsicTop.TriggerRegisters.AcqCountReset()
            self.App.AsicTop.TriggerRegisters.SetAutoTrigger(rate)
            self.App.AsicTop.TriggerRegisters.numberTrigger.set(frames)
            self.App.AsicTop.TriggerRegisters.StartAutoTrigger()
            
            # Wait for the file write to write the 10 waveforms
            #time.sleep(frames/rate)
            while (self.App.AsicTop.TriggerRegisters.AcqCount.get() != frames) :
                print("Triggers sent: {}".format(self.App.AsicTop.TriggerRegisters.AcqCount.get()) , end='\r')
                time.sleep(0.1)
            print("Triggers sent: {}".format(self.App.AsicTop.TriggerRegisters.AcqCount.get()))
            
            # stops triggers
            self.App.AsicTop.TriggerRegisters.StopTriggers()  
        
    def enableFullRateDataRcv(self, index, enable) :
        self.fullRateDataReceiver[index].RxEnable.set(enable)

    def getLaneLocks(self) :
        for asicIndex in range(self.numOfAsics) : 
            self.App.SspMonGrp[asicIndex].enable.set(True)
            print("ASIC{}: {:#x}".format(asicIndex, self.App.SspMonGrp[asicIndex].Locked.get()))

    #check current frames in receivers
    def printDataReceiverStatus(self) :
        for asicIndex in range(self.numOfAsics):
            print("Checkpoint: DataReceiver {} has {} frames".format(asicIndex, getattr(self, f"DataReceiver{asicIndex}").FrameCount.get()))        

    def acquireToFile(self, filename, frames, rate) :
        with self.root.updateGroup(.25):
            dev = var = 0
            if os.path.isfile(f'{filename}'):
                print("File already exists. Please change file name and try again.")
                return  
            print("Acquisition started: filename: {}, rate: {}, #frames:{}".format(filename, rate, frames))

            # Setup and open the file writer
            self.dataWriter.DataFile.set(filename)

            self.dataWriter.Open()

            # Wait for the file write to open the file
            while( self.dataWriter.IsOpen.get() is False):
                time.sleep(0.1)

            #sets TriggerRegisters
            self.hwTrigger(frames, rate)
            writerFrameCount = self.dataWriter._waitFrameCount(frames, 5)
            for index in range (4) : 
                print("Received on channel {} {} frames...".format(index, self.dataWriter.getChannel(index).getFrameCount()))
            print("Waiting for file to close...")
            
            # Close the file writer
            self.dataWriter.Close()
        
        # Wait for the file write to close the file
        while( self.dataWriter.IsOpen.get() is True):
            time.sleep(0.1)

        # Print the status
        print("Acquisition complete and file closed")

    def readFromFile(self, filename) :

        for i in range(self.numOfAsics):
            self.readerReceiver[i].cleanData()

        self.fread.open(filename)
        self.fread.closeWait()

        
    def fnInitAsic(self, dev,cmd,arg):
        """SetTestBitmap command function"""       
        print("Rysync ASIC started")
        arguments = np.asarray(arg)
        if arguments[0] == 1:
            self.filenamePLL         = self.root.top_level + "../config/EPixHRM320KPllConfig250Mhz.csv"
            self.filenamePowerSupply = self.root.top_level + "../config/ePixHRM320k_PowerSupply_Enable.yml"
            self.filenameWaveForms   = self.root.top_level + "../config/ePixHRM320k_RegisterControl.yml"
            self.filenameASIC        = self.root.top_level + "../config/ePixHRM320k_ASIC_u{}_PLLBypass.yml"
            self.filenameDESER       = self.root.top_level + "../config/ePixHRM320k_SspMonGrp_carrier3.yml"
            self.filenamePacketReg   = self.root.top_level + "../config/ePixHRM320k_PacketRegisters.yml"
            self.filenameBatcher     = self.root.top_level + "../config/ePixHRM320k_BatcherEventBuilder.yml"
        if arguments[0] == 2:
            self.filenamePLL         = self.root.top_level + "../config/EPixHRM320KPllConfig125Mhz.csv"
            self.filenamePowerSupply = self.root.top_level + "../config/ePixHRM320k_PowerSupply_Enable.yml"
            self.filenameWaveForms   = self.root.top_level + "../config/ePixHRM320k_RegisterControl.yml"
            self.filenameASIC        = self.root.top_level + "../config/ePixHRM320k_ASIC_u{}_PLLBypass.yml"
            self.filenameDESER       = self.root.top_level + "../config/ePixHRM320k_SspMonGrp_carrier3.yml"
            self.filenamePacketReg   = self.root.top_level + "../config/ePixHRM320k_PacketRegisters.yml"
            self.filenameBatcher     = self.root.top_level + "../config/ePixHRM320k_BatcherEventBuilder.yml"     
        if arguments[0] == 3:
            self.filenamePLL         = self.root.top_level + "../config/EPixHRM320KPllConfig168Mhz.csv"
            self.filenamePowerSupply = self.root.top_level + "../config/ePixHRM320k_PowerSupply_Enable.yml"
            self.filenameWaveForms   = self.root.top_level + "../config/ePixHRM320k_RegisterControl.yml"
            self.filenameASIC        = self.root.top_level + "../config/ePixHRM320k_ASIC_u{}_PLLBypass.yml"
            self.filenameDESER       = self.root.top_level + "../config/ePixHRM320k_SspMonGrp_carrier3.yml"
            self.filenamePacketReg   = self.root.top_level + "../config/ePixHRM320k_PacketRegisters.yml"
            self.filenameBatcher     = self.root.top_level + "../config/ePixHRM320k_BatcherEventBuilder.yml"                     
        if arguments[0] != 0:
            self.fnInitAsicScript(dev,cmd,arg)

    def fnInitAsicScript(self, dev,cmd,arg):
        """SetTestBitmap command function"""  
        arguments = np.asarray(arg)

        print("Init ASIC script started")
        delay = 1


        # configure PLL
        print("Loading PLL configuration")
        self.App.enable.set(False)
        if not self.sim :
            self.Core.Si5345Pll.enable.set(True)
            self.Core.Si5345Pll.LoadCsvFile(self.filenamePLL)
            print("Loaded. Waiting for lock...")
            time.sleep(6) 
            self.App.enable.set(True)
            self.Core.Si5345Pll.enable.set(False)

        # load config that sets prog supply
        print("Loading supply configuration")
        self.root.LoadConfig(self.filenamePowerSupply)
        print("Loading {}".format(self.filenamePowerSupply))
        time.sleep(delay) 

        if (not self.sim):
            # load deserializer
            print("Loading lane delay configurations")
            self.root.LoadConfig(self.filenameDESER)
            print("Loading {}".format(self.filenameDESER))
            time.sleep(delay)  
        

        # load config that sets waveforms
        print("Loading waveforms configuration")
        self.root.LoadConfig(self.filenameWaveForms)
        print("Loading {}".format(self.filenameWaveForms))
        time.sleep(delay) 

        # load config that sets packet registers
        print("Loading packet register configurations")
        self.root.LoadConfig(self.filenamePacketReg)
        print("Loading {}".format(self.filenamePacketReg))
        time.sleep(delay)         

        # load batcher
        print("Loading batcher configurations")
        self.root.LoadConfig(self.filenameBatcher)
        print("Loading {}".format(self.filenameBatcher))
        time.sleep(delay)  

        ## takes the asics off of reset
        print("Taking asic off of reset")
        self.App.AsicTop.RegisterControlDualClock.enable.set(True)
        self.App.AsicTop.RegisterControlDualClock.ClkSyncEn.set(False)
        self.App.AsicTop.RegisterControlDualClock.GlblRstPolarityN.set(False)
        time.sleep(delay) 
        self.App.AsicTop.RegisterControlDualClock.GlblRstPolarityN.set(True)
        time.sleep(delay) 
        self.App.AsicTop.RegisterControlDualClock.ClkSyncEn.set(True)
        self.root.readBlocks()
        time.sleep(delay) 

        ## load config for the asic
        if not self.sim :
            print("Loading ASICs and timing configuration")
            for asicIndex in range(1 ,5, 1):
                if arguments[asicIndex] != 0:
                    self.root.LoadConfig(self.filenameASIC.format(asicIndex))
                    print("Loading {}".format(self.filenameASIC.format(asicIndex)))
                    time.sleep(5*delay) 

        print("Initialization routine completed.")

        return
