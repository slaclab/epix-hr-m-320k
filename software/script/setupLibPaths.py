import pyrogue as pr
import os

top_level = os.path.realpath(__file__).split('software')[0]

pr.addLibraryPath(top_level+'firmware/submodules/epix-hr-core/python')
pr.addLibraryPath(top_level+'firmware/submodules/lcls-timing-core/python')
pr.addLibraryPath(top_level+'firmware/submodules/l2si-core/python')
pr.addLibraryPath(top_level+'firmware/submodules/surf/python')
pr.addLibraryPath(top_level+'firmware/python')