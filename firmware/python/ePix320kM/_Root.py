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

from ePixViewer.software.deviceFiles import ePixHrMv2

rogue.Version.minVersion('5.14.0')

class fullRateDataReceiver(ePixHrMv2.DataReceiverEpixHrMv2):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.dataAcc = np.zeros((192,384,0), dtype='int32')

    def process(self,frame):
        super().process(frame)
        self.dataAcc = np.dstack((self.dataAcc, np.intc(self.Data.get())))

    def cleanData(self):
        self.dataAcc = np.zeros((192,384,0), dtype='int32')

    def getData(self):
        return self.dataAcc      


#############################################
# Descramble class
#############################################
class DataDebug(rogue.interfaces.stream.Slave):

    def __init__(self, name):
        rogue.interfaces.stream.Slave.__init__(self)

        self.channelData = [[] for _ in range(8)]
        self.name = name
        self.enable = False
        self.data = np.zeros((192,384,0), dtype='uint16')

        self.framePixelRow = 192
        self.framePixelColumn = 384
        pixelsPerLanesRows = 48
        pixelsPerLanesColumns = 64
        numOfBanks = 24
        bankHeight = pixelsPerLanesRows
        bankWidth = pixelsPerLanesColumns

        imageSize = self.framePixelColumn * self.framePixelRow

        self.lookupTableCol = np.zeros(imageSize, dtype=int)
        self.lookupTableRow = np.zeros(imageSize, dtype=int)

       # based on descrambling pattern described here figure out the location of the pixel based on its index in raw data
        # https://confluence.slac.stanford.edu/download/attachments/392826236/image-2023-8-9_16-6-42.png?version=1&modificationDate=1691622403000&api=v2
        descarambledImg = np.zeros((numOfBanks, bankHeight,bankWidth), dtype=int)
        for row in range(bankHeight) :
            for col in range (bankWidth) : 
                for bank in range (numOfBanks) :
                    #                                  (even cols w/ offset       +  row offset       + increment every two cols)   * fill one pixel / bank + bank increment
                    descarambledImg[bank, row, col] = (((col+1) % 2) * 1536       +   32 * row        + int(col / 2))               * numOfBanks            + bank
        

        # reorder banks from
        # 18    19    20    21    22    23
        # 12    13    14    15    16    17
        #  6     7     8     9    10    11
        #  0     1     2     3     4     5
        #
        #                To
        #  3     7    11    15    19    23         <= Quadrant[3] 48 x 64 x 6
        #  2     6    10    14    18    22         <= Quadrant[2] 48 x 64 x 6
        #  1     5     9    13    17    21         <= Quadrant[1] 48 x 64 x 6
        #  0     4     8    12    16    20         <= Quadrant[0] 48 x 64 x 6


        quadrant = [bytearray(),bytearray(),bytearray(),bytearray()]
        for i in range(4):
            quadrant[i] = np.concatenate((descarambledImg[0+i],
                                        descarambledImg[4+i],
                                        descarambledImg[8+i],
                                        descarambledImg[12+i],
                                        descarambledImg[16+i],
                                        descarambledImg[20+i]),1)
            
        descarambledImg = np.concatenate((quadrant[0], quadrant[1]),0)
        descarambledImg = np.concatenate((descarambledImg, quadrant[2]),0)
        descarambledImg = np.concatenate((descarambledImg, quadrant[3]),0)  

        # reverse pixxel original index to new row and column to generate lookup tables
        for row in range (self.framePixelRow) :
            for col in range (self.framePixelColumn):  
                index = descarambledImg[row,col]
                self.lookupTableRow[index] = row
                self.lookupTableCol[index] = col

        # reshape column and row lookup table
        self.lookupTableCol = np.reshape(self.lookupTableCol, (self.framePixelRow, self.framePixelColumn))
        self.lookupTableRow = np.reshape(self.lookupTableRow, (self.framePixelRow, self.framePixelColumn))

    def descramble(self, frame):
        rawData = frame.getNumpy(0, frame.getPayload()).view(np.uint16)
        current_frame_temp = np.zeros((192, 384), dtype=int)
        """performs the EpixMv2 image descrambling (simply applying lookup table) """
        if (len(rawData)==73752):
             imgDesc = np.frombuffer(rawData[24:73752],dtype='uint16').reshape(192, 384)
        else:
            print("{}: descramble error".format(self.name))
            print('rawData length {}'.format(len(rawData)))
            imgDesc = np.zeros((192,384), dtype='uint16')

        # apply lookup table
        current_frame_temp[self.lookupTableRow, self.lookupTableCol] = imgDesc
        # returns final image
        #return np.bitwise_and(current_frame_temp, self.PixelBitMask.get())
        return current_frame_temp
        
    def _acceptFrame(self, frame):

        if (self.enable == False) :
            return
        
        channel = frame.getChannel()

        frameSize = frame.getPayload()
        ba = bytearray(frameSize)
        frame.read(ba, 0)
        self.data = np.dstack((self.data, self.descramble(frame)))
        

    def cleanData(self):
        self.data = np.zeros((192,384,0), dtype='uint16')

    def getData(self):
        return self.data      

    def enableDataDebug(self, enable):
        self.enable = enable 

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
        self.rate          = [rogue.interfaces.stream.RateDrop(True,0.1) for i in range(self.numOfAsics)]
        self.unbatchers    = [rogue.protocols.batcher.SplitterV1() for lane in range(self.numOfAsics)]
        self.writerUnbatchers    = [rogue.protocols.batcher.SplitterV1() for lane in range(self.numOfAsics)]
        self.streamUnbatchers    = [rogue.protocols.batcher.SplitterV1() for lane in range(self.numOfAsics)]
        self.streamUnbatchersDbg    = [rogue.protocols.batcher.SplitterV1() for lane in range(self.numOfAsics)]
        self._dbg          = [DataDebug(name='DataDebug[{}]'.format(lane)) for lane in range(self.numOfAsics)]

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
            self.dataStream[asicIndex] >> self.writerUnbatchers[asicIndex] >> self.dataWriter.getChannel(asicIndex)
            self.add(fullRateDataReceiver(
                name = f"fullRateDataReceiver[{asicIndex}]"
                ))
            self.dataStream[asicIndex] >> self.streamUnbatchersDbg[asicIndex] >> self._dbg[asicIndex]
            self.dataStream[asicIndex] >> self.streamUnbatchers[asicIndex] >> self.fullRateDataReceiver[asicIndex]

        # Check if not VCS simulation
        if (not self.sim):
            for vc in range(4):
                self.adcMonStream[vc] >> self.dataWriter.getChannel(vc + 8)
                self.oscopeStream[vc] >> self.dataWriter.getChannel(lane + 12)

        for lane in range(self.numOfAsics):
            self.add(ePixHrMv2.DataReceiverEpixHrMv2(name = f"DataReceiver{lane}"))
            self.dataStream[lane] >> self.rate[lane] >> self.unbatchers[lane] >> getattr(self, f"DataReceiver{lane}")

        @self.command()
        def DisplayViewer0():
            subprocess.Popen(["python", self.top_level+"/../../firmware/python/ePixViewer/software/runLiveDisplay.py", "--dataReceiver", "rogue://0/root.DataReceiver0", "image", "--title", "DataReceiver0", "--sizeY", "192", "--sizeX", "384"], shell=False)

        @self.command()
        def DisplayViewer1():
            subprocess.Popen(["python", self.top_level+"/../../firmware/python/ePixViewer/software/runLiveDisplay.py", "--dataReceiver", "rogue://0/root.DataReceiver1", "image", "--title", "DataReceiver1", "--sizeY", "192", "--sizeX", "384"], shell=False)

        @self.command()
        def DisplayViewer2():
            subprocess.Popen(["python", self.top_level+"/../../firmware/python/ePixViewer/software/runLiveDisplay.py", "--dataReceiver", "rogue://0/root.DataReceiver2", "image", "--title", "DataReceiver2", "--sizeY", "192", "--sizeX", "384"], shell=False)

        @self.command()
        def DisplayViewer3():
            subprocess.Popen(["python", self.top_level+"/../../firmware/python/ePixViewer/software/runLiveDisplay.py", "--dataReceiver", "rogue://0/root.DataReceiver3", "image", "--title", "DataReceiver3", "--sizeY", "192", "--sizeX", "384"], shell=False)

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
        # precaution in case someone stops the acquire function in the middle
        self.App.AsicTop.TriggerRegisters.StopTriggers() 
        
        self.App.AsicTop.TriggerRegisters.AcqCountReset()
        self.App.AsicTop.TriggerRegisters.SetAutoTrigger(rate)
        self.App.AsicTop.TriggerRegisters.numberTrigger.set(frames)
        self.App.AsicTop.TriggerRegisters.StartAutoTrigger()
        
        # Wait for the file write to write the 10 waveforms
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
        if os.path.isfile(f'{filename}'):
            os.remove(f'{filename}')    
        print("Acquisition started: filename: {}, rate: {}, #frames:{}".format(filename, frames, rate))

        # Setup and open the file writer
        writer = self.dataWriter._writer
        self.dataWriter.DataFile.set("test.dat")

        self.dataWriter._open()

        # Wait for the file write to open the file
        while( writer.isOpen() is False):
            time.sleep(0.1)

        # Wait a little bit for the file to open up
        time.sleep(1.0)    

        #sets TriggerRegisters
        self.hwTrigger(frames, rate)

        writerFrameCount = writer.getFrameCount()
        for i in range(20):
            if (writerFrameCount == frames) :
                break
            time.sleep(1)
            writerFrameCount = writer.getFrameCount()
            print("Received {} frames...".format(writerFrameCount) , end='\r')

            
        print("\n waiting for file to close...")
        
        # Close the file writer
        writer.close()
        
        # Wait for the file write to close the file
        while( writer.isOpen() is True):
            time.sleep(0.1)

        # Print the status
        print( f'Total triggers sent: {self.App.AsicTop.TriggerRegisters.AcqCount.get()}')
        print("File closed. Acquisition complete. Frames acquired: {}".format(writer.getFrameCount()))
        
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

        # load batcher
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
        print("Loading packet registers")
        self.root.LoadConfig(self.filenamePacketReg)
        print("Loading {}".format(self.filenamePacketReg))
        time.sleep(delay)         

        # load batcher
        print("Loading packet registers")
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
        ## start deserializer config for the asic
        if self.filenameDESER == "":
            EN_DESERIALIZERS_0 = arg[1]

        else:
            print("Loading deserializer parameters")
            EN_DESERIALIZERS_0 = False
            self.DeserRegisters0.enable.set(True)
            self.root.LoadConfig(self.filenameDESER)                    
            self.root.readBlocks()
            time.sleep(delay)                   
            self.DeserRegisters0.Resync.set(True)
            time.sleep(delay) 
            self.DeserRegisters0.Resync.set(False)
            time.sleep(delay) 
            #
            self.DeserRegisters0.BERTRst.set(True)
            time.sleep(delay) 
            self.DeserRegisters0.BERTRst.set(False)
        

        if EN_DESERIALIZERS_0 : 
            print("Starting deserializer")
            self.serializerSyncAttempsts = 0
            while True:
                #make sure idle
                self.DeserRegisters0.enable.set(True)
                self.DeserRegisters0.IdelayRst.set(0)
                self.DeserRegisters0.IserdeseRst.set(0)
                self.root.readBlocks()
                time.sleep(2*delay) 
                self.DeserRegisters0.InitAdcDelay()
                time.sleep(delay)                   
                self.DeserRegisters0.Resync.set(True)
                time.sleep(delay) 
                self.DeserRegisters0.Resync.set(False)
                time.sleep(5*delay) 
                if (self.DeserRegisters0.Locked0.get() and self.DeserRegisters0.Locked1.get() and self.DeserRegisters0.Locked2.get() and  self.DeserRegisters0.Locked3.get() and self.DeserRegisters0.Locked4.get() and  self.DeserRegisters0.Locked5.get()):
                    break
                #limits the number of attempts to get serializer synch.
                self.serializerSyncAttempsts = self.serializerSyncAttempsts + 1
                if self.serializerSyncAttempsts > 0:
                    break

            self.DeserRegisters0.BERTRst.set(True)
            time.sleep(delay) 
            self.DeserRegisters0.BERTRst.set(False)

            print("Starting deserializer - 2")
            self.serializerSyncAttempsts = 0
            while True:
                #make sure idle
                #self.DeserRegisters0.AdcDelayFineTune()
                #limits the number of attempts to get serializer synch.
                self.serializerSyncAttempsts = self.serializerSyncAttempsts + 1
                if self.serializerSyncAttempsts > 0:
                    break

        print("Initialization routine completed.")