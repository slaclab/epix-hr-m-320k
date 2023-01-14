import pyrogue as pr

class PowerControl(pr.Device):
    def __init__(self, **kwargs):
        super().__init__(description='ePix M Waveform Generation', **kwargs)
        
    