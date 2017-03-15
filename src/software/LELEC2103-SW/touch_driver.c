#include <stdio.h>
#include "mtltouch.h"

typedef enum {notouch, intouch} touch_state;

typedef union {
    struct {
    } notouch;
    struct {
        int x_init, y_init;
    } intouch;
} touch_state_data;


void task_touch_sense(*pdata)
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
            error("Invalid touch count\n");
            state = notouch;
        } else if (state == notouch) {
            if (t_count != 0) {
                state = intouch;
                state_data.intouch.x_init = *mtl_touch_x;
                state_data.intouch.y_init = *mtl_touch_y;
            }
        } else if (state == intouch) {
            if (t_count == 0) {
                // TODO emit data (in message box for example)
                state = notouch;
            }
        }
        OSTimeDly(0, 0, 0, 0, 20);
    }
}
