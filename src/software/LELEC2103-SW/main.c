#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "includes.h"
#include "system.h"
#include "mtltouch.h"
#include "gsensor.h"
#include "tiling_roms.h"


/* Definition of Task Stacks */
#define   TASK_STACKSIZE       2048
OS_STK    task1_stk[TASK_STACKSIZE];
OS_STK    task2_stk[TASK_STACKSIZE];
OS_STK    task3_stk[TASK_STACKSIZE];

/* Definition of Task Priorities */
#define TASK1_PRIORITY      4
#define TASK2_PRIORITY      6
#define TASK3_PRIORITY      8

#define WHITE	0x000000
#define BLACK	0xFFFFFF
#define RED		0xFF0000
#define GREEN	0x00FF00
#define GRAY	0x808080

#define DEBUG	1

void init_color_map() {
	volatile int * colormap_ram = (int *) COLORMAP_BASE;
        assert(COLORMAP_ROM_LEN == 256);
        memcpy(colormap_ram, colormap_rom, 256*sizeof(int));
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
        assert(TILES_IMAGE_ROM_LEN <= 256); // FIXME replace with constant from system.h
        memcpy(tiles_ram, tiles_image_rom, TILES_IMAGE_ROM_LEN);
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

//	assert(ADXL345_SPI_Init(SPI_GSENSOR_BASE));
	while (1) {
		*display_control = msg_reg[0];
		msg_reg[1] = *display_control;

		OSTimeDlyHMSM(0, 0, 0, 20);
//
//		OSTimeDlyHMSM(0, 0, 1, 0);
//		alt_16 szXYZ[3];
//		bool ready = ADXL345_SPI_IsDataReady(SPI_GSENSOR_BASE);
//		bool readres = ADXL345_SPI_XYZ_Read(SPI_GSENSOR_BASE, szXYZ);
//		printf("data ready: %d, x: %d, y: %d, z: %d, res: %d\n", ready, szXYZ[0], szXYZ[1], szXYZ[2], readres);

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

	OSTaskCreateExt(task_g_sense,
				NULL,
				(void *)&task3_stk[TASK_STACKSIZE-1],
				TASK3_PRIORITY,
				TASK3_PRIORITY,
				task3_stk,
				TASK_STACKSIZE,
				NULL,
				0);

	OSStart();

	return 0;
}
