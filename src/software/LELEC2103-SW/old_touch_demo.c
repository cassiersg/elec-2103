/*
 * main.c
 *
 *  Created on: Feb 16, 2017
 *      Author: cgaetan
 */

// Include the user-friendly names for the peripheral addresses.
#include <stdio.h>
#include "mtltouch.h"

#define GLITCH_THRESHOLD 10

typedef struct touch_info {
	int x1, x2, x3, x4, x5;
	int y1, y2, y3, y4, y5;
	int touch_count;
	int gesture;
	int touch_ready;
} touch_info;

void print_touch_info(touch_info t) {
	if(t.touch_count > 0) {
		printf("-- Touch count: %i\n", t.touch_count);
		printf("-- Gesture: %i\n", t.gesture);
		printf("-- Touch ready: %i\n", t.touch_ready);
	} else {
		//printf("No touch event...\n");
	}

	if(t.touch_count > 0)	printf("(x1, y1): (%i,%i)\n", t.x1, t.y1);
	if(t.touch_count > 1)	printf("(x2, y2): (%i,%i)\n", t.x2, t.y2);
	if(t.touch_count > 2)	printf("(x3, y3): (%i,%i)\n", t.x3, t.y3);
	if(t.touch_count > 3)	printf("(x4, y4): (%i,%i)\n", t.x4, t.y4);
	if(t.touch_count > 4)	printf("(x5, y5): (%i,%i)\n", t.x5, t.y5);
}

typedef enum touch_state touch_state;
enum touch_state {notouch, dead, in_touch, just_released};

int my_abs(int x) {
	return (x > 0) ? x : -x;
}

#define TAP_RADIUS 50

int main(void)
{
	printf("=== Starting MTL touch demo ===\n");

	volatile int *mtl_touch_x 		= MTL_TOUCH_X;
	volatile int *mtl_touch_y 		= MTL_TOUCH_Y;
	volatile int *mtl_touch_count 	= MTL_TOUCH_COUNT;
	volatile int *mtl_touch_gesture = MTL_TOUCH_GESTURE;
	volatile int *mtl_touch_ready	= MTL_TOUCH_READY;

	int delay;

	int x1, y1;
	int just_released_counter = 0;
	int current_touch_counter = 0;
	touch_state t = notouch;

	while (1) {
		for(delay = 0; delay < 100; delay++);

		int touch_count = *mtl_touch_count;
		if(touch_count > 1) {
			printf("Invalid touch count.\n");
			continue;
		}

		if(t == notouch) {
			if(touch_count == 1) {
				x1 = mtl_touch_x[0];
				y1 = mtl_touch_y[0];
				t = in_touch;
			}
		} else if(t == in_touch) {
			if(touch_count == 1) {
				int xnew = mtl_touch_x[0];
				int ynew = mtl_touch_y[0];

				if(my_abs(x1 - xnew) > TAP_RADIUS || my_abs(y1 - ynew) > TAP_RADIUS) {
					if(current_touch_counter != 0) {
						printf("Tap detected: %i at (%i, %i).\n", current_touch_counter, x1, y1);
						current_touch_counter = 0;
					}

					printf("Swipe detected.\n");
					t = dead;
				}
			} else if(touch_count == 0) {
				current_touch_counter++;
				t = just_released;
			}
		} else if(t == just_released) {
			if(just_released_counter >= 2000) {
				printf("Tap detected: %i at (%i, %i).\n", current_touch_counter, x1, y1);
				current_touch_counter = 0;
				just_released_counter = 0;
				t = dead;
			} else {
				just_released_counter++;

				if(touch_count == 1) {
					int xnew = mtl_touch_x[0];
					int ynew = mtl_touch_y[0];

					// FIC: tap_init
					if(my_abs(x1 - xnew) > TAP_RADIUS || my_abs(y1 - ynew) > TAP_RADIUS) {
						printf("Tap detected: %i at (%i, %i).\n", current_touch_counter, x1, y1);
						current_touch_counter = 0;
					}

					x1 = xnew;
					y1 = ynew;

					t = in_touch;
					just_released_counter = 0;
				}
			}
		} else if(t == dead) {
			for(delay = 0; delay < 200000; delay++);
			t = notouch;
		}
	}

	return 0;
}


