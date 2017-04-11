#ifndef _H_GL_PLATFORM_H_
#define _H_GL_PLATFORM_H_

#ifdef RPI
#include "bcm_host.h"
#endif

void platform_gl_init(int width, int height);
void platform_gl_exit();

#endif
