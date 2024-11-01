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
import asic_reg_mapping.EpixHrMv2 as EpixHrMv2
import os
import numpy as np
import time
import surf.protocols.batcher       as batcher
import l2si_core as l2si
import pprint


class chargeInjection(pr.Process):
    def __init__(self, sim=False, **kwargs):
        super().__init__(**kwargs)

        self.add(pr.LocalVariable(
            name        = 'FirstColumn',
            description = 'First column index',
            mode        = 'WO',
            value       = 0
        ))

        self.add(pr.LocalVariable(
            name        = 'LastColumn',
            description = 'Last column index',
            mode        = 'WO',
            value       = 383
        ))

        self.add(pr.LocalVariable(
            name        = 'ASIC',
            description = 'Choose ASIC. -1 for all.',
            mode        = 'WO',
            value       = -1
        ))

        self.add(pr.LocalVariable(
            name        = 'PulserValue',
            description = 'Current value of the pulser',
            mode        = 'RO',
            value       = 0
        ))

class SweepDelaysPrintEyes(pr.Process):
    def __init__(self, sim=False, **kwargs):
        super().__init__(**kwargs)

        self.add(pr.LocalVariable(
            name        = 'Taps',
            description = 'Number of taps to sweep upon',
            mode        = 'WO',
            value       = 512
        ))

        self.add(pr.LocalVariable(
            name        = 'TimePerSweep',
            description = 'Time to wait during sweep ',
            mode        = 'WO',
            value       = 40
        ))

        self.add(pr.LocalVariable(
            name        = 'ASIC',
            description = 'Choose ASIC (0-3). -1 for all.',
            mode        = 'WO',
            value       = -1
        ))

        self.add(pr.LocalVariable(
            name        = 'TapsDone',
            description = 'Taps evaluated',
            mode        = 'RO',
            value       = ""
        ))


