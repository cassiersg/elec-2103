#include <stdio.h>
#include "includes.h"
#include "system.h"
#include "mtltouch.h"

/* Definition of Task Stacks */
#define   TASK_STACKSIZE       2048
OS_STK    task1_stk[TASK_STACKSIZE];
OS_STK    task2_stk[TASK_STACKSIZE];

/* Definition of Task Priorities */
#define TASK1_PRIORITY      1
#define TASK2_PRIORITY      2

#define WHITE	0x000000
#define BLACK	0xFFFFFF
#define RED		0xFF0000
#define GREEN	0x00FF00
#define GRAY	0x808080

#define DEBUG	1

void init_color_map() {
	volatile int * colormap_ram = (int *) COLORMAP_BASE;

	colormap_ram[0] = WHITE;
	colormap_ram[1] = BLACK;
	colormap_ram[2] = RED;
	colormap_ram[3] = GREEN;
	colormap_ram[4] = GRAY;
}

void init_tiles_idx_ram() {
	volatile char * tiles_idx_0_ram = (char *) TILE_IDX_0_BASE;
	volatile char * tiles_idx_1_ram = (char *) TILE_IDX_1_BASE;

	int i;
	for (i=0; i< 4*1500; i++) {
		tiles_idx_0_ram[i] = 0;
		tiles_idx_1_ram[i] = 0;
	}
}

void init_tiles_ram() {
	volatile char * tiles_ram = (char *) TILE_IMAGE_BASE;

	int i, j;
	for (i = 0; i < 64; i++) {
		for (j = 0; j < 10; j++) {
			char tidx = (i == 0) ? 3 : j;
			tiles_ram[i+j*64] = tidx;
		}
	}
}

void init() {
	init_color_map();
	init_tiles_idx_ram();
	init_tiles_ram();
}

void task1(void* pdata) {
	volatile int * display_control = (int *) DISPLAY_CONTROL_BASE;
	volatile int* msg_reg = (int *) MESSAGE_MEM_BASE;
	
	*display_control = 1;
	msg_reg[1] = *display_control;

	while (1) {
		*display_control = msg_reg[0];
		msg_reg[1] = *display_control;

		OSTimeDlyHMSM(0, 0, 0, 25);
	}
}

int main(void) {
	init();

	OSTaskCreateExt(task1,
			NULL,
			(void *)&task1_stk[TASK_STACKSIZE-1],
			TASK1_PRIORITY,
			TASK1_PRIORITY,
			task1_stk,
			TASK_STACKSIZE,
			NULL,
			0);

	OSTaskCreateExt(task_touch_sense,
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
