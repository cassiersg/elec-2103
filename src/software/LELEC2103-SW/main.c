/*************************************************************************
 * Copyright (c) 2004 Altera Corporation, San Jose, California, USA.      *
 * All rights reserved. All use of this software and documentation is     *
 * subject to the License Agreement located at the end of this file below.*
 **************************************************************************
 * Description:                                                           *
 * The following is a simple hello world program running MicroC/OS-II.The *
 * purpose of the design is to be a very simple application that just     *
 * demonstrates MicroC/OS-II running on NIOS II.The design doesn't account*
 * for issues such as checking system call return codes. etc.             *
 *                                                                        *
 * Requirements:                                                          *
 *   -Supported Example Hardware Platforms                                *
 *     Standard                                                           *
 *     Full Featured                                                      *
 *     Low Cost                                                           *
 *   -Supported Development Boards                                        *
 *     Nios II Development Board, Stratix II Edition                      *
 *     Nios Development Board, Stratix Professional Edition               *
 *     Nios Development Board, Stratix Edition                            *
 *     Nios Development Board, Cyclone Edition                            *
 *   -System Library Settings                                             *
 *     RTOS Type - MicroC/OS-II                                           *
 *     Periodic System Timer                                              *
 *   -Know Issues                                                         *
 *     If this design is run on the ISS, terminal output will take several*
 *     minutes per iteration.                                             *
 **************************************************************************/


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

/* Prints "Hello World" and sleeps for three seconds */
void task1(void* pdata)
{
	volatile int * tiles_ram = (int *) TILES_RAM_BASE;
	volatile int * tiles_idx_ram = (int *) TILES_IDX_RAM_BASE;
	// display fancy patterns
	int i;
	for (i=0; i < 1500; i++) {
		int a = 0;
		a |= ((4*i+3)%6) << 24;
		a |= ((4*i+2)%6) << 16;
		a |= ((4*i+1)%6) << 8;
		a |= ((4*i)%6);
		tiles_idx_ram[i] = a;
	}
	// set tile 0.
	for (i = 0; i < 16; i++) {
		tiles_ram[i] = 0x0;
		tiles_ram[i+16] = 0x00FF0000;
		tiles_ram[i+32] = 0x00FFFFFF;
		tiles_ram[i+16+32] = 0x0000FF00;
	}
	for (i = 0; i < 4; i++) {
		tiles_ram[8*i] = 0x000000FF;
		tiles_ram[8*i+1] = 0x000000FF;
		tiles_ram[8*i+2] = 0x000000FF;
		tiles_ram[8*i+3] = 0x000000FF;
	}
	for (i=0; i< 64; i++) {
		tiles_ram[i+64*1] = 0x0000FF00;
		tiles_ram[i+64*2] = 0x000000FF;
		tiles_ram[i+64*3] = 0x00FF0000;
		tiles_ram[i+64*4] = 0x00FFFFFF;
		tiles_ram[i+64*5] = 0x0;
	}

	while (1)
	{
		printf("It's working\n");

		while (1) {
			volatile int * spi_ptr =   (int*) PI_MAILBOX_MEM_BASE;
			volatile int * spi_ptr_fresh =   spi_ptr + 0x10;
			int last = 0xFFFFFFFF;
			while (1)
			{
				int i;
				for (i=0; i<10000; i++);

				if (spi_ptr[0] != last) {
					last = spi_ptr[0];
					printf("%x  %x\n", spi_ptr[0], spi_ptr[1]);
				}

				if ((spi_ptr[0] & 0xFFFF) == 0xDEAD) {
					printf("updating\n");
					spi_ptr[0] = 0xBEEF00 | (spi_ptr[0] >> 16);
					last = spi_ptr[0];
				}

				if (spi_ptr_fresh[2]) {
					printf("new message %x\n", spi_ptr[2]);
					spi_ptr[3] = 0xAAA;
				}
			}
		}
		OSTimeDlyHMSM(0, 0, 3, 0);
	}
}
/* Prints "Hello World" and sleeps for three seconds */
void task2(void* pdata)
{
	while (1)
	{
		OSTimeDlyHMSM(0, 0, 3, 0);
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
