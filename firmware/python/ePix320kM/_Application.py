#-----------------------------------------------------------------------------
# This file is part of the 'epix-320k-m'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'Development Board Examples', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------


import pyrogue as pr

import surf
import surf.protocols.ssp as ssp

import ePix320kM as fpga
import epix_hr_leap_common as ePixHrleapCommon

import os
import numpy as np
import time
import surf.protocols.batcher       as batcher
import l2si_core as l2si

class App(pr.Device):
    def __init__(self, sim=False, **kwargs):
        super().__init__(**kwargs)
        
        num_of_asics = 4

      #############################################
      # Create block / variable combinations
      #############################################

        debugChEnum=[  {0:'AsicDM(0)', 1:'AsicDM(1)', 2:'AsicSync', 3:'AsicAcq', 4:'AsicSR0',  
                        5: 'AsicGRst', 6:'AsicSaciCmd(0)', 7:'AsicSaciClk', 
                        8:'AsicSaciSelL(0)', 9:'AsicSaciSelL(1)', 10:'AsicSaciSelL(2)',
                        11:'AsicSaciSelL(3)', 12:'LdoShutDnl0', 13:'LdoShutDnl1',
                        14: 'pllLolL', 15:'biasDacDin', 16: 'biasDacSclk',
                        17: 'biasDacCsb', 18: 'biasDacClrb', 19: 'hsDacCsb',
                        20: 'hsDacSclk', 21: 'hsDacDin', 22:'hsLdacb'},

                    {0:'AsicDM(1)'}]


        for i in range(num_of_asics):
            self.add(
                fpga.EpixMv2Asic(
                    name='Mv2Asic[{}]'.format(i),
                    offset=0x0000_0000 + 0x0100_0000 * i,
                    expand=False,
                    enabled=False
                )
            )

        for i in range(num_of_asics):
            self.add(ssp.SspLowSpeedDecoderReg(
                name        = f'SspMonGrp[{i}]',
                offset      = 0x0400_0000+i*0x1000,
                numberLanes = 24,
                enabled=False
            ))
        
        self.add(
            ePixHrleapCommon.AsicTop(
                name='AsicTop',
                offset=0x0500_0000,
                expand=False,
                enabled=True,
                asicStreams=4,
                debugChEnum=debugChEnum
            )
        )

        self.add(
            fpga.PowerControl(
                name='PowerControl',
                offset=0x0600_0000,
                expand=True,
                enabled=True
            )
        )
    
        self.add(
            fpga.Adc(
                name='Adcs',
                offset=0x0700_0000,
                expand=False,
                enabled=True
            )
        )

        self.add(ePixHrleapCommon.Dac(
            name = "Dac",
            offset = 0x0800_0000,
            enabled = False,
        ))

        self.add(
            ePixHrleapCommon.TimingRx(
                name='TimingRx',
                offset=0x0900_0000,
                expand=False,
                enabled=True
            )
        )


        self.add(pr.LocalCommand( name='InitHSADC',   
                                  description='Initialize the HS ADC used by the scope module', 
                                  value='',
                                  function=self.fnInitHsADC
        ))


        self.add(pr.LocalVariable(
            name        = 'RunState',
            description = 'Run state status, which is controlled by the StopRun() and StartRun() commands',
            mode        = 'RO',
            value       = False,
        ))

        @self.command(description  = 'Stops the triggers and blows off data in the pipeline')
        def StopRun():
            print (f'{self.path}.StopRun() executed')

            # Get devices
            eventBuilder = self.find(typ=batcher.AxiStreamBatcherEventBuilder)
            trigger      = self.find(typ=l2si.TriggerEventBuffer)

            # Turn off the triggering
            for devPtr in trigger:
                devPtr.MasterEnable.set(False)
                print("{} turned off".format(devPtr.name))

            # Flush the downstream data/trigger pipelines
            for devPtr in eventBuilder:
                devPtr.Blowoff.set(True)
                print("{} flushed".format(devPtr.name))

            # Update the run state status variable
            self.RunState.set(False)

        @self.command(description  = 'starts the triggers and allow steams to flow to DMA engine')
        def StartRun():
            print (f'{self.path}.StartRun() executed')

            # Get devices
            eventBuilder = self.find(typ=batcher.AxiStreamBatcherEventBuilder)
            trigger      = self.find(typ=l2si.TriggerEventBuffer)

            # Reset all counters
            #self.CountReset()

            # Arm for data/trigger stream
            for devPtr in eventBuilder:
                devPtr.Blowoff.set(False)
                devPtr.SoftRst()
                print("{} armed".format(devPtr.name))

            # Turn on the triggering
            for devPtr in trigger:
                devPtr.MasterEnable.set(True)
                print("{} turned on".format(devPtr.name))

            # Update the run state status variable
            self.RunState.set(True) 


    def fnInitHsADC(self, dev,cmd,arg):
        """Initialization routine for the HS ADC"""

        for adcIdx in range(0,2):
            self.Adc.FastADCsDebug[adcIdx].enable.set(True)   
            self.Adc.FastADCsDebug[adcIdx].DelayAdc0.set(15)
            self.Adc.FastADCsDebug[adcIdx].enable.set(False)

        self.Adc.FastADCsConfig.enable.set(True)
        self.root.readBlocks()

        for adcIdx in range(0,2):
            self.Adc.FastADCsDebug[adcIdx].DelayAdc0.set(15)
            self.Adc.FastADCsDebug[adcIdx].enable.set(False)

        self.Adc.FastADCsConfig.enable.set(True)
        self.root.readBlocks()
        self.Adc.FastADCsConfig.InternalPdwnMode.set(3)
        self.Adc.FastADCsConfig.InternalPdwnMode.set(0)
        self.Adc.FastADCsConfig.OutputFormat.set(0)
        self.root.readBlocks()
        self.Adc.FastADCsConfig.enable.set(False)
        self.root.readBlocks()
        print("Fast ADC initialized")
        
