#ifndef MTLTOUCH_H_
#define MTLTOUCH_H_

#include "system.h"

#define MTL_TOUCH_X (((int *) MTL_IP_0_BASE) + 0)
#define MTL_TOUCH_Y (((int *) MTL_IP_0_BASE) + 8)
#define MTL_TOUCH_COUNT (((int *) MTL_IP_0_BASE) + 16)
#define MTL_TOUCH_GESTURE (((int *) MTL_IP_0_BASE) + 17)
#define MTL_TOUCH_READY (((int *) MTL_IP_0_BASE) + 18)

#endif
