#-----------------------------------------------------------------------------
# This file is part of the 'epix-320k-m'. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the 'Development Board Examples', including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------

import rogue.interfaces.stream
import numpy as np

#############################################
# Descramble class
#############################################
class dataDebug(rogue.interfaces.stream.Slave):

    def __init__(self, name, size=1000):
        rogue.interfaces.stream.Slave.__init__(self)

        self.channelData = [[] for _ in range(8)]
        self.name = name
        self.enable = False
        self.enableDP = False
        self.dataAcc = np.zeros((192,384,size), dtype='int32')
        self.autoFillMask = np.zeros((size), dtype='int32')
        self.fixedMask    = np.zeros((size), dtype='int32')
        self.allMasks     = np.zeros((size), dtype='int32')
        self.ASIC         = np.zeros((size), dtype='int32')
        self.frameNo      = np.zeros((size), dtype='int32')        
        self.currentFrameCount = 0
        self.size = size
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

        # Work around ASIC/firmware bug: all rows shifted by 1
        # Create lookup table where each row points to the next
        hardwareBugWorkAroundRowLUT = np.zeros((self.framePixelRow))
        for index in range (self.framePixelRow) :
            hardwareBugWorkAroundRowLUT[index] = index + 1
        # handle bank/lane roll over cases
        hardwareBugWorkAroundRowLUT[47] = 0 
        hardwareBugWorkAroundRowLUT[95] = 48
        hardwareBugWorkAroundRowLUT[143] = 96 
        hardwareBugWorkAroundRowLUT[191] = 144

        # reverse pixel original index to new row and column to generate lookup tables
        for row in range (self.framePixelRow) :
            for col in range (self.framePixelColumn):  
                index = descarambledImg[row,col]
                self.lookupTableRow[index] = hardwareBugWorkAroundRowLUT[row]
                self.lookupTableCol[index] = col

        # reshape column and row lookup table
        self.lookupTableCol = np.reshape(self.lookupTableCol, (self.framePixelRow, self.framePixelColumn))
        self.lookupTableRow = np.reshape(self.lookupTableRow, (self.framePixelRow, self.framePixelColumn))


    def descramble(self, frame):
        metaData = {}
        #channel = frame.getChannel() # timing is channel 0. Data is channel 2
        rawData = frame.getNumpy(0, frame.getPayload()).view(np.uint16)
        current_frame_temp = np.zeros((self.framePixelRow, self.framePixelColumn), dtype=int)
        """performs the EpixMv2 image descrambling (simply applying lookup table) """
        if (len(rawData)==73776):
            imgDesc = np.frombuffer(rawData[24:73752],dtype='uint16').reshape(192, 384)
            metaData['autoFillMask'] = rawData[73753] << 16 | rawData[73752] 
            metaData['fixedMask']    = rawData[73755] << 16 | rawData[73754] 
            metaData['allMasks'] = metaData['autoFillMask'] | metaData['fixedMask']
            metaData['ASIC'] = rawData[4] & 0x7
            metaData['frameNo'] = rawData[3]<< 16 | rawData[2]
            #print("{}: descramble Ok channel {}".format(self.name, channel))
            #print('rawData length {}'.format(len(rawData)))
        else:
            print("{}: descramble error channel {}".format(self.name, channel))
            print('rawData length {}'.format(len(rawData)))
            imgDesc = np.zeros((192,384), dtype='uint16')

        # apply lookup table
        current_frame_temp[self.lookupTableRow, self.lookupTableCol] = imgDesc
        # returns final image
        #return np.bitwise_and(current_frame_temp, self.PixelBitMask.get())
        return (metaData, current_frame_temp)
        
    def _acceptFrame(self, frame):

        if (self.enable == False) :
            return
        
        #channel = frame.getChannel()
        frameSize = frame.getPayload()
        ba = bytearray(frameSize)
        frame.read(ba, 0)
        if (self.currentFrameCount >= self.size) :
            print("Max acquistion size of dataDebug of {} reached. Cleanup dataDebug. Discarding new data.".format(self.size))
        else :
            metaData , self.dataAcc[:,:,self.currentFrameCount] = self.descramble(frame)
            if metaData:
                self.autoFillMask[self.currentFrameCount] = metaData['autoFillMask']
                self.fixedMask[self.currentFrameCount] = metaData['fixedMask']
                self.allMasks[self.currentFrameCount] = metaData['allMasks']
                self.ASIC[self.currentFrameCount] = metaData['ASIC']
                self.frameNo[self.currentFrameCount] = metaData['frameNo']

                self.currentFrameCount = self.currentFrameCount + 1 
   
        if (self.enableDP) :
            print("Extracted and descrambled {} frames".format(self.currentFrameCount), end='\r')

    def cleanData(self):
        self.dataAcc = np.zeros((192,384,self.size), dtype='int32')
        self.autoFillMask = np.zeros((self.size), dtype='int32')
        self.fixedMask    = np.zeros((self.size), dtype='int32')
        self.allMasks     = np.zeros((self.size), dtype='int32')
        self.ASIC         = np.zeros((self.size), dtype='int32')
        self.frameNo      = np.zeros((self.size), dtype='int32')
        self.currentFrameCount = 0

    def getData(self):
        return self.dataAcc[:,:,0:self.currentFrameCount]    

    def getMetaData(self):
        return self.ASIC[0:self.currentFrameCount], self.frameNo[0:self.currentFrameCount], self.fixedMask[0:self.currentFrameCount], self.autoFillMask[0:self.currentFrameCount], self.allMasks[0:self.currentFrameCount]
    
    def enableDataDebug(self, enable):
        self.enable = enable 

    def enableDebugPrint(self, enable):
        self.enableDP = enable 