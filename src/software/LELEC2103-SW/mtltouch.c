#include <stdio.h>
#include "mtltouch.h"
#include "system.h"
#include "includes.h"

#define MTL_TOUCH_X (((int *) MTL_TOUCH_BASE) + 0)
#define MTL_TOUCH_Y (((int *) MTL_TOUCH_BASE) + 8)
#define MTL_TOUCH_COUNT (((int *) MTL_TOUCH_BASE) + 16)
#define MTL_TOUCH_GESTURE (((int *) MTL_TOUCH_BASE) + 17)
#define MTL_TOUCH_READY (((int *) MTL_TOUCH_BASE) + 18)

static void emit_touch_to_rpi(int x, int y);

typedef enum {notouch, intouch} touch_state;

typedef union {
    struct {
    } notouch;
    struct {
        int x_init, y_init;
    } intouch;
} touch_state_data;


void task_touch_sense(void *pdata)
{
    volatile int *mtl_touch_x 		= MTL_TOUCH_X;
    volatile int *mtl_touch_y 		= MTL_TOUCH_Y;
    volatile int *mtl_touch_count 	= MTL_TOUCH_COUNT;
    volatile int *mtl_touch_gesture = MTL_TOUCH_GESTURE;
    volatile int *mtl_touch_ready	= MTL_TOUCH_READY;

    touch_state state = notouch;
    touch_state_data state_data;

    while (1) {
        int t_count = *mtl_touch_count;
        if (t_count > 1) {
            printf("Invalid touch count\n");
            state = notouch;
        } else if (state == notouch) {
            if (t_count != 0) {
                state = intouch;
                state_data.intouch.x_init = *mtl_touch_x;
                state_data.intouch.y_init = *mtl_touch_y;
            }
        } else if (state == intouch) {
            if (t_count == 0) {
                // FIXME emit data (in message box for example)
            	emit_touch_to_rpi(state_data.intouch.x_init, state_data.intouch.y_init);
                state = notouch;
            }
        }
        OSTimeDlyHMSM(0, 0, 0, 20);
    }
}

#define X_THRESHOLD 400
static void emit_touch_to_rpi(int x, int y) {
	volatile int *msg_reg = (int *) MESSAGE_MEM_BASE;
	if (x < X_THRESHOLD) {
		msg_reg[2] = 1; // LEFT
	} else {
		msg_reg[2] = 2; // RIGHT
	}
}
