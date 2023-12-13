//////////////////////////////////////////////////////////////////////////////
// This file is part of 'Vivado HLS Example'.
// It is subject to the license terms in the LICENSE.txt file found in the
// top-level directory of this distribution and at:
//    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
// No part of 'Vivado HLS Example', including this file,
// may be copied, modified, propagated, or distributed except according to
// the terms contained in the LICENSE.txt file.
//////////////////////////////////////////////////////////////////////////////

#include "AxiStreamePixHrMv2Descramble.h"

#include <iostream>
using namespace std;

void AxiStreamePixHrMv2Descramble(mystream &ibStream, mystream &obStream) {
	// Set the input and output ports as AXI4-Stream
	#pragma HLS INTERFACE axis port=ibStream
	#pragma HLS INTERFACE axis port=obStream

	// Don't generate ap_ctrl ports in RTL
	#pragma HLS INTERFACE ap_ctrl_none port=return



   	// Exemple for 2 ePixHR10k ASICs => 2 * 32 * 6 = 384
	static ap_uint<ASIC_DATA_WIDTH> imageFlattened(NUM_BANKS * ROWS_PER_BANK * COLS_PER_BANK);
	#pragma HLS ARRAY_PARTITION variable=image dim=1 complete	


   /* Reorder banks from
	# 18    19    20    21    22    23
	# 12    13    14    15    16    17
	#  6     7     8     9    10    11
	#  0     1     2     3     4     5
	#
	#                To
	#  3     7    11    15    19    23
	#  2     6    10    14    18    22
	#  1     5     9    13    17    21
	#  0     4     8    12    16    20
	*/
   	ap_uint bankRemapping[24] = {0, 6, 12, 18, 1, 7, 13, 19, 2, 8, 14, 20, 3, 9, 15, 21, 4, 10, 16, 22, 5, 11, 17, 23};
    int colOffset[24] = {0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5 };
    int rowOffset[24] = {0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4, 5 };

    if(ibStream.empty())
		return;

   	auto ibVar = ibStream.read();

   /*
   #pragma HLS DATAFLOW
   rows_loop:
   for(rowIdx=0; rowIdx<MAX_NUM_ROWS;rowIdx++){

	   read_frame(ibStream, input_line_buffer, lastDataFlag);

	   //#pragma HLS DATAFLOW
	   process_line(input_line_buffer, previous_line_buffer, output_line_buffer);

       //#pragma HLS DATAFLOW
	   last = send_frame(output_line_buffer, lastDataFlag, obStream);

	   //exit logic, frame ends with the last flag but now the algorithm
	   //has an upper boundary
	   if (last==1){
		   rowIdx=MAX_NUM_ROWS;
	   }
   }*/
   	while(!ibStream.empty())
		obStream.write(ibStream.read());
}

void read_frame(mystream &ibStream, ap_uint<ASIC_DATA_WIDTH> linebuf[NUM_ASICS * ASIC_COLUMNS_PER_STREAM * ASIC_NUM_OF_STREAMS], ap_uint<32> &lastDataFlag){
	ap_uint<8> idx = 0, idx2 = 0;
	int high_range, low_range;
	data_t ibVar;
	ap_uint<IO_STREAM_WIDTH> temp_data;
	ap_uint<ASIC_DATA_WIDTH> temp_pix;

   input_to_buf_loop:
   	   for (idx = 0; idx < ASIC_COLUMNS_PER_STREAM; ++idx){
           auto ibVar = ibStream.read();
           temp_data = ibVar.data;
           cout << "hw lane ibVar.data=" << ibVar.data << " hw lane ibVar.strb=" << ibVar.strb << " hw lane ibVar.keep=" << ibVar.keep << ", linebuf " << linebuf[idx] <<", last " << lastDataFlag[idx] << ", " << endl;
	       //loops over the single input data and buffer it on a line buffer
	       for (idx2 = 0; idx2 < ASIC_NUM_OF_STREAMS*NUM_ASICS; ++idx2){
	    	   high_range = ((ASIC_DATA_WIDTH)*(idx2+1)-1);
		       low_range = (ASIC_DATA_WIDTH*idx2);
	    	   temp_pix = temp_data.range(high_range,low_range);
	    	   cout << "tmp data " << temp_pix << ", ";
	    	   //effectively de scramble the data
		       linebuf[idx+(idx2*ASIC_COLUMNS_PER_STREAM)] = temp_pix;
	       }
	       cout << endl;
	       cout << "idx " << idx << "linebuff values " << linebuf[idx] << ", " << linebuf[32+idx] << ", " << linebuf[64+idx] << ", " << endl;
   	       lastDataFlag[idx]=ibVar.last;

   	   }
}

