# -----------------------------------------------------------------------------
# This file is part of the 'Simple-PGPv4-KCU105-Example'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'Simple-PGPv4-KCU105-Example', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
# -----------------------------------------------------------------------------

import pyrogue as pr

import surf.axi              as axi
import surf.devices.amphenol as amphenol
import surf.devices.micron   as micron
import surf.devices.silabs   as silabs
import surf.devices.ti       as ti
import surf.protocols.pgp    as pgp
import surf.xilinx           as xil


class Core(pr.Device):
    def __init__(self,
                 sim      = False,
                 promProg = False,
                 **kwargs):
        super().__init__(**kwargs)

        self.add(axi.AxiVersion(
            offset = 0x0000_0000,
            expand = True,
        ))
        
        self.add(xil.AxiSysMonUltraScale(
            offset  = 0x0001_0000,
            enabled = not sim and not promProg,
        ))

        self.add(micron.AxiMicronN25Q(
            offset  = 0x0002_0000,
            hidden  = True,
            enabled = not sim,
        ))

        self.add(amphenol.LeapXcvr(
            offset  = 0x0003_0000,
            writeEn = False,
            enabled = not sim and not promProg,
        ))

        self.add(silabs.Si5345(
            offset  = 0x0004_0000,
            enabled = not sim and not promProg,
        ))

        self.add(ti.Lmk61e2(
            offset  = 0x0005_0000,
            enabled = not sim and not promProg,
        ))

        numVc = [1,1,1,1,1,3,4,4]
'''
        for lane in range(8):
            self.add(pgp.Pgp4AxiL(
                name    = f'PgpMon[{lane}]',
                offset  = 0x0100_0000 + 0x0001_0000*lane,
                numVc   = numVc[lane],
                writeEn = False,
                enabled = not sim and not promProg,
            ))
    '''