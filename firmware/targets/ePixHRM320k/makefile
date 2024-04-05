
# Define target output
target: prom

# Define Firmware Version: v1.0.0.0
export PRJ_VERSION = 0x01010700

# Define target part
export PRJ_PART = XCKU15P-FFVA1156-2-E

# Define the TOP_DIR path
export TOP_DIR = $(abspath $(PWD)/../..)

# Using XVC Debug bridge
export USE_XVC_DEBUG = 1 

# Setup for releases.yaml
export RELEASE = ePixHRM320k

# -----------------------------------
# things needed for epix-hr-core
# export COMM_TYPE = pgp4
# export INCLUDE_PGP4_10G = 1 
# COMMON_NAME is defined by application
export COMMON_NAME = ePixHRM320k

# Define if this is FSBL PROM address
# export PROM_FSBL = 1

# Define if you want to build the DDR MIG core
# export BUILD_MIG_CORE = 0

# Define if you want to build the user Microblaze core
# export BUILD_MB_CORE = 0

# -----------------------------------

# Use top level makefile
include ../../submodules/ruckus/system_vivado.mk
