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
import pprint

class App(pr.Device):
    def __init__(self, sim=False, **kwargs):
        super().__init__(**kwargs)
        
        num_of_asics = 4

      #############################################
      # Create block / variable combinations
      #############################################

        debugChEnum=[  {0:'AsicDM(0)', 1:'AsicDM(1)', 2:'AsicSync', 3:'AsicAcq', 4:'AsicSR0',  
                        5: 'AsicGRst', 6:'AsicClkEn', 7:'AsicR0', 8:'AsicSaciCmd(0)', 9:'AsicSaciClk', 
                        10:'AsicSaciSelL(0)', 11:'AsicSaciSelL(1)', 12:'AsicSaciSelL(2)',
                        13:'AsicSaciSelL(3)', 14: 'AsicRsp', 15:'LdoShutDnl0', 16:'LdoShutDnl1',
                        17: 'pllLolL', 18:'biasDacDin', 19: 'biasDacSclk',
                        20: 'biasDacCsb', 21: 'biasDacClrb', 22: 'hsDacCsb',
                        23: 'hsDacSclk', 24: 'hsDacDin', 25:'hsLdacb', 26: 'slowAdcDout(0)',
                        27: 'slowAdcDrdyL(0)', 28: 'slowAdcSyncL(0)', 29: 'slowAdcSclk(0)',
                        30: 'slowAdcCsL(0)', 31: 'slowAdcDin(0)' , 32: 'slowAdcRefClk(0)',
                        33: 'slowAdcDout(1)',
                        34: 'slowAdcDrdyL(1)', 35: 'slowAdcSyncL(1)', 36: 'slowAdcSclk(1)',
                        37: 'slowAdcCsL(1)', 38: 'slowAdcDin(1)' , 39: 'slowAdcRefClk(1)'},

                    {0:'AsicDM(1)'}]

        snEnum = { 0: 'CarrierIDLow', 1: 'CarrierIDHigh', 2: 'PowerAndCommIDLow', 3: 'PowerAndCommIDHigh',
                   4: 'DigIDLow', 5: 'DigIDHigh'}
        
        for asicIdx in range(num_of_asics):
            self.add(
                fpga.EpixMv2Asic(
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


        self.add(pr.LocalCommand(name='SetMaxRunRateHz',
                                 description="[MAX Run-Rate,'debug'] Setting run-rate[Hz] (ADC) via setting main clock devider",
                                 value = [5200, 'debug'],
                                 function=self.F_SET_RUN_RATE))

        self.add(pr.LocalCommand(name='SetFrameRateHz',
                                 description="[Frame-Rate,'debug'] Setting Frame-rate[Hz] (Data) via firmware trigger",
                                 value = [5000, 'debug'],
                                 function=self.F_SET_FRAME_RATE))

        self.add(pr.LocalCommand(name='SetPIPODelays',
                                 description="['debug'] forcing pipo to a preset value that is know to work",
                                 value = ['debug'],
                                 function=self.F_SET_PIPO_DELAYS))

        self.add(pr.LocalCommand(name='SetIntegrationTimeus',
                                 description="[INT_TIME_us, R0_wait_us, R0_2_SR0_Dly_us, 'debug'] int-time [usec], R0 delay after ACQ falls[usec], SRO delay after R0 falls [usec]",
                                 value = [1,0,0,'debug'],
                                 function=self.F_SET_INT_TIME))

        self.add(pr.LocalCommand(name='ToggelRegFE_sync2GN_en',
                                 description="['debug'] shows state between steps of togling",
                                 value = ['debug'],
                                 function=self.F_tgl_FE_sync2GR_en))

        self.add(pr.LocalCommand(name='TuneManual_SERDES_Eye_Training',
                                 description='[N_step,t_sweep] from 0 to 511 number steps waiting t_sweep at each step formally Sweep-Print-Delay eyes still debating if worth using... leaning  heavily no!',
                                 value = [40, 10],
                                 function=self.fnSweepDelaysPrintEyes))

        self.add(pr.LocalCommand(name='TestChargeInjection',
                                 description="[lower, upper, 'debug']from power 0 to 2^10-1, in steps of 2",
                                 value = [0, 63, 'debug'],
                                 function=self.fnChargeInjection))

        self.add(pr.LocalCommand(name='TestChargeInjectionStep',
                                 description="Same as the charge injection function but will loop through the full asic",
                                 value = ['debug'],
                                 function=self.fnChargeInjection_stepped))

        self.add(pr.LocalCommand(name='TestRampDACtosweepADC',
                                 description="[enable_ramp,run_rate_Hz, frame_rate_Hz, dac_start, dac_stop, dac_step,'debug'] from 0 to 65535 DAC sweep adc values and plot hist of outputs can store a single sweep not in debug mode",
                                 value = [False, 5200, 5000, 0, 65535, 1],
                                 function=self.F_RAMP_DAC_TO_SWEEP_ADC))

        #################################################################

    def stop_capture(self):
        self.root.runControl.runState.set(0)

    def start_capture(self):
        self.root.runControl.runState.set(1)

    """
    >>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ADC RAMP: START <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    """
    def F_RAMP_DAC_TO_SWEEP_ADC(self, dev, cmd, arg):
        # arg[0] enable or disable DAC-ramp
        # arg[1] [Hz] run rate (ADC frequency)
        # arg[2] [Hz] frame rate (DATA frequency < ADC frequency)
        # arg[3] start
        # arg[4] stopped
        # arg[5] step
        # arg[6] 'debug' (optional)
        # we got a hiden comand
        if 'debug' in arg:
            debug = True
        else:
            debug = False

        # inputs
        EN_RAMP = arg[0] # enable DAC RAMP TEST OF ADC_CLK
        run_rate_Hz = max([arg[1],arg[2]]) # how fast to run the ADCs [Hz]
        frame_rate_Hz = min([arg[2],arg[1]]) # how fast to run the data rate [Hz]
        dac_min = min([arg[3],arg[4]]) # where dac will start
        dac_max = max([arg[4],arg[3]])
        dac_step = arg[5]

        # stuff to generally enable and set
        self.Mv2Asic[2].enable.set(True) # changing mTest state

        """
        DAC RAMP STUFF
        """
        if EN_RAMP:
            # make sure firm-ware triggers are stopped, going to capture a sigle ramp
            self.stop_capture() # stop software triggers, use firmware
            self.AsicTop.TriggerRegisters.RunTriggerEnable.set(False)
            if debug:
                print('\tWARNING: Disabling all triggers')
            # end-if

            self.F_EN_mTest(True,debug) # connecting ADC to DAC
            # this are GUI level functions, why we are passing dev & cmd into these functons
            self.F_SET_RUN_RATE(dev, cmd, [run_rate_Hz]) # starting up ADCs on firmware triggers
            self.F_SET_FRAME_RATE(dev, cmd, [frame_rate_Hz]) # setting frame rate of data
            if debug:
                # quick step to show ADC is working manul mode
                self.F_show_DAC_V_range(dac_min, dac_max)
            # end-if
            self.F_EN_DAC_FOR_RAMP(True) # RAMP MODE AT FRAME RATE
            self.F_SET_DAC_FOR_RAMP(dac_min,dac_max,dac_step)
            if not debug:
                # disable firmware TriggerRegisters
                print('\tWARNING: Disabling Firmware Triggers, close file...')
                self.TriggerRegisters.RunTriggerEnable.set(False)
            # end-if

        else:
            self.F_EN_mTest(False,debug) # disconnecting ADC from DAC
            self.F_EN_DAC_FOR_RAMP(False) # setting HSDac to manual mode
            self.HSDac.enable.set(False) # disabling HSDac

    def F_show_DAC_V_range(self, dac_min, dac_max):
        self.F_EN_DAC_FOR_RAMP(False) # setting HSDac to manual mode
        self.HSDac.DacValue.set(dac_max)
        time.sleep(0.1)
        print('\tDacValueV = {}[V]'.format(self.HSDac.DacValueV.get()))
        time.sleep(1)
        self.HSDac.DacValue.set(dac_min)
        time.sleep(0.1)
        print('\tDacValueV = {}[V]\n'.format(self.HSDac.DacValueV.get()))

    def F_EN_mTest(self, EN_mTest, debug):
        if debug:
            print('\tmTest = {}'.format(self.Mv2Asic[2].mTest.get()))
        # end-if
        # what connects ADC to DacChannel
        self.Mv2Asic[2].mTest.set(EN_mTest)
        if debug:
            print('\tmTest = {}\n'.format(self.Mv2Asic[2].mTest.get()))
        # end-if

    def F_EN_DAC_FOR_RAMP(self, EN_DAC):
        self.HSDac.enable.set(True) # just enabling always
        self.HSDac.WFEnabled.set(EN_DAC)
        self.HSDac.run.set(EN_DAC)
        self.HSDac.externalUpdateEn.set(EN_DAC)
        if EN_DAC:
            self.HSDac.waveformSource.set(0x1) # ramp usage
        else:
            self.HSDac.waveformSource.set(0x0) # when manual or disable
        # end-if
        self.HSDac.DacChannel.set(1) # Sets DAC A SE mode, should be 1 always

    def F_SET_DAC_FOR_RAMP(self, dac_min,dac_max,dac_step):
        self.HSDac.rCStartValue.set(dac_min)
        self.HSDac.rCStopValue.set(dac_max)
        self.HSDac.rCStep.set(dac_step)

    #<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ADC RAMP: END >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
    """
    >>>>>>>>>>>>>>>>>>>>>>>>> CHARGE-INJECTION: START <<<<<<<<<<<<<<<<<<<<<<<<<<
    """
    def fnChargeInjection_stepped(self, dev, cmd, arg):
        # we got a hiden comand
        if 'debug' in arg:
            # print(cmd)
            debug = True
        else:
            debug = False

        """
        One time set reg
        """
        self.Mv2Asic[2].test.set(1) # connecting charge injection

        column_list = [0, 63, 127, 191, 255, 319, 383]

        for column in range(len(column_list) - 1):

            lane_selected = np.zeros(384)
            lane_selected[column_list[column] : column_list[column + 1]] = 1
            # lane_selected[0:63] = 1

            if debug:
                print(lane_selected)
                print('lower bound {}'.format(column_list[column]))
                print('upper bound {}'.format(column_list[column + 1]))

            self.Mv2Asic[2].InjEn_ePixM.set(1)
            self.Mv2Asic[2].Pulser.set(int(0))
            self.root.runControl.runState.set(0x0)

            for pulse_value in range(0, 1023, 2):
                if debug:
                    print('previous pulser val: {}'.format(self.Mv2Asic[2].Pulser.get()))

                self.Mv2Asic[2].Pulser.set(int(pulse_value))

                if debug:
                    print('set Pulser Value: {}'.format(self.Mv2Asic[2].Pulser.get()))

                # When running with sleep time @ 0.001 vs 0.002[sec] took 106 vs 107[sec]
                # time dominated by loop bellow
                for column in lane_selected:
                    self.Mv2Asic[2].InjEn_ePixM.set(int(column))
                    self.Mv2Asic[2].ClkInj_ePixM.set(1)
                    # ff chain advances on falling edge of clock signal
                    self.Mv2Asic[2].ClkInj_ePixM.set(0)

                self.root.Trigger()

        #disabling charge INJECTION
        self.Mv2Asic[2].test.set(0) # connecting charge injection

        return

    def fnChargeInjection(self, dev, cmd, arg):
        # we got a hiden comand
        if 'debug' in arg:
            # print(cmd)
            debug = True
        else:
            debug = False

        """
        One time set reg
        """
        self.AsicTop.RegisterControlDualClock.SyncDelay.set(0)
        self.Mv2Asic[2].FE_ACQ2GR_en.set(True)
        self.Mv2Asic[2].FE_sync2GR_en.set(False)
        self.Mv2Asic[2].test.set(1) # connecting charge injection

        # Hard coding the first adc column group
        lane_selected = np.zeros(384)
        lane_selected[arg[0] : arg[1]] = 1
        # lane_selected[0:63] = 1

        if debug:
            print(lane_selected)

        self.Mv2Asic[2].InjEn_ePixM.set(1)
        self.Mv2Asic[2].Pulser.set(int(0))
        self.root.runControl.runState.set(0x0)

        for pulse_value in range(1, 1023, 2):
            if debug:
                print('previous pulser val: {}'.format(self.Mv2Asic[2].Pulser.get()))

            self.Mv2Asic[2].Pulser.set(int(pulse_value))

            if debug:
                print('set Pulser Value: {}'.format(self.Mv2Asic[2].Pulser.get()))

            # When running with sleep time @ 0.001 vs 0.002[sec] took 106 vs 107[sec]
            # time dominated by loop bellow
            for column in lane_selected:
                self.Mv2Asic[2].InjEn_ePixM.set(int(column))
                self.Mv2Asic[2].ClkInj_ePixM.set(1)
                # ff chain advances on falling edge of clock signal
                self.Mv2Asic[2].ClkInj_ePixM.set(0)

            self.root.Trigger()

        #disabling charge INJECTION
        self.Mv2Asic[2].test.set(0) # connecting charge injection

        return

    #<<<<<<<<<<<<<<<<<<<<<<<<<< CHARGE-INJECTION: END >>>>>>>>>>>>>>>>>>>>>>>>>#
    """
    ############################################################################
    >>>>>>>>>>>>>>>>>>>>>>>> TOGEL GLOBAL RESET: START  <<<<<<<<<<<<<<<<<<<<<<<<
    """
    def F_tgl_FE_sync2GR_en(self, dev, cmd, arg):
        # toggling FE_sync2GN_en register
        # INPUT(S):
        #   arg[-1]     (OPT) 'debug' enables function debug option
        """
        LANE INPUTS
        """
        if 'debug' in arg:
            debug = True
            print('20221104_130752, Debugging: F_tgl_FE_sync2GR_en')
            print('\tFor ePixM: Want FE_syn2GR_en = False')
        else:
            debug = False

        # toggeling
        reg_state = self.Mv2Asic[2].FE_sync2GR_en.get()
        print('\tFE_sync2GR_en = {}',format(reg_state))
        self.Mv2Asic[2].FE_sync2GR_en.set(not reg_state) # toggle
        reg_state = self.Mv2Asic[2].FE_sync2GR_en.get()
        print('\tFE_sync2GR_en = {}',format(reg_state))
        print('\n')


    #<<<<<<<<<<<<<<<<<<<<<<<< TOGEL GLOBAL RESET: END  >>>>>>>>>>>>>>>>>>>>>>>>#
    """
    >>>>>>>>>>>>>>>>>>>>>>>>> SET INTEGRATION: START  <<<<<<<<<<<<<<<<<<<<<<<<<<
    """
    def F_SET_INT_TIME(self, dev, cmd, arg):
        # INPUT(S):
        #   arg[0]      INT_TIME_us integration time in [usec]
        #   arg[1]      R0_2_SR0_Dly_us delay time between R0 and SR0 [usec]
        #   arg[-1]     (OPT) 'debug' enables function debug option
        """
        LANE INPUTS
        """
        INT_TIME_us = arg[0] # [usec] desired integration time
        R0_wait_us = arg[1] # [usec] wait time after R0
        R0_2_SR0_Dly_us = arg[2] # [usec] time between integration and conversion
        if 'debug' in arg:
            debug = True
            print('20220926_075621, Debugging: F_SET_INT')
        else:
            debug = False

        # ARE WE RUNNING FROM FIRMWARE OR SOFTWARE TRIG
        print('\tWARNING: Set up trigger before integration')
        if self.root.runControl.runState.get():
            FIRMWARE_TRIGGERING = False
        else:
            if self.TriggerRegisters.enable.get():
                if self.TriggerRegisters.RunTriggerEnable.get():
                    if self.TriggerRegisters.AutoTrigPeriod.get() > 0:
                        FIRMWARE_TRIGGERING = True
                    else:
                        FIRMWARE_TRIGGERING = False
                else:
                    FIRMWARE_TRIGGERING = False
            else:
                FIRMWARE_TRIGGERING = False

        if not FIRMWARE_TRIGGERING:
            print('\tWARNING! Software triggering')

        # now we know what type of triggering we are doing
        # how long is the frame time?
        UNIT_TIME = 10 # [ns]
        MIN_TIME = 1000 # [ns] min time between steps
        SAFTY_FACTOR = 1.05
        # converting user relative-wait-time input(s) to [nsec]
        R0_WAIT_TIME = max([0,1000*R0_wait_us ]) #[ns] RELATIVE TIME
        R0_2_SR0_Delay_TIME = max([0,1000 * R0_2_SR0_Dly_us]) # [ns] RELATIVE TIME
        if FIRMWARE_TRIGGERING:
            FRAME_TIME = self.TriggerRegisters.AutoTrigPeriod.get() * UNIT_TIME # [ns]
            FRAME_FREQ = 1e9/FRAME_TIME # [Hz]
        else:
            FRAME_FREQ = self.root.runControl.runRate.get() # [Hz]
            FRAME_TIME = 1e9 / FRAME_FREQ # [ns]

        print(f'\tFrame Freq = {FRAME_FREQ:g}[Hz]')
        print(f'\tFrame Time = {FRAME_TIME/1000:g}[us]')

        # now need to esiamte SRO (ADC) duration based on clock frequency
        PIX_per_ADC = 2 * 48 # number of pixels per ADC [columns * rows]
        MAIN_CLK = 2e9 # [Hz] main clock
        PIX_per_lane = 64 # how many pixel columns there are in a given ADC-lane or group
        ADC_CLK_DIV = 5 # how many times ADC_CLK is divived by the Serdes_CLK
        # calcs
        CLK_DIV_LOW = self.MMCMRegisters.CLKOUT0LowTime.get()
        CLK_DIV_HIGH = self.MMCMRegisters.CLKOUT0HighTime.get()
        Serdes_CLK = MAIN_CLK / (CLK_DIV_LOW + CLK_DIV_HIGH)
        ADC_CLK = Serdes_CLK / ADC_CLK_DIV # [Hz] not sure why divided by 5, ADC clock is
        ADC_LANE_CLK = ADC_CLK / PIX_per_lane # [Hz]
        ADC_LANE_TIME = 1e9 / ADC_LANE_CLK # [ns]
        SRO_Duration = np.ceil(SAFTY_FACTOR * PIX_per_ADC * ADC_LANE_TIME) #[ns]

        print(f'\tSRO Duration < {np.ceil(SRO_Duration/1000):g}[us]')

        # setting integration time
        INT_Duration = INT_TIME_us*1000 # [ns]
        # Setting integration window time R0
        OFFSET_Duration = INT_Duration # should be the same as INT_Duration
        INT_WINDOW_Duration = (2 * OFFSET_Duration) + R0_WAIT_TIME
        INT_WINDOW_Delay_Time = MIN_TIME
        # setting integration time (ACQ)
        # duration set above, and placing integration in middle of window
        INT_Delay_Time = MIN_TIME + OFFSET_Duration
        # setting intergartion window time (R0)
        # setting ADC time (SRO)
        # already found SRO_Duration above, and moving SRO to the end of the integration window
        SRO_Delay_Time = INT_WINDOW_Delay_Time + INT_WINDOW_Duration + R0_2_SR0_Delay_TIME

        # off-set (noise integration time) [usec]
        print('\tOffset Integration: {}[us]'.format( 0.001*(OFFSET_Duration) ))
        # integration of signal
        print('\tSignal Integration: {}[us]'.format( 0.001*(INT_Duration) ))

        # setting relative times [10s-of-ns], actually unitless
        RLTV_FRM_TIME = int( FRAME_TIME / UNIT_TIME )
        # ADC setups: FIXED DELAY and width based on clock
        RLTV_SR0_W_TIME = int( SRO_Duration / UNIT_TIME ) # [10s-of-ns] width time
        #RLTV_SR0_D_TIME = int( SRO_Delay_TIME_MAX / UNIT_TIME ) # <-- places at end of frame
        RLTV_SR0_D_TIME = int( SRO_Delay_Time / UNIT_TIME ) # at end of int-window
        # INT time, ACQ relative-time
        RLTV_ACQ_W_TIME = int( INT_Duration / UNIT_TIME ) # [10s-of-ns]
        RLTV_ACQ_D_TIME = int( INT_Delay_Time / UNIT_TIME ) # [10s-of-ns]
        # INT WINDOW, R0 relative-time
        RLTV_R0_W_TIME = int( INT_WINDOW_Duration / UNIT_TIME ) # [10s-of-ns]
        RLTV_R0_D_TIME = int( INT_WINDOW_Delay_Time / UNIT_TIME ) # [10s-of-ns]

        if debug:
            print('\n') # first debug statement, adding \n
            print(f'\tFRAME TIME = {RLTV_FRM_TIME:g}[10s-of-ns]')

        # READ & DUMP integral registers
        self.F_READ_INT_REG(True, debug)

        # set VALUES
        self.RegisterControl.enable.set(True)
        self.RegisterControl.R0Delay.set(RLTV_R0_D_TIME)
        self.RegisterControl.R0Width.set(RLTV_R0_W_TIME)
        self.RegisterControl.AcqDelay1.set(RLTV_ACQ_D_TIME)
        self.RegisterControl.AcqWidth1.set(RLTV_ACQ_W_TIME)
        self.RegisterControl.SR0Delay1.set(RLTV_SR0_D_TIME)
        self.RegisterControl.SR0Width1.set(RLTV_SR0_W_TIME)

        # READ & DUMP integral registers
        self.F_READ_INT_REG(False, debug)
        print('\n')

    #--------------------------------------------------------------------------#
    def F_READ_INT_REG(self, FIRST_CALL, debug):
        self.RegisterControl.enable.set(True)
        R0Delay_CRNT = self.RegisterControl.R0Delay.get()
        R0Width_CRNT = self.RegisterControl.R0Width.get()
        AcqDelay1_CRNT = self.RegisterControl.AcqDelay1.get()
        AcqWidth1_CRNT = self.RegisterControl.AcqWidth1.get()
        SR0Delay1_CRNT = self.RegisterControl.SR0Delay1.get()
        SR0Width1_CRNT = self.RegisterControl.SR0Width1.get()
        if debug:
            if FIRST_CALL:
                print('\tBEFORE')
            else:
                print('\tAFTER')
            #end-if-else
            print('\t\tR0Delay = {}'.format(R0Delay_CRNT))
            print('\t\tR0Width = {}'.format(R0Width_CRNT))
            print('\t\tAcqDelay1 = {}'.format(AcqDelay1_CRNT))
            print('\t\tAcqWidth1 = {}'.format(AcqWidth1_CRNT))
            print('\t\tSR0Delay1 = {}'.format(SR0Delay1_CRNT))
            print('\t\tSR0Width1 = {}'.format(SR0Width1_CRNT))
        #end-if

    #<<<<<<<<<<<<<<<<<<<<<<<< SET INTEGRATION: END  >>>>>>>>>>>>>>>>>>>>>>>>>>>#
    """
    >>>>>>>>>>>>>>>>>>>>>>>>>> SETTING CLOCK: START  <<<<<<<<<<<<<<<<<<<<<<<<<<<
    """
    def F_SET_PIPO_DELAYS(self, dev, cmd, arg):
        # INPUT(S):
        #   arg[0]      NOTHING RIGHT NOW
        #   arg[-1]     (OPT) 'debug' enables function debug option
        """
        LANE INPUTS
        """
        if 'debug' in arg:
            debug = True
            print('20220921_092021, Debugging: F_SET_PIPO_DELAYS')
        else:
            debug = False
        # end-if-else
        if debug:
            print('\tWARNING! FORCING PIPO-Delays to fix value')
            print('Updated: 20221108, make sure to run DAC ramp')
        # end-if

        # set pipo-delays
        self.Mv2Asic[2].enable.set(True)
        self.Mv2Asic[2].pipoclk_delay_row0.set(0x7)
        self.Mv2Asic[2].pipoclk_delay_row1.set(0x7)
        self.Mv2Asic[2].pipoclk_delay_row2.set(0x5)
        self.Mv2Asic[2].pipoclk_delay_row3.set(0x3)

        # print SETTING
        print('PIPO-row0 = {}'.format( self.Mv2Asic[2].pipoclk_delay_row0.get() ))
        print('PIPO-row1 = {}'.format( self.Mv2Asic[2].pipoclk_delay_row1.get() ))
        print('PIPO-row2 = {}'.format( self.Mv2Asic[2].pipoclk_delay_row2.get() ))
        print('PIPO-row3 = {}'.format( self.Mv2Asic[2].pipoclk_delay_row3.get() ))

    def F_SET_RUN_RATE(self, dev, cmd, arg):
        # INPUT(S):
        #   arg[0]      Run-Rate [Hz]
        #   arg[-1]     (OPT) 'debug' enables function debug option
        """
        LANE INPUTS
        """
        if 'debug' in arg:
            debug = True
            print('20220921_092021, Debugging: F_SET_RUN_RATE')
        else:
            debug = False

        """
        SET MAIN CLOCK
        """
        # READ CURRENT VALUES FIRST: Seems to have stopped error by reading what the values are first
        self.MMCMRegisters.enable.set(True)
        DUMP_VALUE = self.MMCMRegisters.CLKOUT0HighTime.get()
        DUMP_VALUE = self.MMCMRegisters.CLKOUT0LowTime.get()
        DUMP_VALUE = self.MMCMRegisters.CLKOUT0Frac.get()
        DUMP_VALUE = self.MMCMRegisters.CLKOUT0FracEn.get()
        # Setting duty cycle = 50%
        R0_Low_High = self.F_RunRate_Hz_to_CLKDIV(arg)
        self.MMCMRegisters.CLKOUT0HighTime.set(R0_Low_High)
        self.MMCMRegisters.CLKOUT0LowTime.set(R0_Low_High)
        self.MMCMRegisters.CLKOUT0Frac.set(0)
        self.MMCMRegisters.CLKOUT0FracEn.set(0)

        # WHAT IS THE ACTUAL FRAME RATE?
        if debug:
            RR_Hz_act = self.F_CLKDIV_to_RunRate_Hz([R0_Low_High,'debug'])
        else:
            RR_Hz_act = self.F_CLKDIV_to_RunRate_Hz([R0_Low_High])

        """
        RESULTS
        """
        print('\nSet: CLK-DIV = {}[-] \t\t--> Run-Rate = {}[Hz]\n'.format(R0_Low_High,round(RR_Hz_act,3)))

    def F_SET_FRAME_RATE(self, dev, cmd, arg):
        # INPUT(S):
        #   arg[0]      Frame-Rate [Hz]
        #   arg[-1]     (OPT) 'debug' enables function debug option
        """
        LANE INPUTS
        """
        FRAME_RATE = arg[0] # [Hz] Desired frame rate
        if 'debug' in arg:
            debug = True
            print('20220921_092021, Debugging: F_SET_FRAME_RATE')
        else:
            debug = False

        """
        WHAT CLOCK IS CURRENTLY SET AT
        """
        self.MMCMRegisters.enable.set(True)
        R0_High = self.MMCMRegisters.CLKOUT0HighTime.get()
        R0_Low =  self.MMCMRegisters.CLKOUT0HighTime.get()
        R0_Low_High = 0.5 * (R0_High + R0_Low)
        MAX_RUN_RATE = self.F_CLKDIV_to_RunRate_Hz([R0_Low_High]) # [Hz]
        MAX_FRAME_TO_RUN_RATE = 5000/5100 # [-] desired safety margin
        print('\t\tWARNING! <= {} MAX-FRAME-RATE IS MAX!'.format(round(MAX_FRAME_TO_RUN_RATE,2)))
        MAX_FRAME_RATE = np.ceil( MAX_FRAME_TO_RUN_RATE * MAX_RUN_RATE)
        FRAME_RATE = min([FRAME_RATE,MAX_FRAME_RATE])
        if debug:
            print('\t\tRun-Rate = {}[Hz] --> Max-Frame-Rate = {}[Hz]'.format(MAX_RUN_RATE,MAX_FRAME_RATE))

        """
        SET TRIGGER
        """
        # NOTE:
        # AutoTrigPeriod = 100,000 --> FrameRate = 1000[Hz]
        # AutoTrigPeriod = 50,000 --> FrameRate = 2000[Hz]
        # AutoTrigPeriod = 40,000 --> FrameRate = 2500[Hz]
        # SLOPE = -50 [Period_Number/Hz]
        # INTERCEPT = 150,000
        TRG_PRD = int(1e8/(FRAME_RATE)) # [10s-of-nsec]
        # READING SOMETHING first
        self.TriggerRegisters.enable.set(True)
        DUMP_VALUE = self.TriggerRegisters.AutoTrigPeriod.get()
        # NOW SETTING VALUES
        self.TriggerRegisters.AutoTrigPeriod.set(TRG_PRD)
        # startup TriggerRegisters
        self.root.runControl.runState.set(0x0) # STOPPED software triggers
        self.TriggerRegisters.AutoDaqEn.set(True)
        self.TriggerRegisters.AutoRunEn.set(True)
        self.TriggerRegisters.DaqTriggerEnable.set(True)
        self.TriggerRegisters.RunTriggerEnable.set(True)

        """
        RESULTS
        """
        # IF WE ARE RUNNING, THEN FRAMERATE WILL BE SHOWING UNDER AXISTREAMMON
        self.AxiStreamMon.enable.set(True)
        print('\n')
        for ch in range(4):
            self.AxiStreamMon.Ch[ch].enable.set(True)
            FRAME_RATE_READ = self.AxiStreamMon.Ch[ch].FrameRate.get()
            print('Ch[{}].FrameRate = {}'.format(ch,FRAME_RATE_READ))

        print('\n')

    #--------------------------------------------------------------------------#
    def F_RunRate_Hz_to_CLKDIV(self, arg):
        # THIS IS MAX ACHAVABLE RUN RATE... may not get this
        # INPUT: [FR_Hz,'debug'] where FR_Hz is disired frame-rate[Hz]
        # OUTPUT: R0 <-- INT CLK-DIVIDER TO GENERATE THIS FRAME-RATE
        FR_Hz = arg[0] # [Hz] desired frame rate
        if len(arg) > 1:
            if 'debug' in arg[-1]:
                debug = True
            #end-if
        else:
            debug = False
        #end-if-else
        """
        CONSTATNS
        """
        PIX_per_ADC = 2 * 48 # number of pixels per ADC [columns * rows]
        PIX_per_lane = 64 # how many pixel columns there are in a given ADC-lane or group
        MAIN_CLK = 2e9 # [Hz] main clock
        max_integration_time = 6e-6 # [sec]
        extra_margin = 4e-6 # [sec]

        """
        VARIABLES
        """
        read_out_time = (1/FR_Hz) - (max_integration_time + extra_margin) # [sec] what out read out time per lane (ADC-group)
        ADC_smpl_prd = read_out_time / PIX_per_ADC # [sec] how much time it take to read a single ADC pixels
        ADC_CLK = PIX_per_lane/ADC_smpl_prd # [Hz] clock frequency required to read a single ADC pixels
        Serdes_CLK = ADC_CLK * 5 # [Hz] clock frequency required to have this frame rate
        R0 = int( np.ceil(MAIN_CLK / (2*Serdes_CLK)) ) # [-] no units, a divider
        """
        OUTPUT & RETURN
        """
        if debug:
            print('\tF_FrameRate_Hz_to_CLKDIV')
            print('\t\tDesired  Frame-Rate = {}[Hz]'.format(FR_Hz))
            print('\t\tSets CLK-Divider R0_High = R0_Low = {}[-]'.format(R0))
        #end-if
        return R0

    #--------------------------------------------------------------------------#
    def F_CLKDIV_to_RunRate_Hz(self, arg):
        # THIS IS MAX ACHAVABLE RUN RATE... may not get this
        # INPUT: [R0,'debug'] where CLK-DIVIDER is disired
        # OUTPUT: FR_Hz <--  TO GENERATE THIS FRAME-RATE
        R0 = arg[0] # [-] Desired clock divider
        if len(arg) > 1:
            if 'debug' in arg[-1]:
                debug = True
            #end-if
        else:
            debug = False
        #end-if-else
        """
        CONSTATNS
        """
        PIX_per_ADC = 2 * 48 # number of pixels per ADC [columns * rows]
        PIX_per_lane = 64 # how many pixel columns there are in a given ADC-lane or group
        MAIN_CLK = 2e9 # [Hz] main clock
        max_integration_time = 6e-6 # [sec]
        extra_margin = 4e-6 # [sec]

        """
        VARIABLES
        """
        Serdes_CLK = MAIN_CLK / (2*R0) # Assuming R0_High = R0_Low = R0 to be output
        ADC_CLK = Serdes_CLK / 5 # [Hz] not sure why divided by 5, ADC clock is
        ADC_smpl_prd = 1/(ADC_CLK/PIX_per_lane) # [sec] HOW LONG IT TAKE ADC TO SAMPLE A SINGLE LANE
        read_out_time = PIX_per_ADC * ADC_smpl_prd # [sec] what out read out time per lane (ADC-group)

        ### FRAME RATE ###
        FR_Hz = 1/(read_out_time + max_integration_time + extra_margin) #[Hz]
        if debug:
            print('\tF_CLKDIV_to_FrameRate_Hz')
            print('\t\tR0_High = R0_Low = {}[-]'.format(R0))
            print('\t\tSets FR = {}[Hz]'.format(FR_Hz))
        #end-if
        return FR_Hz

    #<<<<<<<<<<<<<<<<<<<<<<<<<<< SETTING CLOCK: END  >>>>>>>>>>>>>>>>>>>>>>>>>>#

    def test_lane_delay(self,lane,delay,time_per_sweep, idle_lock_array):
        total_errors = 0
        test_delay = np.clip(idle_lock_array[lane] + int(delay),0,511)
        self.SspMonGrp[2].UsrDlyCfg[lane].set(int(test_delay))
        self.SspMonGrp[2].CntRst.set(1)

        time.sleep(time_per_sweep)
        total_errors = self.SspMonGrp[2].ErrorDetCnt[lane].get()
        return (total_errors, test_delay)

    def fnSweepDelaysPrintEyes(self, dev, cmd, arg):
        if 'debug' in arg:
            debug = True
            print('Debugging in function {}'.format(cmd))

        else:
            debug = False

        if arg[0] < 256:
            print('Sweep Count must be greater than 256')
            return 1

        arguments = np.asarray(arg)
        sweep_max = 511
        sweep_cnt = arg[0]
        time_per_sweep = float(arg[1])/100.0

        all_errors = np.zeros((24, sweep_cnt)) # incase need to subtract

        self.SspMonGrp[2].enable.set(1)
        self.MMCMRegisters.enable.set(1)

        self.stop_capture()
        idle_lock_array = np.empty(24)
        for i in range(24):
            idle_lock_array[i] = self.SspMonGrp[2].DlyConfig[i].get()

        self.SspMonGrp[2].EnUsrDlyCfg.set(0x1)


        delay_space = (np.linspace(0,sweep_max,sweep_cnt))
        #random_space = random.sample(delay_space)

        idle_results = np.zeros((24,sweep_cnt))
        for idx, delay in enumerate(delay_space):
            if debug:
                print('Idle State')
            print(f'delay {idx}/{sweep_cnt}')
            for lane in range(24):
                self.SspMonGrp[2].UsrDlyCfg[lane].set(int(delay))

            self.SspMonGrp[2].CntRst.set(1)
            self.start_capture()
            self.stop_capture()
            time.sleep(time_per_sweep)
            self.SspMonGrp[2].CntRst.set(1)
            time.sleep(time_per_sweep)
            self.stop_capture()

            for lane in range(24):
                idle_results[lane][idx] = self.SspMonGrp[2].ErrorDetCnt[lane].get()

        self.SspMonGrp[2].EnUsrDlyCfg.set(0x0)
        time.sleep(1)
        self.SspMonGrp[2].EnUsrDlyCfg.set(0x1)

        run_results = np.zeros((24,sweep_cnt))
        for idx, delay in enumerate(delay_space):
            if debug:
                print('Running State')
            print(f'delay {idx}/{sweep_cnt}')
            for lane in range(24):
                self.SspMonGrp[2].UsrDlyCfg[lane].set(int(delay))

            self.SspMonGrp[2].CntRst.set(1)
            self.start_capture()
            time.sleep(time_per_sweep)
            self.stop_capture()

            for lane in range(24):
                run_results[lane][idx] = self.SspMonGrp[2].ErrorDetCnt[lane].get()

        self.stop_capture()

        if debug:
            print('Save to file')
            np.savetxt('idle_results.csv', idle_results, delimiter=',')
            np.savetxt('run_results.csv', run_results, delimiter=',')
            np.savetxt('delay_space.csv', delay_space, delimiter=',')
            np.savetxt('idle_lock_array.csv', idle_lock_array, delimiter=',')
            np.savetxt('all_errors.csv', run_results + idle_results, delimiter=',')

        all_errors = run_results + idle_results

        lane_adj_eyes = self.F_FIND_EYES(delay_space, all_errors, debug)
        self.F_SET_DELAYS(lane_adj_eyes)

        self.SspMonGrp[2].EnUsrDlyCfg.set(0x1)

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


    def F_SET_DELAYS(self, lane_adj_eyes):
        num_of_lanes,num_of_eye_info = lane_adj_eyes.shape # returning lane, delay center, width of each eye
        # Disable & wait & Enabling user to change delay
        self.SspMonGrp[2].EnUsrDlyCfg.set(0x1)
        # set delay
        for lane in range(num_of_lanes):
            crnt_dly = int(lane_adj_eyes[lane][1])
            self.SspMonGrp[2].UsrDlyCfg[lane].set(crnt_dly)
        #end-for
        # reset all error counters
        self.SspMonGrp[2].CntRst.set(1) # resets counters
        time.sleep(1)
        #end def

    # Can this be deleted?
    def fnFindMinimumErrorDelays(self, dev, cmd, arg):
        arguments = np.asarray(arg)

        sweep_cnt = arg[0]
        time_per_sweep = float(arg[1])/100.0

        single_lane = arg[2]
        #"""set MMCM clock rate, wait for lock, set usr delay, set to run"""
        self.SspMonGrp[2].enable.set(1)

        self.stop_capture()

        idle_lock_array = np.empty(24)
        for i in range(24):
            print(f'{i} = {self.SspMonGrp[2].DlyConfig[i].get()}')
            idle_lock_array[i] = self.SspMonGrp[2].DlyConfig[i].get()

        self.SspMonGrp[2].EnUsrDlyCfg.set(0x1)
        self.start_capture()

        #pprint.pprint(self.SspMonGrp[2].__dict__)

        print("error rate test")
        numb_of_test_delays = sweep_cnt
        delay_space = np.linspace(-(sweep_val/2),(sweep_val/2),numb_of_test_delays)

        if single_lane > 23:
            for lane in range(24):
                print(f'lane{lane} :', end = '')

                delay_err_dict = {}
                for delay in delay_space:
                    (total_errors, test_delay) = self.test_lane_delay(lane,delay,time_per_sweep,idle_lock_array)
                    delay_err_dict[test_delay] = total_errors
                    #print(f' {int(delay)}:{accum} ', end = '')

                print(delay_err_dict)
                no_error_vals = [k for k,v in delay_err_dict.items() if int(v) == 0]
                print(f'mean 0 val = {np.mean(no_error_vals)}')
                self.SspMonGrp[2].UsrDlyCfg[lane].set(int(np.mean(no_error_vals)))
        else :
            delay_err_dict = {}
            for delay in delay_space:
                (total_errors, test_delay) = self.test_lane_delay(single_lane,delay,time_per_sweep,idle_lock_array)
                delay_err_dict[test_delay] = total_errors
                delay_err_dict[test_delay] = total_errors
            print(delay_err_dict)
            no_error_vals = [k for k,v in delay_err_dict.items() if int(v) == 0]
            print(f'mean 0 val = {np.mean(no_error_vals)}')
            self.SspMonGrp[2].UsrDlyCfg[single_lane].set(int(np.mean(no_error_vals)))

        self.SspMonGrp[2].CntRst.set(1)

        #self.SspMonGrp[2].EnUsrDlyCfg.set(0x0)

        self.stop_capture()

    # Can this be deleted?
    def fnSetUsrDelays(self, dev,cmd,arg):
        """set user delay command function """
        print("hey you click the set user delay button stil")
        enable = self.find(name="EnUsrDlyCfg")
        dlyconfig_reg = self.find(name="DlyConfig")
        usrconfig_reg = self.find(name="UsrDlyCfg")
        arguments = np.asarray(arg)
        for i in range(24):
            usrconfig_reg[i].set(dlyconfig_reg[i].get()+int(arguments[i%4]))

        self.SspMonGrp[2].EnUsrDlyCfg.set(0x1)
        


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



