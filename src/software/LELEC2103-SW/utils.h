#ifndef UTILS_234_H_
#define UTILS_234_H_

#include "includes.h"
#include <stdio.h>

#define DEBUG 0
#if DEBUG
#define debug_printf(fmt, ...) fprintf(stderr, fmt, __VA_ARGS__)
#else
#define debug_printf(fmt,...)
#endif

extern OS_EVENT *mutex_spi;
extern OS_EVENT *mbox_touch;

#endif /* UTILS_H_ */
