
try :
    from ePixViewer.asics import ePixHrMv2
except ImportError:
    pass


class fullRateDataReceiver(ePixHrMv2.DataReceiverEpixHrMv2):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.dataAcc = np.zeros((192,384,1000), dtype='int32')
        self.currentFrameCount = 0

    def process(self,frame):
        if (self.currentFrameCount >= 1000) :
            print("Max acquistion size of fullRateDataReceiver of 1000 reached. Cleanup dataDebug. Discarding new data.")
        else :
            super().process(frame)
            self.dataAcc[:,:,self.currentFrameCount] = np.intc(self.Data.get())
            self.currentFrameCount = self.currentFrameCount + 1

    def cleanData(self):
        self.dataAcc = np.zeros((192,384,1000), dtype='int32')
        self.currentFrameCount = 0

    def getData(self):
        return self.dataAcc[:,:,0:self.currentFrameCount]     
