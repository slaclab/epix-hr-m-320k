#-----------------------------------------------------------------------------
# This file is part of the 'ePix-320k-M'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'Simple-PGPv4-KCU105-Example', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import pyrogue        as pr
import LclsTimingCore as timing
import l2si_core      as l2si

class TimingRx(pr.Device):
    def __init__( self,sim=False,**kwargs):
        super().__init__(**kwargs)

        name = ['UseMiniTpg','TxDbgRst','TxDbgPhyRst','TxDbgPhyPllRst']
        for i in range(4):
            self.add(pr.RemoteVariable(
                name         = name[i],
                offset       = 0x0001_0100,
                bitSize      = 1,
                bitOffset    = i,
                mode         = 'RW',
            ))

        self.add(timing.GthRxAlignCheck(
            offset  = 0x0000_0000,
            expand  = False,
            hidden  = False,
            enabled = not sim,
        ))

        # TimingCore
        self.add(timing.TimingFrameRx(
            offset = 0x0008_0000,
            expand = False,
        ))

        # XPM Mini Core
        self.add(l2si.XpmMiniWrapper(
            offset = 0x0003_0000,
            expand = True,
        ))

        self.add(l2si.TriggerEventManager(
            offset       = 0x0004_0000,
            numDetectors = 1,
            enLclsI      = False,
            enLclsII     = True,
            expand       = True,
        ))

        @self.command(description="Configure for LCLS-II Timing (186 MHz based)")
        def ConfigLclsTimingV2():
            print ( 'ConfigLclsTimingV2()' )
            self.UseMiniTpg.set(0x0)
            self.TxDbgPhyRst.set(0x1)
            self.TxDbgPhyRst.set(0x0)
            self.TimingFrameRx.ModeSelEn.setDisp('UseClkSel')
            self.TimingFrameRx.RxPllReset.set(1)
            time.sleep(1.0)
            self.TimingFrameRx.RxPllReset.set(0)
            self.TimingFrameRx.ClkSel.set(0x1)
            self.TimingFrameRx.C_RxReset()
            time.sleep(1.0)
            self.TimingFrameRx.RxDown.set(0) # Reset the latching register

        @self.command()
        def ConfigureXpmMini():
            print ( 'ConfigureXpmMini()' )
            self.ConfigLclsTimingV2()
            self.UseMiniTpg.set(0x1)
            self.XpmMiniWrapper.XpmMini.HwEnable.set(True)
            self.XpmMiniWrapper.XpmMini.Link.set(0)
            self.XpmMiniWrapper.XpmMini.Config_L0Select_RateSel.set(5)
            self.XpmMiniWrapper.XpmMini.Config_L0Select_Enabled.set(False)
