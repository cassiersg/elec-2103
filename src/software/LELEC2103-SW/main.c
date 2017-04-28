#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "HAL/inc/priv/alt_iic_isr_register.h"
#include "altera_avalon_pio_regs.h"
#include "io.h"
#include "includes.h"
#include "system.h"
#include "mtltouch.h"
#include "gsensor.h"
#include "utils.h"
//#include "tiling_roms.h"
//#include "compressed.h"

/* Definition of Task Stacks */
#define   TASK_STACKSIZE       2048
OS_STK    task1_stk[TASK_STACKSIZE];
OS_STK    task2_stk[TASK_STACKSIZE];
OS_STK    task3_stk[TASK_STACKSIZE];

/* Definition of Task Priorities */
#define TASK1_PRIORITY      4
#define TASK2_PRIORITY      6
#define TASK3_PRIORITY      8

void init() {
}

void task1(void* pdata) {
//	volatile int* msg_reg = (int *) MESSAGE_MEM_BASE;
//
//
//
	debug_printf("start task 1\n");
	while (1) {
		OSTimeDlyHMSM(0, 0, 0, 20);
	}
}

//void endframe_isr(void* data) {
//	IOWR(PIO_ENDFRAME_BASE, 3, 1);
//}

int main(void) {
//	need_pageflip = 0;
//	IOWR(PIO_ENDFRAME_BASE, 2, 1);
//	 int reg_ret = alt_iic_isr_register(PIO_ENDFRAME_IRQ_INTERRUPT_CONTROLLER_ID,
//			 PIO_ENDFRAME_IRQ,
//			 &endframe_isr,
//			 NULL,
//			 NULL);
//	 assert(!reg_ret);


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

	debug_printf("started task 1\n");
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
