

import pyrogue as pr
import axipcie            as pcie
import surf.protocols.pgp as pgp
import rogue


class pciePgp(pr.Device):
    def __init__( self,dev,numDmaLanes,**kwargs):
        super().__init__(**kwargs)

        # Create PCIE memory mapped interface
        self.memMap = rogue.hardware.axi.AxiMemMap(dev)

        # Add the PCIe core device to base
        self.add(pcie.AxiPcieCore(
            offset     = 0x00000000,
            memBase     = self.memMap,
            numDmaLanes = numDmaLanes,
            boardType   = None,
            expand      = False,
        ))

        # Add PGP Core
        for lane in range(numDmaLanes):
                self.add(pgp.Pgp4AxiL(
                    name    = f'Lane[{lane}]',
                    offset  = (0x00800000 + lane*0x00010000),
                    memBase = self.memMap,
                    numVc   = 1,
                    writeEn = True,
                    expand  = False
                )) 