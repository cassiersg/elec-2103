#include <stdio.h>
#include "mtltouch.h"

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

					if(my_abs(x1 - xnew) > my_abs(y1 - ynew)) {
						if(xnew > x1) {
							printf("Swipe east detected.\n");
						} else {
							printf("Swipe west detected.\n");
						}
					} else {
						printf("Vertical swipe detected.\n");
					}

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

					// FIX: tap_init
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


