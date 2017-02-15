/*
 * main.c
 *
 *  Created on: Feb 16, 2017
 *      Author: cgaetan
 */

// Include the user-friendly names for the peripheral addresses.
#include <stdio.h>
#include "mtltouch.h"

int main(void)
{
	printf("=== Starting MTL touch demo ===\n");

	volatile int *mtl_touch_x = MTL_TOUCH_X;
	volatile int *mtl_touch_y = MTL_TOUCH_Y;
	volatile int *mtl_touch_count = MTL_TOUCH_COUNT;
	volatile int *mtl_touch_gesture = MTL_TOUCH_GESTURE;

	int reg_x[5] = {0, 0, 0, 0, 0};
	int reg_y[5] = {0, 0, 0, 0, 0};
	int reg_count = 0;
	int reg_gesture = 0;

	int i;

	while (1) {
		if (*mtl_touch_count != reg_count) {
			printf("New touch count: %i\n", *mtl_touch_count);
			reg_count = *mtl_touch_count;
		}
		if (*mtl_touch_gesture != reg_gesture) {
			printf("New touch count: %x\n", *mtl_touch_gesture);
			reg_gesture = *mtl_touch_gesture;
		}
		for (i = 0; i < 5; i++) {
			if (mtl_touch_x[i] != reg_x[i]) {
				printf("New X[%i]: %i\n", i, mtl_touch_x[i]);
				reg_x[i] = mtl_touch_x[i];
			}
			if (mtl_touch_y[i] != reg_y[i]) {
				printf("New Y[%i]: %i\n", i, mtl_touch_y[i]);
				reg_y[i] = mtl_touch_y[i];
			}
		}
		for (i=0; i<100000; i++);
	}
	return 0;
}
