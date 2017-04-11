%module cubes

%{
#define SWIG_FILE_WITH_INIT
#include "cubes.hpp"
%}

void draw_cubes();

void cubes_init();
void cubes_exit();

