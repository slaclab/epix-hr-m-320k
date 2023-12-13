#include <stdio.h>

#define BYTES_PER_PIXEL 2
#define ROW_PER_FRAME 192
#define COLS_PER_FRAME 384
#define ROWS_PER_BANK 48
#define COLS_PER_BANK 64
#define NUM_BANKS 24
#define BANKS_PER_ROW 6
#define NUM__DATA_CYCLES 3072
#define IO_STREAM_WIDTH_BYTES NUM_BANKS * BYTES_PER_PIXEL
#define IO_STREAM_WIDTH_BITS IO_STREAM_WIDTH_BYTES * 8
#define ASIC_DATA_WIDTH_BITS BYTES_PER_PIXEL * 8


int main()
{
    unit16_t inputImageAxiStreamBunches[3073][NUM_BANKS]; /* first cycle header and rest is body */
    unit16_t outputImageAxiStreamBunches[3073][NUM_BANKS]; /* first cycle header and rest is body */
    unit16_t descrambledImage[NUM_BANKS][ROWS_PER_BANK][COLS_PER_BANK];
    unit16_t descrambledImageFlattened[NUM_BANKS * ROWS_PER_BANK * COLS_PER_BANK];

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
   	int bankRemapping[24] = {0, 6, 12, 18, 1, 7, 13, 19, 2, 8, 14, 20, 3, 9, 15, 21, 4, 10, 16, 22, 5, 11, 17, 23};
    int colOffset[24] = {0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5 };
    int rowOffset[24] = {0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4, 5 };

    int rowPerBankIndex = 0;
    int colPerBankIndex = 1;
    bool even = false;

    for (imageAxiStreamBunchesIndex = 1; imageAxiStreamBunchesIndex < 3073; imageAxiStreamBunchesIndex++)
    {
        for (bankIndex = 0; bankIndex < NUM_BANKS; bankIndex++)
        {
            //descrambledImage[bankRemapping[bankIndex]][rowPerBankIndex][colPerBankIndex] = imageAxiStreamBunches[imageAxiStreamBunchesIndex][bankIndex];
            descrambledImageFlattened[
                                        rowOffset[bankRemapping[bankIndex]] * BANKS_PER_ROW * ROWS_PER_BANK * COLS_PER_BANK + 
                                        colOffset[bankRemapping[bankIndex]] * COLS_PER_BANK +
                                        rowPerBankIndex * BANKS_PER_ROW * COLS_PER_BANK + 
                                        colPerBankIndex ] = imageAxiStreamBunches[imageAxiStreamBunchesIndex][bankIndex];
                                      
                                      
                                      
        }

        if (colPerBankIndex >= COLS_PER_BANK-2) 
            if (even == true)
                colPerBankIndex = 0;
            else
                colPerBankIndex = 1;

        if (rowPerBankIndex >= ROWS_PER_BANK - 1) then
            rowPerBankIndex = 0;


        if (colPerBankIndex == COLS_PER_BANK-1) and (rowPerBankIndex == ROWS_PER_BANK - 1)
            even = true;
            colPerBankIndex = 0;

        if (colPerBankIndex == COLS_PER_BANK-2) and (rowPerBankIndex == ROWS_PER_BANK - 1)
            break;

        // Update counters
        colPerBankIndex = colPerBankIndex + 2;
        rowPerBankIndex++;

    }

    outputImageAxiStreamBunches[0] = imageAxiStreamBunches[0];
    for (imageAxiStreamBunchesIndex = 0; imageAxiStreamBunchesIndex < 3072; imageAxiStreamBunchesIndex++)
    {
        for (bankIndex = 0; bankIndex < NUM_BANKS; bankIndex++)
        {
            outputImageAxiStreamBunches[imageAxiStreamBunchesIndex+1][bankIndex] = descrambledImageFlattened[imageAxiStreamBunchesIndex * NUM_BANKS + bankIndex];
        }
    }
    return 0;
}