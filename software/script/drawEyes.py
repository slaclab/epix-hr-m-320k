import numpy as np
import matplotlib.pyplot as plt
import sys

asicLaneLayout         =[ 0, 4,  8, 12, 16, 20, 
                          1, 5,  9, 13, 17, 21,
                          2, 6, 10, 14, 18, 22,
                          3, 7, 11, 15, 19, 23]

asicLane2ViewerMapping = [None] * 24

for x,y in enumerate(asicLaneLayout) : 
    asicLane2ViewerMapping[y] = x

if len(sys.argv) != 2:
    sys.exit(0)

all_errors=np.loadtxt("all_errors{}.csv".format(sys.argv[1]), delimiter=',')

shape=np.shape(all_errors)

x = [ i for i in range(shape[1]) ]

for i in range(24) :
    plt.subplot(4,6,asicLane2ViewerMapping[i]+1)
    plt.xlabel("eye lane {}".format(i))
    plt.plot(x,all_errors[i])

plt.subplots_adjust(left=0.1,
                    bottom=0.1,
                    right=0.9,
                    top=0.9,
                    wspace=0.4,
                    hspace=0.4)

plt.show()