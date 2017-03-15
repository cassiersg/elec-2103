#include <stdio.h>
#include "includes.h"
#include "system.h"

/* Definition of Task Stacks */
#define   TASK_STACKSIZE       2048
OS_STK    task1_stk[TASK_STACKSIZE];
OS_STK    task2_stk[TASK_STACKSIZE];

/* Definition of Task Priorities */

#define TASK1_PRIORITY      1
#define TASK2_PRIORITY      2

#define TILES_ROW 100
#define GRID_SCALE_FACTOR 4

char grid[8][8] = {
	{0, 0, 0, 0, 0, 0, 0, 0},
	{0, 0, 0, 1, 0, 0, 2, 0},
	{0, 1, 3, 1, 1, 0, 1, 0},
	{0, 1, 1, 1, 1, 0, 1, 0},
	{0, 1, 1, 1, 1, 0, 1, 0},
	{0, 1, 1, 1, 1, 0, 1, 1},
	{1, 1, 1, 1, 1, 1, 1, 1},
	{1, 1, 1, 1, 1, 1, 1, 1}
};

void task1(void* pdata)
{
	int i, j;
	
	volatile char * tiles_ram = (char *) TILE_IMAGE_BASE;
	volatile char * tiles_idx_0_ram = (char *) TILE_IDX_0_BASE;
	volatile char * tiles_idx_1_ram = (char *) TILE_IDX_1_BASE;
	volatile int * colormap_ram = (int *) COLORMAP_BASE;
	volatile int * display_control = (int *) DISPLAY_CONTROL_BASE;

	for (i=0; i<4*1500; i++) {
			tiles_idx_0_ram[i] = 0;
			tiles_idx_1_ram[i] = 0;
	}
//	tiles_idx_0_ram[1000] = 2;
//	tiles_idx_0_ram[1099] = 4;
//	tiles_idx_0_ram[1100] = 4;
//	tiles_idx_0_ram[1201] = 4;
	for (i=0; i<8; i++) {
		for (j=0; j<8; j++) {
			int i_off, j_off;
			for (i_off = 0; i_off < GRID_SCALE_FACTOR; i_off++) {
				for (j_off = 0; j_off < GRID_SCALE_FACTOR; j_off++) {
					tiles_idx_0_ram[TILES_ROW*(j*GRID_SCALE_FACTOR+j_off)+i*GRID_SCALE_FACTOR+i_off] = grid[j][i];
				}
			}
		}
	}
	for (i=0; i<64; i++) {
		for (j=0; j<4; j++) {
			char tidx;
			tidx = j;
			if (i==0) tidx = 3;
			//else if ((i & 0x7)==0) tidx = 2;
			tiles_ram[i+j*64] = tidx;
		}
		tiles_ram[4*64+i] = (i & 0x3);
	}
	colormap_ram[0]  = 0;
	colormap_ram[1] = 0xFFFFFF;
	colormap_ram[2] = 0xFF0000;
	colormap_ram[3] = 0x00FF00;
	colormap_ram[0xFF] = 0x0;

	*display_control = 1;
	volatile int* msg_reg = (int *) MESSAGE_MEM_BASE;
	msg_reg[1] = *display_control;


	printf("It's working, %i\n", sizeof(int));
	while (1)
	{
		*display_control = msg_reg[0];
		msg_reg[1] = *display_control;
		OSTimeDlyHMSM(0, 0, 0, 50);
	}
}
/* Prints "Hello World" and sleeps for three seconds */
void task2(void* pdata)
{
	while (1)
	{
		OSTimeDlyHMSM(0, 0, 3, 0);
//		volatile int* msg_reg = (int *) MESSAGE_MEM_BASE;
//		msg_reg[1] = 0x0000BEEF;
//		printf("%x\n", msg_reg[0]);
//		volatile char * tiles_idx_0_ram = (char *) TILE_IDX_0_BASE;
//		volatile char * tiles_idx_1_ram = (char *) TILE_IDX_1_BASE;
//		int i;
//		for (i=0; i<20; i++) {
//			printf("0 %i: %i\n", i, tiles_idx_0_ram[i]);
//			printf("1 %i: %i\n", i, tiles_idx_1_ram[i]);
//		}
	}
}
/* The main function creates two task and starts multi-tasking */
int main(void)
{

	OSTaskCreateExt(task1,
			NULL,
			(void *)&task1_stk[TASK_STACKSIZE-1],
			TASK1_PRIORITY,
			TASK1_PRIORITY,
			task1_stk,
			TASK_STACKSIZE,
			NULL,
			0);


	OSTaskCreateExt(task2,
			NULL,
			(void *)&task2_stk[TASK_STACKSIZE-1],
			TASK2_PRIORITY,
			TASK2_PRIORITY,
			task2_stk,
			TASK_STACKSIZE,
			NULL,
			0);
	OSStart();
	return 0;
}

/******************************************************************************
 *                                                                             *
 * License Agreement                                                           *
 *                                                                             *
 * Copyright (c) 2004 Altera Corporation, San Jose, California, USA.           *
 * All rights reserved.                                                        *
 *                                                                             *
 * Permission is hereby granted, free of charge, to any person obtaining a     *
 * copy of this software and associated documentation files (the "Software"),  *
 * to deal in the Software without restriction, including without limitation   *
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,    *
 * and/or sell copies of the Software, and to permit persons to whom the       *
 * Software is furnished to do so, subject to the following conditions:        *
 *                                                                             *
 * The above copyright notice and this permission notice shall be included in  *
 * all copies or substantial portions of the Software.                         *
 *                                                                             *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  *
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,    *
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE *
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER      *
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING     *
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER         *
 * DEALINGS IN THE SOFTWARE.                                                   *
 *                                                                             *
 * This agreement shall be governed in all respects by the laws of the State   *
 * of California and by the laws of the United States of America.              *
 * Altera does not recommend, suggest or require that this reference design    *
 * file be used in conjunction or combination with any other product.          *
 ******************************************************************************/