void process_line(ap_uint<ASIC_DATA_WIDTH> input_line_buffer[NUM_ASICS * ASIC_COLUMNS_PER_STREAM * ASIC_NUM_OF_STREAMS], ap_uint<ASIC_DATA_WIDTH> previous_line_buffer[NUM_ASICS * ASIC_COLUMNS_PER_STREAM * ASIC_NUM_OF_STREAMS], ap_uint<ASIC_DATA_WIDTH> output_line_buffer[NUM_ASICS * ASIC_COLUMNS_PER_STREAM * ASIC_NUM_OF_STREAMS]){
	ap_uint<8> idx = 0, idx2 = 0;
	ap_uint<ASIC_DATA_WIDTH> temp_pix;

	buf_in_to_buf_out_loop:
	   	  for (idx = 0; idx < ASIC_COLUMNS_PER_STREAM  ; ++idx){
	   		for (idx2 = 0; idx2 < ASIC_NUM_OF_STREAMS*NUM_ASICS; ++idx2){
			  #pragma HLS UNROLL factor=ASIC_NUM_OF_STREAMS*NUM_ASICS
	   		  //just copy
	   		  if (idx < ROW_SHIFT_START_COLUMN){
	   			output_line_buffer[(idx+(idx2*ASIC_COLUMNS_PER_STREAM))] =  input_line_buffer[(idx+(idx2*ASIC_COLUMNS_PER_STREAM))];
	   		  }else{ //row shift
	   			output_line_buffer[(idx+(idx2*ASIC_COLUMNS_PER_STREAM))] = previous_line_buffer[(idx+(idx2*ASIC_COLUMNS_PER_STREAM))];
	   			previous_line_buffer[(idx+(idx2*ASIC_COLUMNS_PER_STREAM))] = input_line_buffer[(idx+(idx2*ASIC_COLUMNS_PER_STREAM))];
	   		  }
	   		}
	   	  }
}

ap_uint<1> send_frame(ap_uint<ASIC_DATA_WIDTH> output_line_buffer[NUM_ASICS * ASIC_COLUMNS_PER_STREAM * ASIC_NUM_OF_STREAMS], ap_uint<32> &lastDataFlag, mystream &obStream){
   ap_uint<8> idx = 0, idx2 = 0;
   data_t obVar;
   ap_uint<IO_STREAM_WIDTH> temp_data;

   output_to_buf_loop:
   	  for (idx = 0; idx < ASIC_COLUMNS_PER_STREAM  ; ++idx){
	      for (idx2 = 0; idx2 < ASIC_NUM_OF_STREAMS*NUM_ASICS; ++idx2){
	    	  temp_data.range(((ASIC_DATA_WIDTH)*(idx2+1)-1),ASIC_DATA_WIDTH*idx2) = output_line_buffer[((idx*ASIC_NUM_OF_STREAMS*NUM_ASICS)+idx2)];
	       }
           obVar.data = temp_data;
           //create error flag check and set
           //last should coincide with idx = 31
           obVar.last = lastDataFlag[idx];//flag is kept in order since only data should be mirrored
           obVar.strb = 0xFFFFFF;//ibVar.strb; //for 192 bits bus this value should always be xFFFFFF
           obVar.keep = 0xFFFFFF;//ibVar.keep;

           cout << "idx="        << idx        << ", ";
           cout << "linebuffer=" << output_line_buffer[idx] << ", ";
           cout << "obVar.data=" << obVar.data << " hw lane obVar.strb=" << obVar.strb << " hw lane obVar.keep=" << obVar.keep <<endl;

           obStream.write(obVar);
      }
   	  return obVar.last;
}
