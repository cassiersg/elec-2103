/*
 * 	TODO: use a mailbox to pass data to the emit_spi function to please JD
 */

#include <stdio.h>
#include <assert.h>
#include "mtltouch.h"
#include "system.h"
#include "includes.h"

#include "utils.h"

#define X_THRESHOLD 400

#define MTL_TOUCH_X1 (((int *) MTL_TOUCH_BASE) + 0)
#define MTL_TOUCH_Y1 (((int *) MTL_TOUCH_BASE) + 8)
#define MTL_TOUCH_X2 (((int *) MTL_TOUCH_BASE) + 1)
#define MTL_TOUCH_Y2 (((int *) MTL_TOUCH_BASE) + 9)
#define MTL_TOUCH_COUNT (((int *) MTL_TOUCH_BASE) + 16)
#define MTL_TOUCH_GESTURE (((int *) MTL_TOUCH_BASE) + 17)
#define MTL_TOUCH_READY (((int *) MTL_TOUCH_BASE) + 18)

static void emit_touch_event_rpi(int x);

typedef enum {notouch, intouch} touch_state;

typedef union {
    struct {
    } notouch;
    struct {
        int x_init, y_init, t_count;
    } intouch;
} touch_state_data;

int abs(int x) {
	return x >= 0 ? x: -x;
}

void task_touch_sense(void *pdata)
{
    debug_printf("Task touch sense started\n");

    volatile int *mtl_touch_x1 		= MTL_TOUCH_X1;
    volatile int *mtl_touch_y1 		= MTL_TOUCH_Y1;
    volatile int *mtl_touch_x2		= MTL_TOUCH_X2;
    volatile int *mtl_touch_y2 		= MTL_TOUCH_Y2;
    volatile int *mtl_touch_count 	= MTL_TOUCH_COUNT;

    touch_state state = notouch;
    touch_state_data state_data;

    int x_final, y_final;

    while (1) {
        int t_count = *mtl_touch_count;

        if (t_count > 4) {
            debug_printf("Invalid touch count\n");
            state = notouch;
        } else if (state == notouch || (t_count > state_data.intouch.t_count)) {
        	/* The second condition deals with non-ideal pause gestures (i.e. touch_count
        	 * is not especially at 2 directly) */
            if (t_count != 0) {
            	state = intouch;

                if(t_count == 1) {
					state_data.intouch.x_init = *mtl_touch_x1;
					state_data.intouch.y_init = *mtl_touch_y1;
					state_data.intouch.t_count = *mtl_touch_count;
                } else if(t_count == 2) {
                	state_data.intouch.x_init = (*mtl_touch_x1 + *mtl_touch_x2)/2;
					state_data.intouch.y_init = (*mtl_touch_y1 + *mtl_touch_y2)/2;
					state_data.intouch.t_count = *mtl_touch_count;
                } else {
                	state_data.intouch.t_count = *mtl_touch_count;
                }
            }
        } else if (state == intouch) {
            if (t_count == 0) {
            	if (state_data.intouch.t_count == 1) {
            		debug_printf("Touch detected\n");
            		int msg;
            		if (state_data.intouch.x_init < X_THRESHOLD) {
            				msg = 1; // LEFT
            			} else {
            				msg = 2; // RIGHT
            		}
            		emit_touch_event_rpi(msg);
            		//emit_touch_to_rpi(state_data.intouch.x_init, state_data.intouch.y_init);
            	} else if (state_data.intouch.t_count == 2) {
            		int dx = abs(x_final - state_data.intouch.x_init);
            		int dy = abs(y_final - state_data.intouch.y_init);

            		if(dx < 100 && dy > 150) {
            			debug_printf("Pause or resume detected\n");
            			emit_touch_event_rpi(3);
            			//emit_pause_resume_to_rpi();
                    }
            	} else {
                	debug_printf("Triple touch detected!\n");
                	emit_touch_event_rpi(4);
                	//emit_hide_struct_to_rpi();
            	}

            	state = notouch;
            } else if(t_count == 2) {
        		x_final = (*mtl_touch_x1 + *mtl_touch_x2)/2;
        		y_final = (*mtl_touch_y1 + *mtl_touch_y2)/2;
            }
        }

        OSTimeDlyHMSM(0, 0, 0, 2);
    }
}

void task_emit_touch_event_rpi(void *pdata) {
	volatile int *msg_reg = (int *) MESSAGE_MEM_BASE;
	while (1) {
		INT8U err;
		int x = (int) OSMboxPend(mbox_touch, 0, &err);
		assert(!err);
		OSMutexPend(mutex_spi, 0, &err);
		msg_reg[2] = x;
		OSMutexPost(mutex_spi);
	}
}
static void emit_touch_event_rpi(int x) {
	OSMboxPost(mbox_touch, (void *) x);
}
