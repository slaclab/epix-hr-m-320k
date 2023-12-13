//////////////////////////////////////////////////////////////////////////////
// This file is part of 'Vivado HLS Example'.
// It is subject to the license terms in the LICENSE.txt file found in the
// top-level directory of this distribution and at:
//    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
// No part of 'Vivado HLS Example', including this file,
// may be copied, modified, propagated, or distributed except according to
// the terms contained in the LICENSE.txt file.
//////////////////////////////////////////////////////////////////////////////

#ifndef _AXI_STREAM_EPIXHRMV2_DESCRAMPLE_H_
#define _AXI_STREAM_EPIXHRMV2_DESCRAMPLE_H_

#include <stdio.h>

#include "ap_axi_sdata.h"
#include "hls_stream.h"

#define BYTES_PER_PIXEL 2
#define ROW_PER_FRAME 192
#define COLS_PER_FRAME 384
#define ROWS_PER_BANK 48
#define COLS_PER_BANK 64
#define NUM_BANKS 24
#define NUM__DATA_CYCLES 3072
#define IO_STREAM_WIDTH NUM_BANKS * BYTES_PER_PIXEL
#define ASIC_DATA_WIDTH BYTES_PER_PIXEL * 8

// hls::axis<ap_int<WData>, WUser, WId, WDest>
typedef ap_axis<IO_STREAM_WIDTH,2,1,1> data_t;

typedef hls::stream<data_t> mystream;

extern void AxiStreamePixHrMv2Descramble(mystream &ibStream, mystream &obStream);

#endif
