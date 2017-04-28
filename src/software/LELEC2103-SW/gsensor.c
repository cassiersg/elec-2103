#include "gsensor.h"
#include "utils.h"

#include <assert.h>
#include <stdio.h>

#include "system.h"
#include "includes.h"
#include "alt_types.h"
#include "terasic/accelerometer_adxl345_spi.h"

void task_g_sense(void *pdata) {
	volatile int* msg_reg = (int *) MESSAGE_MEM_BASE;

	assert(ADXL345_SPI_Init(SPI_GSENSOR_BASE));
	OSTimeDlyHMSM(0, 0, 1, 0);
	while (1) {
		alt_16 szXYZ[3];
		//assert(ADXL345_SPI_IsDataReady(SPI_GSENSOR_BASE));
		assert(ADXL345_SPI_XYZ_Read(SPI_GSENSOR_BASE, szXYZ));
		INT8U err;
		OSMutexPend(mutex_spi, 0, &err);
		assert(!err);
		msg_reg[3] = szXYZ[0];
		msg_reg[4] = szXYZ[1];
		msg_reg[5] = szXYZ[2];
		debug_printf("acc: %i\n", msg_reg[3]);
		OSMutexPost(mutex_spi);
		OSTimeDlyHMSM(0, 0, 0, 50);
	}
}
