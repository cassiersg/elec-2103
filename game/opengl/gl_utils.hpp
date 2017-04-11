#ifndef _H_GL_UTILS_H_
#define _H_GL_UTILS_H_

#include "GLES/gl.h"
#include "GLES2/gl2.h"

void assertOpenGLError(const char *msg);

GLuint loadShader ( GLenum type, const char *shaderSrc );

GLuint gen_program(const char* vertex_shader_src, const char* fragment_shader_src);

void glbuf2rgb(unsigned char *buffer, int width, int height);

#endif
