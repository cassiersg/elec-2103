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

#ifdef RPI
typedef struct
{
   uint32_t screen_width;
   uint32_t screen_height;
   DISPMANX_DISPLAY_HANDLE_T dispman_display;
   DISPMANX_ELEMENT_HANDLE_T dispman_element;
   EGLDisplay display;
   EGLSurface surface;
   EGLContext context;
} GLOBAL_GL_SCREEN_STATE;
static GLOBAL_GL_SCREEN_STATE _state, *state=&_state;
#endif

static void assertEGLError(const char *msg);

static void assertEGLError(const char *msg)
{
    EGLint error = eglGetError();
    if (error != EGL_SUCCESS) {
        printf("EGL error %s\n", msg);
        assert(0);
    }
}


#ifdef RPI

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
      EGL_DEPTH_SIZE, 16,
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
}

#else


#include  <X11/Xlib.h>
#include  <X11/Xatom.h>
#include  <X11/Xutil.h>

// X11 related local variables
static Display *x_display = NULL;

EGLBoolean CreateEGLContext( EGLNativeWindowType hWnd,
                              EGLint attribList[])
{
   EGLint numConfigs;
   EGLDisplay display;
   EGLContext context;
   EGLSurface surface;
   EGLConfig config;
   EGLint contextAttribs[] = { EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE, EGL_NONE };

   // Get Display
   display = eglGetDisplay((EGLNativeDisplayType)x_display);
   assert(display != EGL_NO_DISPLAY);
   // Initialize EGL
   assert(eglInitialize(display, NULL, NULL));
   // Get configs
   assert(eglGetConfigs(display, NULL, 0, &numConfigs));
   // Choose config
   assert(eglChooseConfig(display, attribList, &config, 1, &numConfigs));
   // Create a surface
   surface = eglCreateWindowSurface(display, config, (EGLNativeWindowType)hWnd, NULL);
   assert(surface != EGL_NO_SURFACE);
   // Create a GL context
   context = eglCreateContext(display, config, EGL_NO_CONTEXT, contextAttribs );
   assert(context != EGL_NO_CONTEXT);
   // Make the context current
   assert(eglMakeCurrent(display, surface, surface, context));
   
   return EGL_TRUE;
} 

EGLNativeWindowType WinCreate(int width, int height)
{
    XSetWindowAttributes swa;
    XSetWindowAttributes  xattr;
    XWMHints hints;
    XEvent xev;
    // X11 native display initialization
    x_display = XOpenDisplay(NULL);
    assert(x_display != NULL);
    Window root = DefaultRootWindow(x_display);
    swa.event_mask  =  ExposureMask | PointerMotionMask | KeyPressMask;
    Window win = XCreateWindow(
               x_display, root,
               0, 0, width, height, 0,
               CopyFromParent, InputOutput,
               CopyFromParent, CWEventMask,
               &swa);
    xattr.override_redirect = 0;
    XChangeWindowAttributes(x_display, win, CWOverrideRedirect, &xattr);
    hints.input = 1;
    hints.flags = InputHint;
    XSetWMHints(x_display, win, &hints);
    // make the window visible on the screen
    //XMapWindow (x_display, win);
    //XStoreName (x_display, win, "");
    // get identifiers for the provided atom name strings
    Atom wm_state = XInternAtom (x_display, "_NET_WM_STATE", 0);
    memset ( &xev, 0, sizeof(xev) );
    xev.type                 = ClientMessage;
    xev.xclient.window       = win;
    xev.xclient.message_type = wm_state;
    xev.xclient.format       = 32;
    xev.xclient.data.l[0]    = 1;
    xev.xclient.data.l[1]    = 0;
    XSendEvent (
       x_display,
       DefaultRootWindow ( x_display ),
       0,
       SubstructureNotifyMask,
       &xev );
    return (EGLNativeWindowType) win;
}

void platform_gl_init(int width, int height)
{
   EGLint attribList[] =
   {
       EGL_RED_SIZE,       5,
       EGL_GREEN_SIZE,     6,
       EGL_BLUE_SIZE,      5,
       EGL_ALPHA_SIZE,     EGL_DONT_CARE,
       EGL_DEPTH_SIZE,     8,
       EGL_STENCIL_SIZE,   EGL_DONT_CARE,
       EGL_SAMPLE_BUFFERS, 0,
       EGL_NONE
   };

   EGLNativeWindowType win = WinCreate(width, height);
  
   assert(CreateEGLContext(win, attribList));
}

#endif


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
   eglDestroyContext( state->display, state->context );
   eglTerminate( state->display );
#endif
}