'''
    def fnSetWaveform(self, dev,cmd,arg):
        """SetTestBitmap command function"""
        self.filename = QtGui.QFileDialog.getOpenFileName(self.root.guiTop, 'Open File', '', 'csv file (*.csv);; Any (*.*)')
        if os.path.splitext(self.filename)[1] == '.csv':
            waveform = np.genfromtxt(self.filename, delimiter=',', dtype='uint16')
            if waveform.shape == (1024,):
                for x in range (0, 1024):
                    self.Dac.waveformMem._rawWrite(offset = (x * 4),data =  int(waveform[x]))
            else:
                print('wrong csv file format')

    def fnGetWaveform(self, dev,cmd,arg):
        """GetTestBitmap command function"""
        self.filename = QtGui.QFileDialog.getOpenFileName(self.root.guiTop, 'Open File', '', 'csv file (*.csv);; Any (*.*)')
        if os.path.splitext(self.filename)[1] == '.csv':
            readBack = np.zeros((1024),dtype='uint16')
            for x in range (0, 1024):
                readBack[x] = self.Dac.waveformMem._rawRead(offset = (x * 4))
            np.savetxt(self.filename, readBack, fmt='%d', delimiter=',', newline='\n')

    def fnAcqDataWithSaciClkRstScript(self, dev,cmd,arg):
        """SetTestBitmap command function"""       
        print("Acquiring data with clock reset between frames")            
        delay = 1
        numFrames = arg
        if numFrames == 0:
            numFrames = 100
        print("A total of %d frames will be added to the current file" % (numFrames))

        self.root.dataWriter.enable.set(True)
        self.currentFilename = self.root.dataWriter.dataFile.get()
        self.root.dataWriter.dataFile.set(self.currentFilename +"_refData"+".dat")

        print("Saving reference data")
        for frame in range(numFrames):
            #resync channels
            self.DeserRegisters0.Resync.set(True)
            self.DeserRegisters2.Resync.set(True)
            time.sleep(delay) 
            self.DeserRegisters0.Resync.set(False)
            self.DeserRegisters2.Resync.set(False)

            #enable to write frames          
            self.root.dataWriter.open.set(True)

            #acquire an image
            self.root.Trigger()
            time.sleep(delay) 
            
            #close file
            self.root.dataWriter.open.set(False)

            #no issued reset
            #self.Hr10kTAsic0.DigRO_disable.set(True)
            #self.Hr10kTAsic2.DigRO_disable.set(True)
            #self.Hr10kTAsic0.DigRO_disable.set(False)
            #self.Hr10kTAsic2.DigRO_disable.set(False)

        self.root.dataWriter.dataFile.set(self.currentFilename +"_testData"+".dat")
        print("Saving test data")
        for frame in range(numFrames):
            #resync channels
            self.DeserRegisters0.Resync.set(True)
            self.DeserRegisters2.Resync.set(True)
            time.sleep(delay) 
            self.DeserRegisters0.Resync.set(False)
            self.DeserRegisters2.Resync.set(False)

            #enable to write frames          
            self.root.dataWriter.open.set(True)

            #acquire an image
            self.root.Trigger()
            time.sleep(delay) 
            
            #close file
            self.root.dataWriter.open.set(False)

            #issue reset
            self.Hr10kTAsic0.DigRO_disable.set(True)
            self.Hr10kTAsic2.DigRO_disable.set(True)
            self.Hr10kTAsic0.DigRO_disable.set(False)
            self.Hr10kTAsic2.DigRO_disable.set(False)
        
            


    def fnScanSDrstSDClkScript(self, dev,cmd,arg):
        """SetTestBitmap command function"""       
        print("ASIC0 SDrst and SDclk scan started")
        print(arg)
        delay = 1
        self.root.readBlocks()
        #save filename
        self.root.dataWriter.enable.set(True)
        self.root.dataWriter.open.set(False)
        self.currentFilename = self.root.dataWriter.dataFile.get()

        # scan routine
        for SDrstValue  in range(16):
            for SDclkValue  in range(16):
                self.Hr10kTAsic0.SDrst_b.set(SDrstValue)
                self.Hr10kTAsic0.SDclk_b.set(SDclkValue)
                time.sleep(delay/5)               
                self.root.dataWriter.dataFile.set(self.currentFilename +"_SDrst_"+ str(SDrstValue)+"_SDclk_"+ str(SDclkValue)+".dat")
                self.root.dataWriter.open.set(True)
                # acquire data for 1 second
                time.sleep(delay)               
                self.root.dataWriter.open.set(False)       

        print("Completed")
'''



