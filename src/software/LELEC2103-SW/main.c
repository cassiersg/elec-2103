/*
 * main.c
 *
 *  Created on: Feb 16, 2017
 *      Author: cgaetan
 */

// Include the user-friendly names for the peripheral addresses.
#include <stdio.h>
#include "mtltouch.h"

typedef struct touch_info {
	int x1, x2, x3, x4, x5;
	int y1, y2, y3, y4, y5;
	int touch_count;
	int gesture;
} touch_info;

touch_info build_touch_info(
		int x1, int x2, int x3, int x4, int x5,
		int y1, int y2, int y3, int y4, int y5,
		int touch_count, int gesture) {

	touch_info t = {x1, x2, x3, x4, x5, y1, y2, y3, y4, y5, touch_count, gesture};
	return t;
}

int is_valid_touch_info(touch_info t) {
	return 1;//t.touch_count != 14;
}

void print_touch_info(touch_info t) {
	if(is_valid_touch_info(t)) {
		if(t.touch_count > 0) {
			printf("-- Touch count: %i\n", t.touch_count);
			//printf("-- Gesture: %i\n", t.gesture);
		}

		if(t.touch_count > 0)	printf("(x1, y1): (%i,%i)\n", t.x1, t.y1);
		if(t.touch_count > 1)	printf("(x2, y2): (%i,%i)\n", t.x2, t.y2);
		if(t.touch_count > 2)	printf("(x3, y3): (%i,%i)\n", t.x3, t.y3);
		if(t.touch_count > 3)	printf("(x4, y4): (%i,%i)\n", t.x4, t.y4);
		if(t.touch_count > 4)	printf("(x5, y5): (%i,%i)\n", t.x5, t.y5);
	}
}

int main(void)
{
	printf("=== Starting MTL touch demo ===\n");

	volatile int *mtl_touch_x 		= MTL_TOUCH_X;
	volatile int *mtl_touch_y 		= MTL_TOUCH_Y;
	volatile int *mtl_touch_count 	= MTL_TOUCH_COUNT;
	volatile int *mtl_touch_gesture = MTL_TOUCH_GESTURE;

	int delay;

	touch_info buffer[10];

	int started = 0;
	int counter = 0;
	int x1, y1;

	while (1) {
		touch_info t = build_touch_info(
				mtl_touch_x[0],
				mtl_touch_x[1],
				mtl_touch_x[2],
				mtl_touch_x[3],
				mtl_touch_x[4],
				mtl_touch_y[0],
				mtl_touch_y[1],
				mtl_touch_y[2],
				mtl_touch_y[3],
				mtl_touch_y[4],
				*mtl_touch_count,
				*mtl_touch_gesture);

		print_touch_info(t);

		for(delay = 0; delay < 100000; delay++);
	}

	return 0;
}


