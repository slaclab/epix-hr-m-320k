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

import ePix320kM as fpgaBoard

rogue.Version.minVersion('5.14.0')


class Root(pr.Root):
    def __init__(self,
                 dev      = '/dev/datadev_0',
                 pollEn   = True,   # Enable automatic polling registers
                 initRead = True,   # Read all registers at start of the system
                 promProg = False,  # Flag to disable all devices not related to PROM programming
                 **kwargs):
        numOfAsics = 4
        #################################################################

        self.promProg = promProg
        self.sim      = (dev == 'sim')

        if (self.sim):
            # Set the timeout
            # firmware simulation slow and timeout base on real time (not simulation time)
            kwargs['timeout'] = 100000000

        else:
            # Set the timeout
            # 5.0 seconds default
            kwargs['timeout'] = 5000000

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
            # for lane in range(numOfAsics):
            #     self.dataStream[lane] = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * lane + 0, 1)
            
            # self.srpStream = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 5 + 0, 1)
            
            # self.ssiCmdStream = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 5 + 1, 1)

            # self.xvcStream = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 5 + 2, 1)
            # for vc in range(4):
            #     self.adcMonStream[vc] = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 6 + vc, 1)
            #     self.oscopeStream[vc] = rogue.hardware.axi.AxiStreamDma(dev, 0x100 * 7 + vc, 1)

            # # Create (Xilinx Virtual Cable) XVC on localhost
            # self.xvc = rogue.protocols.xilinx.Xvc(2542)
            # self.addProtocol(self.xvc)

            # # Connect xvcStream to XVC module
            # self.xvcStream == self.xvc

            # # Create SRPv3
            # self.srp = rogue.protocols.srp.SrpV3()

            # # Connect SRPv3 to srpStream
            # self.srp == self.srpStream

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
        self.add(fpgaBoard.Core(
            offset   = 0x0000_0000,
            memBase  = self.srp,
            sim      = self.sim,
            promProg = self.promProg,
            expand   = False,
        ))

        # self.add(fpgaBoard.App(
        #     offset   = 0x8000_0000,
        #     memBase  = self.srp,
        #     sim      = self.sim,
        #     enabled  = not self.promProg,
        #     expand   = True,
        # ))

        #################################################################

    def start(self, **kwargs):
        super().start(**kwargs)
        # Check if not simulation and not PROM programming
        if not self.sim and not self.promProg:
            self.CountReset()
