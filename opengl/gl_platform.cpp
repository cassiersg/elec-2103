#include "gl_platform.hpp"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <unistd.h>

#include "EGL/egl.h"
#include "EGL/eglext.h"
#include "GLES/gl.h"
#include "GLES2/gl2.h"

#include "gl_utils.hpp"

#define check() assert(glGetError() == 0)

typedef struct
{
#ifdef RPI
   uint32_t screen_width;
   uint32_t screen_height;
   DISPMANX_DISPLAY_HANDLE_T dispman_display;
   DISPMANX_ELEMENT_HANDLE_T dispman_element;
#else
    unsigned int canvasFrameBuffer;
    unsigned int canvasRenderBuffer;
#endif
   EGLDisplay display;
   EGLSurface surface;
   EGLContext context;
} GLOBAL_GL_SCREEN_STATE;

static GLOBAL_GL_SCREEN_STATE _state, *state=&_state;

static void assertEGLError(const char *msg);
static void assertEGLError(const char *msg)
{
    EGLint error = eglGetError();
    if (error != EGL_SUCCESS) {
        printf("EGL error %s\n", msg);
        assert(0);
    }
}

void platform_gl_init(int width, int height)
{
   EGLint num_configs;
   EGLConfig config;

   static const EGLint attribute_list[] =
   {
      EGL_RED_SIZE, 8,
      EGL_GREEN_SIZE, 8,
      EGL_BLUE_SIZE, 8,
      EGL_ALPHA_SIZE, 8,
      EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
      EGL_NONE
   };
   
   static const EGLint context_attributes[] =
   {
       EGL_CONTEXT_CLIENT_VERSION, 2,
       EGL_NONE
   };


   // get an EGL display connection
   state->display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
   assert(state->display!=EGL_NO_DISPLAY);
   check();

   // initialize the EGL display connection
   assert(eglInitialize(state->display, NULL, NULL) != EGL_FALSE);
   check();

   // get an appropriate EGL frame buffer configuration
   assert(eglChooseConfig(state->display, attribute_list, &config, 1, &num_configs) != EGL_FALSE);
   check();

   // get an appropriate EGL frame buffer configuration
   assert(eglBindAPI(EGL_OPENGL_ES_API) != EGL_FALSE);
   check();

   // create an EGL rendering context
   state->context = eglCreateContext(state->display, config, EGL_NO_CONTEXT, context_attributes);
   assert(state->context!=EGL_NO_CONTEXT);

#ifdef RPI
   // Not working without that, don't know why
   static EGL_DISPMANX_WINDOW_T nativewindow;
   DISPMANX_UPDATE_HANDLE_T dispman_update;
   VC_RECT_T dst_rect;
   VC_RECT_T src_rect;
   // create an EGL window surface
   assert(graphics_get_display_size(0 /* LCD */, &state->screen_width, &state->screen_height) >= 0);
   state->screen_width = width;
   state->screen_height = height;

   dst_rect.x = 0;
   dst_rect.y = 0;
   dst_rect.width = state->screen_width;
   dst_rect.height = state->screen_height;
 
   src_rect.x = 0;
   src_rect.y = 0;
   src_rect.width = state->screen_width << 16;
   src_rect.height = state->screen_height << 16;        

   state->dispman_display = vc_dispmanx_display_open( 0 /* LCD */);
   dispman_update = vc_dispmanx_update_start( 0 );
         
   state->dispman_element = vc_dispmanx_element_add ( dispman_update, state->dispman_display,
      0/*layer*/, &dst_rect, 0/*src*/,
      &src_rect, DISPMANX_PROTECTION_NONE, 0 /*alpha*/, 0/*clamp*/, (DISPMANX_TRANSFORM_T) 0/*transform*/);
      
   nativewindow.element = state->dispman_element;
   nativewindow.width = state->screen_width;
   nativewindow.height = state->screen_height;
   vc_dispmanx_update_submit_sync( dispman_update );
      
   state->surface = eglCreateWindowSurface( state->display, config, &nativewindow, NULL );
   assert(state->surface != EGL_NO_SURFACE);

   // connect the context to the surface
   assert(eglMakeCurrent(state->display, state->surface, state->surface, state->context)
           != EGL_FALSE);
   check();
#else
   // Not on RPI, MESA allows to create context without surface
   assert(eglMakeCurrent(state->display, EGL_NO_SURFACE, EGL_NO_SURFACE, state->context) != EGL_FALSE);
   check();

    // Create framebuffer
    glGenFramebuffers(1, &state->canvasFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, state->canvasFrameBuffer);

    // Attach renderbuffer
    glGenRenderbuffers(1, &state->canvasRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, state->canvasRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA4, width, height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, state->canvasRenderBuffer);
    assertOpenGLError("framebuffer");
#endif

   // Maybe not necessary (?)
   // Enable back face culling.
   glEnable(GL_CULL_FACE);
   //glMatrixMode(GL_MODELVIEW); // ??  works only on RPI
}

void platform_gl_exit()
{
#if RPI
   DISPMANX_UPDATE_HANDLE_T dispman_update;
   int s;
   // clear screen
   glClear( GL_COLOR_BUFFER_BIT );
   eglSwapBuffers(state->display, state->surface);

   eglDestroySurface( state->display, state->surface );

   dispman_update = vc_dispmanx_update_start( 0 );
   s = vc_dispmanx_element_remove(dispman_update, state->dispman_element);
   assert(s == 0);
   vc_dispmanx_update_submit_sync( dispman_update );
   s = vc_dispmanx_display_close(state->dispman_display);
   assert (s == 0);

   // Release OpenGL resources
   eglMakeCurrent( state->display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT );
#else
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glDeleteRenderbuffers(1, &state->canvasRenderBuffer);
    glDeleteFramebuffers(1, &state->canvasFrameBuffer);
#endif
   eglDestroyContext( state->display, state->context );
   eglTerminate( state->display );

   printf("\ncube closed\n");
}