class App(pr.Device):
    def __init__(self, sim=False, **kwargs):
        super().__init__(**kwargs)
        
        num_of_asics = 4

      #############################################
      # Create block / variable combinations
      #############################################

        debugChEnum=[  {0:'AsicDM0', 1:'AsicDM1', 2:'AsicSync', 3:'AsicAcq', 4:'AsicSR0',  
                        5: 'AsicGRst', 6:'AsicClkEn', 7:'AsicR0', 8:'AsicSaciCmd0', 9:'AsicSaciClk', 
                        10:'AsicSaciSelL0', 11:'AsicSaciSelL1', 12:'AsicSaciSelL(2)',
                        13:'AsicSaciSelL(3)', 14: 'AsicRsp', 15:'LdoShutDnl0', 16:'LdoShutDnl1',
                        17: 'pllLolL', 18:'biasDacDin', 19: 'biasDacSclk',
                        20: 'biasDacCsb', 21: 'biasDacClrb', 22: 'hsDacCsb',
                        23: 'hsDacSclk', 24: 'hsDacDin', 25:'hsLdacb', 26: 'slowAdcDout0',
                        27: 'slowAdcDrdyL0', 28: 'slowAdcSyncL0', 29: 'slowAdcSclk0',
                        30: 'slowAdcCsL0', 31: 'slowAdcDin0' , 32: 'slowAdcRefClk(0)',
                        33: 'slowAdcDout1',
                        34: 'slowAdcDrdyL1', 35: 'slowAdcSyncL1', 36: 'slowAdcSclk1',
                        37: 'slowAdcCsL1', 38: 'slowAdcDin1' , 39: 'slowAdcRefClk1'},

                    {0:'AsicDM0'}]

        snEnum = { 0: 'CarrierIDLow', 1: 'CarrierIDHigh', 2: 'PowerAndCommIDLow', 3: 'PowerAndCommIDHigh',
                   4: 'DigIDLow', 5: 'DigIDHigh'}


        self.add(chargeInjection(name='SoftwareChargeInjection',
                                 description="[lower, upper, 'debug']from power 0 to 2^10-1, in steps of 2",
                                 function=self.fnChargeInjection))

        self.add(
            fpga.ChargeInjection(
                name='FPGAChargeInjection',
                offset=0x0A00_0000,
                expand=True,
                enabled=True
            )
        )

        self.add(SweepDelaysPrintEyes(name='SoftwareDelayDetermination',
                                 description='Manual serdes eye training',
                                 function=self.fnSweepDelaysPrintEyes))

        self.add(
            fpga.DelayDetermination(
                name='FPGADelayDetermination',
                offset=0x0B00_0000,
                numAsics = num_of_asics,
                expand=True,
                enabled=True
            )
        )


        for asicIdx in range(num_of_asics):
            self.add(
                EpixHrMv2.EpixHrMv2Asic(
                    name='Mv2Asic[{}]'.format(asicIdx),
                    offset=0x40_0000 * asicIdx,
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
                debugChEnum=debugChEnum,
                snEnum=snEnum
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
            enabled = True,
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







        #################################################################
    def stop_capture(self):
        self.root.runControl.runState.set(0)

    def start_capture(self):
        self.root.runControl.runState.set(1)

    def setupChargeInjection(self, asicIndex, lane_selected, pulserValue):
        self.Mv2Asic[asicIndex].enable.set(True)
        self.Mv2Asic[asicIndex].FE_ACQ2GR_en.set(True)
        self.Mv2Asic[asicIndex].FE_sync2GR_en.set(False)
        self.Mv2Asic[asicIndex].test.set(1) # connecting charge injection
        self.Mv2Asic[asicIndex].Pulser.set(int(pulserValue))
        for column in lane_selected:
            self.Mv2Asic[asicIndex].InjEn_ePixM.set(int(column))
            self.Mv2Asic[asicIndex].ClkInj_ePixM.set(1)
            # ff chain advances on falling edge of clock signal
            self.Mv2Asic[asicIndex].ClkInj_ePixM.set(0)

    def prepareChargeInjection(self, asicIndex, firstCol, lastCol, pulserValue):

        lane_selected = np.zeros(384)
        lane_selected[firstCol : lastCol + 1] = 1

        self.setupChargeInjection(asicIndex, lane_selected, pulserValue)


    def chargeInjectionCleanup(self, asicIndex):
        self.Mv2Asic[asicIndex].enable.set(True)
        self.Mv2Asic[asicIndex].FE_ACQ2GR_en.set(True)
        self.Mv2Asic[asicIndex].FE_sync2GR_en.set(False)
        self.Mv2Asic[asicIndex].test.set(0) 
        self.Mv2Asic[asicIndex].InjEn_ePixM.set(0)



    def fnChargeInjection(self, dev):
        with self.root.updateGroup(.25):

            """
            One time set reg
            """
            self.AsicTop.RegisterControlDualClock.SyncDelay.set(0)
            if (self.SoftwareChargeInjection.ASIC.get() == -1) :
                startAsic = 0
                endAsic = 4
            else :
                startAsic = self.SoftwareChargeInjection.ASIC.get()
                endAsic = self.SoftwareChargeInjection.ASIC.get() + 1         

            for asicIndex in range(startAsic, endAsic, 1) :
                print("Enabling ASIC {}".format(asicIndex))
                self.Mv2Asic[asicIndex].enable.set(True)
                self.Mv2Asic[asicIndex].FE_ACQ2GR_en.set(True)
                self.Mv2Asic[asicIndex].FE_sync2GR_en.set(False)
                self.Mv2Asic[asicIndex].test.set(1) # connecting charge injection

            # Hard coding the first adc column group
            lane_selected = np.zeros(384)
            lane_selected[self.SoftwareChargeInjection.FirstColumn.get() : self.SoftwareChargeInjection.LastColumn.get() + 1] = 1
            # lane_selected[0:63] = 1

            for asicIndex in range(startAsic, endAsic, 1) :
                self.Mv2Asic[asicIndex].InjEn_ePixM.set(1)
                self.Mv2Asic[asicIndex].Pulser.set(int(0))

            self.root.runControl.runState.set(0x0)

            for pulse_value in range(1, 1023, 2):
                self.SoftwareChargeInjection.Progress.set(pulse_value/1023) 

                for asicIndex in range(startAsic, endAsic, 1) :
                    self.Mv2Asic[asicIndex].Pulser.set(int(pulse_value))

                self.SoftwareChargeInjection.PulserValue.set(self.Mv2Asic[asicIndex].Pulser.get())

                for column in lane_selected:
                    if self.SoftwareChargeInjection._runEn == False :
                        for asicIndex in range(startAsic, endAsic, 1) :
                            self.Mv2Asic[asicIndex].test.set(0)                        
                        return
                    else :
                        for asicIndex in range(startAsic, endAsic, 1) :
                            self.Mv2Asic[asicIndex].InjEn_ePixM.set(int(column))
                            self.Mv2Asic[asicIndex].ClkInj_ePixM.set(1)
                            # ff chain advances on falling edge of clock signal
                            self.Mv2Asic[asicIndex].ClkInj_ePixM.set(0)

                self.root.Trigger()

            #disabling charge INJECTION
            for asicIndex in range(startAsic, endAsic, 1) :
                self.Mv2Asic[asicIndex].test.set(0)

        return
        
    def fnSweepDelaysPrintEyes(self, dev):
        with self.root.updateGroup(.25):
            if self.SoftwareDelayDetermination.ASIC.get() == -1 :
                startAsicIndex = 0
                endAsicIndex   = 4
                self.totalTaps = 4 * self.SoftwareDelayDetermination.Taps.get() * 2
            else : 
                startAsicIndex = self.SoftwareDelayDetermination.ASIC.get()
                endAsicIndex   = self.SoftwareDelayDetermination.ASIC.get()+1
                self.totalTaps = self.SoftwareDelayDetermination.Taps.get() * 2
            self.tapsDone = 0
                        
            for asicIndex in range(startAsicIndex, endAsicIndex, 1) :
                print("Sweeping ASIC {}".format(asicIndex))
                self.fnSweepDelaysPrintEye(asicIndex)
            

    def fnSweepDelaysPrintEye(self, asicIndex):
    

        if (self.root.App.PowerControl.DigitalSupplyEn.get() == 0x0) :
            raise Exception("Power on ASICs not enabled. Did you configure ASICs?")

        sweep_max = 511
        sweep_cnt = self.SoftwareDelayDetermination.Taps.get()
        time_per_sweep = float(self.SoftwareDelayDetermination.TimePerSweep.get())/100.0


        lane_adj_eyes_all = []

        # Disable batchers
        for i in range(4) :
            getattr(self.root.App.AsicTop, f"BatcherEventBuilder{i}").Blowoff.set(True)

        # number of lanes x sweep count
        all_errors = np.zeros((24, sweep_cnt)) # incase need to subtract

        self.SspMonGrp[asicIndex].enable.set(1)

        self.stop_capture()

        idle_lock_array = np.empty(24)

        # store automatic delay in idle_lock_array
        for i in range(24):
            idle_lock_array[i] = self.SspMonGrp[asicIndex].DlyConfig[i].get()

        # enable manual delay
        self.SspMonGrp[asicIndex].EnUsrDlyCfg.set(0x1)

        # generate a list of delays based on sweep_cnt start 0, end 511, hop sweep count.
        delay_space = (np.linspace(0,sweep_max,sweep_cnt))
        

        idle_results = np.zeros((24,sweep_cnt))


        for idx, delay in enumerate(delay_space):
            if self.SoftwareDelayDetermination._runEn == False :
                return                    

            # try one delay at a time for all lanes
            for lane in range(24):
                self.SspMonGrp[asicIndex].UsrDlyCfg[lane].set(int(delay))

            # reset counters
            self.SspMonGrp[asicIndex].CntRst.set(1)

            # send trigger
            self.start_capture()
            self.stop_capture()
            time.sleep(time_per_sweep)

            # Reset counters
            self.SspMonGrp[asicIndex].CntRst.set(1)
            time.sleep(time_per_sweep)
            self.stop_capture()

            # get Error det cnt for each lane when idle and not sending images
            for lane in range(24):
                idle_results[lane][idx] = self.SspMonGrp[asicIndex].ErrorDetCnt[lane].get()

            self.tapsDone = self.tapsDone + 1
            self.SoftwareDelayDetermination.Progress.set(self.tapsDone/self.totalTaps) 
            self.SoftwareDelayDetermination.TapsDone.set("{}/{}".format(self.tapsDone, self.totalTaps)) 

        # reset set delays
        self.SspMonGrp[asicIndex].EnUsrDlyCfg.set(0x0)
        time.sleep(1)

        # enable manual delay again
        self.SspMonGrp[asicIndex].EnUsrDlyCfg.set(0x1)

        # get delay results when sending images
        run_results = np.zeros((24,sweep_cnt))
        for idx, delay in enumerate(delay_space):
            if self.SoftwareDelayDetermination._runEn == False :
                return                       

            for lane in range(24):
                self.SspMonGrp[asicIndex].UsrDlyCfg[lane].set(int(delay))

            self.SspMonGrp[asicIndex].CntRst.set(1)
            self.start_capture()
            time.sleep(time_per_sweep)
            self.stop_capture()

            for lane in range(24):
                run_results[lane][idx] = self.SspMonGrp[asicIndex].ErrorDetCnt[lane].get()


            self.tapsDone = self.tapsDone + 1
            self.SoftwareDelayDetermination.Progress.set(self.tapsDone/self.totalTaps) 
            self.SoftwareDelayDetermination.TapsDone.set("{}/{}".format(self.tapsDone, self.totalTaps)) 

        self.stop_capture()

        print('Save to file')
        np.savetxt('idle_results{}.csv'.format(asicIndex), idle_results, delimiter=',')
        np.savetxt('run_results{}.csv'.format(asicIndex), run_results, delimiter=',')
        np.savetxt('delay_space{}.csv'.format(asicIndex), delay_space, delimiter=',')
        np.savetxt('idle_lock_array{}.csv'.format(asicIndex), idle_lock_array, delimiter=',')
        np.savetxt('all_errors{}.csv'.format(asicIndex), run_results + idle_results, delimiter=',')

        all_errors = run_results + idle_results
        lane_adj_eyes = self.F_FIND_EYES(delay_space, all_errors, False)
        self.F_SET_DELAYS(lane_adj_eyes, asicIndex)
        print(" ASIC {} manual delay is {}".format(asicIndex, lane_adj_eyes))

        self.SspMonGrp[asicIndex].EnUsrDlyCfg.set(0x1)

        # Enabling batchers again
        for i in range(4) :
            getattr(self.root.App.AsicTop, f"BatcherEventBuilder{i}").Blowoff.set(False)


    def F_FIND_EYES(self, delay_vec, lane_errors, TROUBLE_SHOOT_FIND_EYES):
        num_of_lanes,num_of_delay_steps = lane_errors.shape
        num_eye_info = 3 # returning lane, delay center, width of each eye
        lane_eyes = np.zeros((num_of_lanes,num_eye_info), dtype='uint16')
        for lane in range(num_of_lanes):
            cntr, wdth = self.F_FIND_EYE(delay_vec,lane_errors[lane][0:num_of_delay_steps],TROUBLE_SHOOT_FIND_EYES)
            lane_eyes[lane][:] = (np.array([lane, cntr, wdth])).flatten()
        #end-for
        return lane_eyes
        #end-def

    def F_FIND_EYE(self, v_lane_dly, v_lane_err, TROUBLE_SHOOT_FIND_EYES):
        v_lane_dly = (np.array(v_lane_dly,dtype='uint16')).flatten() # making delay an int array
        # finding err-power at a given delay
        v_err_pwr = np.array( np.ceil( np.log10(v_lane_err+1) ) - 1, dtype='int8').flatten()
        # min power of whole vector
        pwr_min = np.amin(v_err_pwr)
        # where the min power levels happen
        v_idx_min = (np.array(np.where(v_err_pwr==pwr_min),dtype='uint16')).flatten()
        # can't use diff due to need to be able to see if a single min happens
        #v_d_idx_min = (np.array(np.diff(v_idx_min),dtype='uint16')).flatten()
        # looking for start and stop index of longest strip
        idx_count = 0
        idx_count_max = 0
        idx_0 = -1
        idx_f = -1
        for k, idx in enumerate(v_idx_min):
            #print(f'{k},{idx},{v_idx_min[k]}')
            if k == 0:
                idx_old = idx - 1
            #end-if
            if idx - idx_old == 1:
                idx_count += 1
            else:
                # reset idx_count
                if idx_count > idx_count_max:
                    idx_count_max = idx_count
                    idx_count = 0
                    idx_0 = v_idx_min[k-idx_count_max]
                    idx_f = v_idx_min[k-1]
                #end-if
            #end-if-else
            idx_old = idx
        #end-for
        if idx_count_max == 0: # never skipped
            idx_count_max = idx_count
            idx_0 = v_idx_min[0]
            idx_f = v_idx_min[-1]
        #end-if
        # finding eye
        eye_width = v_lane_dly[idx_f] - v_lane_dly[idx_0] + 1
        delay = int( np.mean(v_lane_dly[idx_0:idx_f+1]) )

        if TROUBLE_SHOOT_FIND_EYES:
            pprint.pprint( v_lane_err )
            print(f'[I_0,I_f,val]=[{idx_0},{idx_f},{idx_count_max}]')
            pprint.pprint( v_err_pwr )
            pprint.pprint( v_idx_min )
            pprint.pprint( v_lane_dly )
            pprint.pprint( v_lane_dly[idx_0:idx_f+1] )
            print(f'{delay} {eye_width} TBD')
            print('\n')
        #end-if
        # RETURN: Delay ceneter, width of eye
        return delay, eye_width
        #end-defi


    def F_SET_DELAYS(self, lane_adj_eyes, asicIndex):
        num_of_lanes,num_of_eye_info = lane_adj_eyes.shape # returning lane, delay center, width of each eye
        # Disable & wait & Enabling user to change delay
        self.SspMonGrp[asicIndex].EnUsrDlyCfg.set(0x1)
        # set delay
        for lane in range(num_of_lanes):
            crnt_dly = int(lane_adj_eyes[lane][1])
            self.SspMonGrp[asicIndex].UsrDlyCfg[lane].set(crnt_dly)
        #end-for
        # reset all error counters
        self.SspMonGrp[asicIndex].CntRst.set(1) # resets counters
        time.sleep(1)
        #end def

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

