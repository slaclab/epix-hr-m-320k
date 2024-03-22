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
import pyrogue.interfaces

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

try :
    from ePixViewer.asics import ePixHrMv2
    from ePixViewer import EnvDataReceiver
    from ePixViewer import ScopeDataReceiver
    from fullRateDataReceiver import fullRateDataReceiver
    from dataDebug import dataDebug
except ImportError:
    pass

rogue.Version.minVersion('6.1.3')

#rogue.Logging.setFilter('pyrogue.packetizer', rogue.Logging.Debug)


class Root(pr.Root):
    def __init__(   self,
            top_level = '',
            dev       = '/dev/datadev_0',
            pollEn    = True,  # Enable automatic polling registers
            initRead  = True,  # Read all registers at start of the system
            promProg  = False, # Flag to disable all devices not related to PROM programming
            pciePgpEn = False, # Enable PCIE PGP card register space access
            justCtrl  = False, # Enable if you only require Root for accessing AXI registers (no data)
            fullRateDataReceiverEn = True, #Enable Full rate data receivers for jupyter 
            DDebugSize=1000,
            **kwargs):

        #################################################################

        self.promProg = promProg
        self.sim      = (dev == 'sim')
        self.top_level = top_level
        self.justCtrl = justCtrl
        self.fullRateDataReceiverEn = fullRateDataReceiverEn
        self.numOfAsics = 4


        if (self.sim):
            # Set the timeout
            kwargs['timeout'] = 10.0 # firmware simulation slow and timeout base on real time (not simulation time)

        else:
            # Set the timeout
            kwargs['timeout'] = 10.0 # 5.0 seconds default

        super().__init__(**kwargs)


        self.zmqServer = pyrogue.interfaces.ZmqServer(root=self, addr='127.0.0.1', port=0)
        self.addInterface(self.zmqServer)
 

        #################################################################

        # Create an empty list to be filled
        self._cmd          = [None]

        if (self.justCtrl == False) :
            self.dataStream    = [None for i in range(self.numOfAsics)]
            self.oscopeStream  = [None for i in range(4)]
            self.rate          = [rogue.interfaces.stream.RateDrop(True,1) for i in range(self.numOfAsics)]
            self.unbatchers    = [rogue.protocols.batcher.SplitterV1() for lane in range(self.numOfAsics)]
            self.streamUnbatchers    = [rogue.protocols.batcher.SplitterV1() for lane in range(self.numOfAsics)]
            self._dbg          = [dataDebug(name='DataDebug[{}]'.format(lane), size = DDebugSize) for lane in range(self.numOfAsics)]
            
            # Create configuration stream
            stream = pyrogue.interfaces.stream.Variable(root=self)

            # Create StreamWriter with the configuration stream included as channel 1
            self.dataWriter = pyrogue.utilities.fileio.StreamWriter(configStream={5: stream})
            self.add(self.dataWriter)               

        # Check if not VCS simulation
        if (not self.sim):

            # # Start up flags
            self._pollEn   = pollEn
            self._initRead = initRead

            # # Map the DMA streams
            if (self.justCtrl == False) :
                for lane in range(self.numOfAsics):
                    self.dataStream[lane] = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * lane + 0, 1)
            
            self.srpStream = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 5 + 0, 1)
            
            self.ssiCmdStream = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 5 + 1, 1)

            self.xvcStream = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 5 + 2, 1)

            if (self.justCtrl == False) :
                self.adcMonStream = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 6, 1)
                for vc in range(4):                
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

            if (self.justCtrl == False) :
                for lane in range(self.numOfAsics):
                    # 2 TCP ports per stream
                    self.dataStream[lane] = rogue.interfaces.stream.TcpClient('localhost', 24002 + 2 * lane)

                self.adcMonStream = rogue.interfaces.stream.TcpClient('localhost', 24016)
                for vc in range(4):
                    self.oscopeStream[vc] = rogue.interfaces.stream.TcpClient('localhost', 24026 + 2 * vc)


            # 2 TCP ports per stream
            self.ssiCmdStream = rogue.interfaces.stream.TcpClient('localhost', 24012)

        self._cmd = rogue.protocols.srp.Cmd()

        # Connect ssiCmd to ssiCmdStream
        pyrogue.streamConnect(self._cmd, self.ssiCmdStream)

        @self.command()
        def Trigger():
            self._cmd.sendCmd(0, 0)
        #################################################################

        self.add(pyrogue.RunControl(name = 'runControl',
                                    description='Run Controller hr',
                                    cmd=self.Trigger,
                                    rates={1: '1 Hz', 2: '2 Hz', 4: '4 Hz', 8: '8 Hz', 10: '10 Hz', 30: '30 Hz', 60: '60 Hz', 120: '120 Hz'}))
        # Connect dataStream to data writer

        if (self.justCtrl == False) :
            for asicIndex in range(self.numOfAsics):
                self.dataStream[asicIndex] >> self.dataWriter.getChannel(asicIndex)
                self.dataStream[asicIndex] >> self.streamUnbatchers[asicIndex]
                self.streamUnbatchers[asicIndex] >> self._dbg[asicIndex]

                if(self.fullRateDataReceiverEn == True):
                    self.add(fullRateDataReceiver(
                        name = f"fullRateDataReceiver[{asicIndex}]",
                        hidden = True
                        ))
                    self.streamUnbatchers[asicIndex] >> self.fullRateDataReceiver[asicIndex]


            # Check if not VCS simulation
            envConf = [
                [
                    {   'id': 0, 'name': 'Therm 0 (deg. C)',      'conv': lambda data: -68.305*data+93.308, 'color': '#FFFFFF'  },
                    {   'id': 1, 'name': 'Therm 1 (deg. C)',      'conv': lambda data: -68.305*data+93.308, 'color': '#FF00FF' },
                    {   'id': 2, 'name': 'Analog VIN (volts)',    'conv': lambda data: data, 'color': '#00FFFF'  },
                    {   'id': 3, 'name': 'ASIC C0 AVDD (Amps)',   'conv': lambda data: data, 'color': '#FFFF00'  },
                    {   'id': 4, 'name': 'ASIC C0 DVDD (Amps)',   'conv': lambda data: data, 'color': '#F0F0F0'  },
                    {   'id': 5, 'name': 'ASIC C1 AVDD (Amps)',   'conv': lambda data: data, 'color': '#F0500F'  },
                    {   'id': 6, 'name': 'ASIC C1 DVDD (Amps)',   'conv': lambda data: data, 'color': '#503010'  },
                    {   'id': 7, 'name': 'ASIC C2 AVDD (Amps)',   'conv': lambda data: data, 'color': '#777777'  }
                ],
                [
                    {   'id': 0, 'name': 'Therm 2 (deg. C)',      'conv': lambda data: -68.305*data+93.308, 'color': '#FFFFFF'  },
                    {   'id': 1, 'name': 'Therm 3 (deg. C)',      'conv': lambda data: -68.305*data+93.308, 'color': '#FF00FF' },
                    {   'id': 2, 'name': 'ASIC C2 DVDD (Amps)',   'conv': lambda data: data, 'color': '#00FFFF'  },
                    {   'id': 3, 'name': 'ASIC C3 DVDD (Amps)',   'conv': lambda data: data, 'color': '#FFFF00'  },
                    {   'id': 4, 'name': 'ASIC C3 AVDD (Amps)',   'conv': lambda data: data, 'color': '#F0F0F0'  },
                    {   'id': 5, 'name': 'ASIC C4 DVDD (Amps)',   'conv': lambda data: data, 'color': '#F0500F'  },
                    {   'id': 6, 'name': 'ASIC C4 AVDD (Amps)',   'conv': lambda data: data, 'color': '#503010'  },
                    {   'id': 7, 'name': 'Humidity (%)',          'conv': lambda data: 45.8*data-21.3, 'color': '#777777'  }
                ],
                [
                    {   'id': 0, 'name': 'Therm 4 (deg. C)',      'conv': lambda data: -68.305*data+93.308, 'color': '#FFFFFF'  },
                    {   'id': 1, 'name': 'Therm 5 (deg. C)',      'conv': lambda data: -68.305*data+93.308, 'color': '#FF00FF' },
                    {   'id': 2, 'name': 'ASIC C0 V2 5A (volts)', 'conv': lambda data: data, 'color': '#00FFFF'  },
                    {   'id': 3, 'name': 'ASIC C1 V2 5A (volts)', 'conv': lambda data: data, 'color': '#FFFF00'  },
                    {   'id': 4, 'name': 'ASIC C2 V2 5A (volts)', 'conv': lambda data: data, 'color': '#F0F0F0'  },
                    {   'id': 5, 'name': 'ASIC C3 V2 5A (volts)', 'conv': lambda data: data, 'color': '#F0500F'  },
                    {   'id': 6, 'name': 'ASIC C4 V2 5A (volts)', 'conv': lambda data: data, 'color': '#503010'  },
                    {   'id': 7, 'name': 'Digital VIN (volts)',   'conv': lambda data: data, 'color': '#777777'  }
                ],
                [
                    {   'id': 0, 'name': 'Therm dig. 0 (deg. C)', 'conv': lambda data: -68.305*(data)+93.308, 'color': '#FFFFFF'  },
                    {   'id': 1, 'name': 'Therm dig. 1 (deg. C)', 'conv': lambda data: -68.305*(data)+93.308, 'color': '#FF00FF' },
                    {   'id': 2, 'name': 'Humidity dig. (%)',     'conv': lambda data: data*45.8-21.3, 'color': '#00FFFF'  },
                    {   'id': 3, 'name': '1V8 (volts)',           'conv': lambda data: data, 'color': '#FFFF00'  },
                    {   'id': 4, 'name': '2V5 (volts)',           'conv': lambda data: data, 'color': '#F0F0F0'  },
                    {   'id': 5, 'name': 'Vout 6V 10A (Amps)',    'conv': lambda data: 10*data, 'color': '#F0500F'  },
                    {   'id': 6, 'name': 'Mon VCC (volts)',       'conv': lambda data: data, 'color': '#503010'  },
                    {   'id': 7, 'name': 'Raw voltage (volts)',   'conv': lambda data: 3* data, 'color': '#777777'  }
                ],
                [
                    {   'id': 0, 'name': 'Humidity', 'conv': lambda data: data*45.8-21.3, 'color': '#FFFFFF', 'units' : '%'  },
                    {   'id': 1, 'name': 'Thermal', 'conv': lambda data: (1/((np.log((data/0.0001992)/10000)/3750)+(1/298.15)))-273.15, 'color': '#FF00FF', 'units' : 'deg. C'},
                    {   'id': 2, 'name': '3V3',     'conv': lambda data: data*2, 'color': '#00FFFF', 'units' : 'volts'  },
                    {   'id': 3, 'name': '1V8',     'conv': lambda data: data, 'color': '#FFFF00', 'units' : 'volts'  },
                    {   'id': 4, 'name': 'An 2V',   'conv': lambda data: data, 'color': '#F0F0F0', 'units' : 'volts'  },
                    {   'id': 5, 'name': 'Dig 2V',  'conv': lambda data: data, 'color': '#F0500F', 'units' : 'volts'  },
                    {   'id': 6, 'name': 'Dig 6V',  'conv': lambda data: data*24, 'color': '#503010', 'units' : 'volts'  },
                    {   'id': 7, 'name': 'An 6V',   'conv': lambda data: data*100, 'color': '#777777', 'units' : 'volts'  }
                ]
            ]


            self.packetizer = rogue.protocols.packetizer.CoreV2(False, False, True); # No inbound and outbound crc, enSsi=True
            
            # Connect VC stream to depacketizer
            self.adcMonStream >> self.packetizer.transport()

            for vc in range(5):
                self.packetizer.application(vc) >> self.dataWriter.getChannel(vc+8)
                self.add(
                    EnvDataReceiver(
                        config = envConf[vc], 
                        clockT = 6.4e-9, 
                        rawToData = lambda raw: (2.5 * float(raw & 0xffffff)) / 16777216, 
                        name = f"EnvData[{vc}]",
                        payloadElementSize = 8
                    )
                )
                self.packetizer.application(vc) >> self.EnvData[vc]

            # Check if not VCS simulation
            if (not self.sim):
                for vc in range(4):
                    self.oscopeStream[vc] >> self.dataWriter.getChannel(vc+13)
                    self.add(ScopeDataReceiver(name = f"ScopeData{vc}"))
                    self.oscopeStream[vc] >> getattr(self, f"ScopeData{vc}")
                    

            # Read file stream. 
            self.readerReceiver = [dataDebug(name = "readerReceiver[{}]".format(lane), size = 10000) for lane in range(self.numOfAsics)]
            self.filter =  [rogue.interfaces.stream.Filter(False, lane) for lane in range(self.numOfAsics)]
            self.dataReceiverFilter =  [rogue.interfaces.stream.Filter(False, 2) for lane in range(self.numOfAsics)]
            self.fread = rogue.utilities.fileio.StreamReader()
            self.readUnbatcher = [rogue.protocols.batcher.SplitterV1() for lane in range(self.numOfAsics)]


            for i in range(self.numOfAsics):
                self.readerReceiver[i] << self.readUnbatcher[i] << self.filter[i] << self.fread
                self.readerReceiver[i].enableDataDebug(True)
                self.readerReceiver[i].enableDebugPrint(True)


            for lane in range(self.numOfAsics):
                self.add(ePixHrMv2.DataReceiverEpixHrMv2(name = f"DataReceiver{lane}"))
                self.dataStream[lane] >> self.rate[lane] >> self.unbatchers[lane] >>  self.dataReceiverFilter[lane] >> getattr(self, f"DataReceiver{lane}")

        @self.command()
        def DisplayViewer0():
            subprocess.Popen(["python", self.top_level+"/../firmware/submodules/ePixViewer/python/ePixViewer/runLiveDisplay.py", "--dataReceiver", "rogue://0/root.DataReceiver0", "image", "--title", "DataReceiver0", "--sizeY", "192", "--sizeX", "384", "--serverList","localhost:{}".format(self.zmqServer.port()) ], shell=False)

        @self.command()
        def DisplayViewer1():
            subprocess.Popen(["python", self.top_level+"/../firmware/submodules/ePixViewer/python/ePixViewer/runLiveDisplay.py", "--dataReceiver", "rogue://0/root.DataReceiver1", "image", "--title", "DataReceiver1", "--sizeY", "192", "--sizeX", "384", "--serverList","localhost:{}".format(self.zmqServer.port())], shell=False)

        @self.command()
        def DisplayViewer2():
            subprocess.Popen(["python", self.top_level+"/../firmware/submodules/ePixViewer/python/ePixViewer/runLiveDisplay.py", "--dataReceiver", "rogue://0/root.DataReceiver2", "image", "--title", "DataReceiver2", "--sizeY", "192", "--sizeX", "384", "--serverList","localhost:{}".format(self.zmqServer.port())], shell=False)

        @self.command()
        def DisplayViewer3():
            subprocess.Popen(["python", self.top_level+"/../firmware/submodules/ePixViewer/python/ePixViewer/runLiveDisplay.py", "--dataReceiver", "rogue://0/root.DataReceiver3", "image", "--title", "DataReceiver3", "--sizeY", "192", "--sizeX", "384", "--serverList","localhost:{}".format(self.zmqServer.port())], shell=False)

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
                                 value=[4,1,1,1,1],
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

        if (self.justCtrl == False) :
            if(self.fullRateDataReceiverEn == True):
                for asicIndex in range(self.numOfAsics):    
                    getattr(self, f"fullRateDataReceiver[{asicIndex}]").RxEnable.set(False)
            for asicIndex in range(self.numOfAsics):    
                getattr(self, f"DataReceiver{asicIndex}").RxEnable.set(False)

            for vc in range(5): 
                self.EnvData[vc].RxEnable.set(False)
            if (not self.sim) : 
                for vc in range(4):             
                    getattr(self, f"ScopeData{vc}").RxEnable.set(False)


    def enableAllAsics(self, enable) :
        for batcherIndex in range(self.numOfAsics) :
            self.enableAsic(batcherIndex, enable)

    def enableAsic(self, batcherIndex, enable) :
        getattr(self.App.AsicTop, f"BatcherEventBuilder{batcherIndex}").Blowoff.set(not enable)

    def disableAndCleanAllFullRateDataRcv(self) :
        if (self.justCtrl == False) :
            if(self.fullRateDataReceiverEn == True):
                for asicIndex in range(self.numOfAsics) :
                    self.fullRateDataReceiver[asicIndex].cleanData()
                    self.fullRateDataReceiver[asicIndex].RxEnable.set(False)

    def enableFullRateDataRcv(self, index, enable) :
        if (self.justCtrl == False) :
            if(self.fullRateDataReceiverEn == True):
                self.fullRateDataReceiver[index].RxEnable.set(enable)

    def enableDataRcv(self, enable) :
        if (self.justCtrl == False) :
            for asicIndex in range(self.numOfAsics) :
                getattr(self, f"DataReceiver{asicIndex}").RxEnable.set(enable)

    def enableDataDebug(self, enable) :
        if (self.justCtrl == False) :
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
       if (self.justCtrl == False) :
            if(self.fullRateDataReceiverEn == True):
                self.fullRateDataReceiver[index].RxEnable.set(enable)

    def getLaneLocks(self) :
        for asicIndex in range(self.numOfAsics) : 
            self.App.SspMonGrp[asicIndex].enable.set(True)
            print("ASIC{}: {:#x}".format(asicIndex, self.App.SspMonGrp[asicIndex].Locked.get()))

    #check current frames in receivers
    def printDataReceiverStatus(self) :
        if (self.justCtrl == False) :
            for asicIndex in range(self.numOfAsics):
                print("Checkpoint: DataReceiver {} has {} frames".format(asicIndex, getattr(self, f"DataReceiver{asicIndex}").FrameCount.get()))        

    def acquireToFile(self, filename, frames, rate) :
        with self.root.updateGroup(.25):
            if (self.justCtrl == False) :
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

        if (self.justCtrl == False) :
            for i in range(self.numOfAsics):
                self.readerReceiver[i].cleanData()

            self.fread.open(filename)
            self.fread.closeWait()

        
    def fnInitAsic(self, dev,cmd,arg):
        """SetTestBitmap command function"""     

        #get serial numbers
        self.App.AsicTop.RegisterControlDualClock.enable.set(True)
        self.App.AsicTop.RegisterControlDualClock.IDreset.set(0x7)
        self.App.AsicTop.RegisterControlDualClock.IDreset.set(0x0)

        # wait for hardware to get serial numbers
        time.sleep(0.1)        

        # Get serial number for digital board and formulate file names
        DigIDLow = self.App.AsicTop.RegisterControlDualClock.DigIDLow.get()
        DigIDHigh = self.App.AsicTop.RegisterControlDualClock.DigIDHigh.get()

        # Use digital board serial number until carrier serial number gets fixed
        prefix = f'{DigIDHigh:x}{DigIDLow:x}'

        print("Rysync ASIC started")
        arguments = np.asarray(arg)

        self.filenameDESER       = self.root.top_level + "/config/ePixHRM320k_"+prefix+"_SspMonGrp_carrier3.yml"
        if (not os.path.isfile(self.filenameDESER)):
            #did not find file. Using default file
            self.filenameDESER       = self.root.top_level + "/config/ePixHRM320k_SspMonGrp_carrier3.yml"
            print("Did not find SspMonGrp_carrier file. Using generic.")

        self.filenamePacketReg   = self.root.top_level + "/config/ePixHRM320k_"+prefix+"_PacketRegisters.yml"
        if (not os.path.isfile(self.filenamePacketReg)):
            #did not find file. Using default file
            self.filenamePacketReg   = self.root.top_level + "/config/ePixHRM320k_PacketRegisters.yml"
            print("Did not find filenamePacketReg file. Using generic.")

        self.filenamePowerSupply = self.root.top_level + "/config/ePixHRM320k_PowerSupply_Enable.yml"
        self.filenameWaveForms   = self.root.top_level + "/config/ePixHRM320k_RegisterControl.yml"
        self.filenameASIC        = self.root.top_level + "/config/ePixHRM320k_ASIC_u{}_PLLBypass.yml"
        self.filenameBatcher     = self.root.top_level + "/config/ePixHRM320k_BatcherEventBuilder.yml"      
        if arguments[0] == 1:
            self.filenamePLL         = self.root.top_level + "/config/EPixHRM320KPllConfig250Mhz.csv"
        if arguments[0] == 2:
            self.filenamePLL         = self.root.top_level + "/config/EPixHRM320KPllConfig125Mhz.csv"
        if arguments[0] == 3:
            self.filenamePLL         = self.root.top_level + "/config/EPixHRM320KPllConfig168Mhz.csv"
               
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
            if arguments[0] != 4 :
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


        if (not self.sim):
            # load deserializer
            print("Loading lane delay configurations")
            self.root.LoadConfig(self.filenameDESER)
            print("Loading {}".format(self.filenameDESER))

        

        # load config that sets waveforms
        print("Loading waveforms configuration")
        self.root.LoadConfig(self.filenameWaveForms)
        print("Loading {}".format(self.filenameWaveForms))


        # load batcher
        print("Loading batcher configurations")
        self.root.LoadConfig(self.filenameBatcher)
        print("Loading {}".format(self.filenameBatcher))

        # load config that sets packet registers
        print("Loading packet register configurations")
        self.root.LoadConfig(self.filenamePacketReg)
        print("Loading {}".format(self.filenamePacketReg))


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


        ## load config for the asic
        if not self.sim :
            print("Loading ASICs and timing configuration")
            for asicIndex in range(1 ,5, 1):
                if arguments[asicIndex] != 0:
                    self.root.LoadConfig(self.filenameASIC.format(asicIndex))
                    print("Loading {}".format(self.filenameASIC.format(asicIndex)))

        print("Initialization routine completed.")

        return
