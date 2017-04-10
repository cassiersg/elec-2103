#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <unistd.h>

#include "platform.h"
//#define GLEW_STATIC
//#include "glew.h"

#if RPI
#include "bcm_host.h"
#endif

#include "GLES/gl.h"
#include "GLES2/gl2.h"
#include "EGL/egl.h"
#include "EGL/eglext.h"

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#define SIZE_VEC(x) (sizeof((x))/sizeof((x)[0]))


#ifndef M_PI
   #define M_PI 3.141592654
#endif

#define check() assert(glGetError() == 0)

typedef struct
{
#if RPI
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

static void init_ogl(GLOBAL_GL_SCREEN_STATE *state, int width, int height);
static void exit_func(GLOBAL_GL_SCREEN_STATE *state);
static GLOBAL_GL_SCREEN_STATE _state, *state=&_state;

GLuint loadShader ( GLenum type, const char *shaderSrc );
GLuint gen_program(void);
void assertOpenGLError(const char *msg);
void export_bmp(char *fname, int width, int height, char* img);
void draw_uniform(int width, int height);
void draw_triangle(int width, int height);
void export_buffer(int width, int height);

// Create a shader object, load the shader source, and
// compile the shader.
GLuint loadShader ( GLenum type, const char *shaderSrc )
{
   GLuint shader;
   GLint compiled;
   
   // Create the shader object
   shader = glCreateShader ( type );

   if ( shader == 0 )
   	return 0;

   // Load the shader source
   glShaderSource ( shader, 1, &shaderSrc, NULL );
   
   // Compile the shader
   glCompileShader ( shader );

   // Check the compile status
   glGetShaderiv ( shader, GL_COMPILE_STATUS, &compiled );

   if ( !compiled ) 
   {
      GLint infoLen = 0;

      glGetShaderiv ( shader, GL_INFO_LOG_LENGTH, &infoLen );
      
      if ( infoLen > 1 )
      {
         char* infoLog = (char *) malloc (sizeof(char) * infoLen );

         glGetShaderInfoLog ( shader, infoLen, NULL, infoLog );
         printf( "Error compiling shader:\n%s\n", infoLog );            
         
         free ( infoLog );
      }

      glDeleteShader ( shader );
      return 0;
   }
   return shader;
}

// Initialize the shader and program object
GLuint gen_program(void)
{
   const char *vShaderStr =  
      "attribute vec3 vPosition;    \n"
      "attribute vec3 color;    \n"
      "attribute vec3 normal;    \n"
      "varying vec3 colorout;    \n"
      "uniform mat4 VP; \n"
      "uniform mat4 model; \n"
      "uniform vec3 lightdir; \n"
      "void main()                  \n"
      "{                            \n"
      "   gl_Position = VP*model*vec4(vPosition.xyz, 1.0);  \n"
      "   vec4 norm_local = model * vec4(normal, 0.0); \n"
      "   float diff = max(0.0, dot(normalize(normal.xyz), normalize(-lightdir)));\n"
      "   float c_light_coeff = 0.3; \n"
      "   colorout = 1.0/(1.0+c_light_coeff) * (c_light_coeff+diff) * color;\n"
      "}                            \n";
   
   const char *fShaderStr =  
      "precision mediump float;\n"
      "varying vec3 colorout;\n"
      "void main()                                  \n"
      "{                                            \n"
      //"  gl_FragColor = vec4 ( 1.0, 0.0, 0.0, 1.0 );\n"
      "  gl_FragColor = vec4 (colorout, 1.0 );\n"
      "}                                            \n";

   GLuint vertexShader;
   GLuint fragmentShader;
   GLuint programObject;
   GLint linked;

   // Load the vertex/fragment shaders
   vertexShader = loadShader ( GL_VERTEX_SHADER, vShaderStr );
   fragmentShader = loadShader ( GL_FRAGMENT_SHADER, fShaderStr );

   // Create the program object
   programObject = glCreateProgram ();
   
   if ( programObject == 0 )
   {
       printf("program object is 0\n");
       return 0;
   }

   glAttachShader ( programObject, vertexShader );
   glAttachShader ( programObject, fragmentShader );

   // Bind vPosition to attribute 0   
   glBindAttribLocation ( programObject, 0, "vPosition" );

   // Link the program
   glLinkProgram ( programObject );

   // Check the link status
   glGetProgramiv ( programObject, GL_LINK_STATUS, &linked );

   if ( !linked ) 
   {
      GLint infoLen = 0;
      glGetProgramiv ( programObject, GL_INFO_LOG_LENGTH, &infoLen );
      
      if ( infoLen > 1 )
      {
         char* infoLog = (char *) malloc (sizeof(char) * infoLen );
         glGetProgramInfoLog ( programObject, infoLen, NULL, infoLog );
         printf( "Error linking program:\n%s\n", infoLog );            
         free ( infoLog );
      }

      glDeleteProgram ( programObject );
      printf("Program not linked\n");
      return 0;
   }

   // Store the program object
   return programObject;
}

void assertEGLError(const char *msg) {
    EGLint error = eglGetError();
    if (error != EGL_SUCCESS) {
        printf("EGL error %s\n", msg);
        assert(0);
    }
}

void assertOpenGLError(const char *msg)
{
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        printf("EGL error %s, %x\n", msg, error);
        assert(0);
    }
}

void export_bmp(char *fname, int width, int height, unsigned char* img)
{
    FILE *f;
    int filesize = 54 + 3*width*height;
    unsigned char bmpfileheader[14] = {'B','M', 0,0,0,0, 0,0, 0,0, 54,0,0,0};
    unsigned char bmpinfoheader[40] = {40,0,0,0, 0,0,0,0, 0,0,0,0, 1,0, 24,0};
    unsigned char bmppad[3] = {0,0,0};

    bmpfileheader[ 2] = (unsigned char)(filesize    );
    bmpfileheader[ 3] = (unsigned char)(filesize>> 8);
    bmpfileheader[ 4] = (unsigned char)(filesize>>16);
    bmpfileheader[ 5] = (unsigned char)(filesize>>24);

    bmpinfoheader[ 4] = (unsigned char)(       width    );
    bmpinfoheader[ 5] = (unsigned char)(       width>> 8);
    bmpinfoheader[ 6] = (unsigned char)(       width>>16);
    bmpinfoheader[ 7] = (unsigned char)(       width>>24);
    bmpinfoheader[ 8] = (unsigned char)(       height    );
    bmpinfoheader[ 9] = (unsigned char)(       height>> 8);
    bmpinfoheader[10] = (unsigned char)(       height>>16);
    bmpinfoheader[11] = (unsigned char)(       height>>24);

    int i;
    for (i=0; i<width*height; i++) {
        char r = img[3*i+2];
        char b = img[3*i+0];
        img[3*i+2] = b;
        img[3*i+0] = r;
    }

    f = fopen("img.bmp","wb");
    fwrite(bmpfileheader,1,14,f);
    fwrite(bmpinfoheader,1,40,f);
    for(i=0; i<height; i++)
    {
        fwrite(img+(width*(height-i-1)*3),3,width,f);
        fwrite(bmppad,1,(4-(width*3)%4)%4,f);
    }
    fclose(f);

}
	
void draw_uniform(int width, int height)
{
    // Clear the target (optional)
    glClearColor(0.3f, 0.1f, 1.0f, 1.0f);
    assertOpenGLError("glClearColor");
    glClear(GL_COLOR_BUFFER_BIT);
    assertOpenGLError("glClear");
}

void draw_triangle(int width, int height)
{
   // Draw whatever you want here
   GLuint program = gen_program();
   assert(program);

    // Enable depth test
    glEnable(GL_DEPTH_TEST);
    // Accept fragment if it closer to the camera than the former one
    glDepthFunc(GL_LESS); 

   // Set the viewport
   glViewport ( 0, 0, width, height );
   assertOpenGLError("glviewport");

   // Our vertices. Tree consecutive floats give a 3D vertex; Three consecutive vertices give a triangle.
   // A cube has 6 faces with 2 triangles each, so this makes 6*2=12 triangles, and 12*3 vertices
   static const GLfloat g_vertex_buffer_data[] = { 
       // front
       -1.0f, 1.0f, 1.0f, 0.0f, 0.0f, 1.0f,
       -1.0f,-1.0f, 1.0f, 0.0f, 0.0f, 1.0f,
        1.0f,-1.0f, 1.0f, 0.0f, 0.0f, 1.0f,
        1.0f, 1.0f, 1.0f, 0.0f, 0.0f, 1.0f,
       -1.0f, 1.0f, 1.0f, 0.0f, 0.0f, 1.0f,
        1.0f,-1.0f, 1.0f, 0.0f, 0.0f, 1.0f,
        // back
        1.0f, 1.0f,-1.0f, 0.0f, 0.0f,-1.0f,
        1.0f,-1.0f,-1.0f, 0.0f, 0.0f,-1.0f,
       -1.0f,-1.0f,-1.0f, 0.0f, 0.0f,-1.0f,
        1.0f, 1.0f,-1.0f, 0.0f, 0.0f,-1.0f,
       -1.0f,-1.0f,-1.0f, 0.0f, 0.0f,-1.0f,
       -1.0f, 1.0f,-1.0f, 0.0f, 0.0f,-1.0f,
        // right
        1.0f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f,
        1.0f,-1.0f,-1.0f, 1.0f, 0.0f, 0.0f,
        1.0f, 1.0f,-1.0f, 1.0f, 0.0f, 0.0f,
        1.0f,-1.0f,-1.0f, 1.0f, 0.0f, 0.0f,
        1.0f, 1.0f, 1.0f, 1.0f, 0.0f, 0.0f,
        1.0f,-1.0f, 1.0f, 1.0f, 0.0f, 0.0f,
        // left
       -1.0f,-1.0f,-1.0f,-1.0f, 0.0f, 0.0f,
       -1.0f,-1.0f, 1.0f,-1.0f, 0.0f, 0.0f,
       -1.0f, 1.0f, 1.0f,-1.0f, 0.0f, 0.0f,
       -1.0f,-1.0f,-1.0f,-1.0f, 0.0f, 0.0f,
       -1.0f, 1.0f, 1.0f,-1.0f, 0.0f, 0.0f,
       -1.0f, 1.0f,-1.0f,-1.0f, 0.0f, 0.0f,
        // bottom
        1.0f,-1.0f, 1.0f, 0.0f,-1.0f, 0.0f,
       -1.0f,-1.0f,-1.0f, 0.0f,-1.0f, 0.0f,
        1.0f,-1.0f,-1.0f, 0.0f,-1.0f, 0.0f,
        1.0f,-1.0f, 1.0f, 0.0f,-1.0f, 0.0f,
       -1.0f,-1.0f, 1.0f, 0.0f,-1.0f, 0.0f,
       -1.0f,-1.0f,-1.0f, 0.0f,-1.0f, 0.0f,
       // up
        1.0f, 1.0f, 1.0f, 0.0f, 1.0f, 0.0f,
        1.0f, 1.0f,-1.0f, 0.0f, 1.0f, 0.0f,
       -1.0f, 1.0f,-1.0f, 0.0f, 1.0f, 0.0f,
        1.0f, 1.0f, 1.0f, 0.0f, 1.0f, 0.0f,
       -1.0f, 1.0f,-1.0f, 0.0f, 1.0f, 0.0f,
       -1.0f, 1.0f, 1.0f, 0.0f, 1.0f, 0.0f,
   };

   // One color for each vertex.
   static const GLfloat g_color_buffer_data[] = { 
       // front -- red
       1.0f, 0.0f, 0.0f,
       1.0f, 0.0f, 0.0f,
       1.0f, 0.0f, 0.0f,
       1.0f, 0.0f, 0.0f,
       1.0f, 0.0f, 0.0f,
       1.0f, 0.0f, 0.0f,
        // back -- green
       0.0f, 1.0f, 0.0f,
       0.0f, 1.0f, 0.0f,
       0.0f, 1.0f, 0.0f,
       0.0f, 1.0f, 0.0f,
       0.0f, 1.0f, 0.0f,
       0.0f, 1.0f, 0.0f,
        // right -- blue
       0.0f, 0.0f, 1.0f,
       0.0f, 0.0f, 1.0f,
       0.0f, 0.0f, 1.0f,
       0.0f, 0.0f, 1.0f,
       0.0f, 0.0f, 1.0f,
       0.0f, 0.0f, 1.0f,
       // left -- yellow
       1.0f, 1.0f, 0.0f,
       1.0f, 1.0f, 0.0f,
       1.0f, 1.0f, 0.0f,
       1.0f, 1.0f, 0.0f,
       1.0f, 1.0f, 0.0f,
       1.0f, 1.0f, 0.0f,
       // bottom -- purple
       1.0f, 0.0f, 1.0f,
       1.0f, 0.0f, 1.0f,
       1.0f, 0.0f, 1.0f,
       1.0f, 0.0f, 1.0f,
       1.0f, 0.0f, 1.0f,
       1.0f, 0.0f, 1.0f,
       // up -- 
       0.0f, 1.0f, 1.0f,
       0.0f, 1.0f, 1.0f,
       0.0f, 1.0f, 1.0f,
       0.0f, 1.0f, 1.0f,
       0.0f, 1.0f, 1.0f,
       0.0f, 1.0f, 1.0f,
   };
   GLfloat g_color_buffer_data_uniform[sizeof(g_color_buffer_data)];
   for (int i=0; i < SIZE_VEC(g_color_buffer_data_uniform)/3; i++) {
       g_color_buffer_data_uniform[3*i] =  1.0f;
       g_color_buffer_data_uniform[3*i+1] =  0.0f;
       g_color_buffer_data_uniform[3*i+2] =  0.0f;
   }

   // Projection matrix : 45° Field of View, 4:3 ratio, display range : 0.1 unit <-> 100 units
   glm::mat4 Projection = glm::perspective(glm::radians(45.0f), 4.0f / 3.0f, 0.1f, 100.0f);
   // Camera matrix
   glm::mat4 View       = glm::lookAt(
           glm::vec3(2,-2,5), // Camera is at (2,2,-5), in World Space
           glm::vec3(0,0,0), // and looks at the origin
           glm::vec3(0,1,0)  // Head is up (set to 0,-1,0 to look upside-down)
           );
   // Model matrix : an identity matrix (model will be at the origin)
   glm::mat4 Model      = glm::mat4(1.0f);
   // Our ModelViewProjection : multiplication of our 3 matrices
   glm::mat4 VP = Projection * View;

    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
   // Use the program object
   glUseProgram ( program);
   assertOpenGLError("gluseprogram");
   // Load the vertex data
    // Position attribute
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat),
           g_vertex_buffer_data);
    glEnableVertexAttribArray(0);
    assertOpenGLError("gl enable vertex attrix array");
    // Color attribute
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0,
            g_color_buffer_data_uniform);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat),
           g_vertex_buffer_data+3);
    glEnableVertexAttribArray(2);

    glm::vec3 lightdir = glm::vec3(0, 0.2, -1);

    // Get matrix's uniform location and set matrix
    GLint VPloc = glGetUniformLocation(program, "VP");
    glUniformMatrix4fv(VPloc, 1, GL_FALSE, glm::value_ptr(VP));
    GLint modelloc = glGetUniformLocation(program, "model");
    glUniformMatrix4fv(modelloc, 1, GL_FALSE, glm::value_ptr(Model));
    GLint lightdirloc = glGetUniformLocation(program, "lightdir");
    glUniform3fv(lightdirloc, 1, glm::value_ptr(lightdir));


    glDrawArrays(GL_TRIANGLES, 0, 6*6);



    /*
   glVertexAttribPointer ( 0, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat), vertices );
   assertOpenGLError("glvertexattrixpointer");
   glEnableVertexAttribArray ( 0 );
   assertOpenGLError("gl enable vertex attrix array");
   glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat), vertices );
   assertOpenGLError("glvertexattrixpointer");
   glEnableVertexAttribArray ( 1 );
   assertOpenGLError("gl enable vertex attrix array");
   glDrawArrays ( GL_TRIANGLES, 0, 6 );
   assertOpenGLError("gl draw arrays");
   */

}

void export_buffer(int width, int height)
{
    // Export
    unsigned char *buffer = (unsigned char*)malloc(width * height * 4);
    assert(buffer != NULL);
    unsigned char *buffer2= (unsigned char*)malloc(width * height * 3);
    assert(buffer2 != NULL);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    assertOpenGLError("glReadPixels");
    printf("it works %d\n", (int) *buffer);
    int i, j;
    for (i=0; i<width*height; i++) {
        for (j=0; j<3; j++) {
            buffer2[3*i+j] = buffer[4*i+j];
        }
       //printf("i: %i, v: %i, v: %i, v: %i, v: %i\n", i, buffer[4*i], buffer[4*i+1], buffer[4*i+2], buffer[4*i+3]);
   }
   export_bmp((char *)"test1.bmp", width, height, buffer2);
   free(buffer);
}


static void init_ogl(GLOBAL_GL_SCREEN_STATE *state, int width, int height)
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

   printf("01\n");

   // get an EGL display connection
   state->display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
   assert(state->display!=EGL_NO_DISPLAY);
   check();
   printf("02\n");

   // initialize the EGL display connection
   assert(eglInitialize(state->display, NULL, NULL) != EGL_FALSE);
   check();

   // get an appropriate EGL frame buffer configuration
   assert(eglChooseConfig(state->display, attribute_list, &config, 1, &num_configs) != EGL_FALSE);
   check();
   printf("03\n");

   // get an appropriate EGL frame buffer configuration
   assert(eglBindAPI(EGL_OPENGL_ES_API) != EGL_FALSE);
   check();

   // create an EGL rendering context
   state->context = eglCreateContext(state->display, config, EGL_NO_CONTEXT, context_attributes);
   assert(state->context!=EGL_NO_CONTEXT);
   printf("04\n");

#if RPI
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
   printf("05\n");

    // Create framebuffer
    glGenFramebuffers(1, &state->canvasFrameBuffer);
   printf("07\n");
    glBindFramebuffer(GL_FRAMEBUFFER, state->canvasFrameBuffer);
   printf("06\n");

    // Attach renderbuffer
    glGenRenderbuffers(1, &state->canvasRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, state->canvasRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA4, width, height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, state->canvasRenderBuffer);
    assertOpenGLError("framebuffer");
   printf("07\n");
#endif

   // Maybe not necessary (?)
   // Enable back face culling.
   glEnable(GL_CULL_FACE);
   //glMatrixMode(GL_MODELVIEW); // ??  works only on RPI
}

static void exit_func(GLOBAL_GL_SCREEN_STATE *state)
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

void draw_export(void)
{
   // Create framebuffer
   unsigned int width = 800, height = 480;
   unsigned int canvasFrameBuffer;
   glGenFramebuffers(1, &canvasFrameBuffer);
   assertOpenGLError("glgenframebuffers");
   glBindFramebuffer(GL_FRAMEBUFFER, canvasFrameBuffer);
   assertOpenGLError("glbindframebuffer");

   // Attach renderbuffer
   unsigned int canvasRenderBuffer;
   glGenRenderbuffers(1, &canvasRenderBuffer);
   assertOpenGLError("glgenrenderbuffers");
   glBindRenderbuffer(GL_RENDERBUFFER, canvasRenderBuffer);
   assertOpenGLError("glbindrenderbuffer");
   glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA4, width, height);
   assertOpenGLError("glrenderbufferstorage");
   glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER,
           canvasRenderBuffer);
   assertOpenGLError("glframebufferrenderbuffer");

   // Clear the target (optional)
   glClearColor(0.1f, 0.5f, 0.0f, 1.0f);
   assertOpenGLError("glclearcolor");
   glClear(GL_COLOR_BUFFER_BIT);
   assertOpenGLError("glclear");

   // Draw whatever you want here
   GLuint program = gen_program();
   assert(program);

   GLfloat vertices[] = {  0.0f,  0.5f, 0.0f,
                           -0.5f, -0.5f, 0.0f,
                            0.5f, -0.5f, 0.0f };

   // Set the viewport
   glViewport ( 0, 0, width, height );

   // Setup OpenGL options
   glEnable(GL_DEPTH_TEST);


   // Clear the color buffer
   glClear ( GL_COLOR_BUFFER_BIT );

   // Use the program object
   glUseProgram ( program);

   // Load the vertex data
   glVertexAttribPointer ( 0, 3, GL_FLOAT, GL_FALSE, 0, vertices );
   glEnableVertexAttribArray ( 0 );
   glDrawArrays ( GL_TRIANGLES, 0, 3 );

   export_buffer(width, height);
   /*
   // Export
   unsigned char *buffer = (char*)malloc(width * height * 4);
   assert(buffer != NULL);
   unsigned char *buffer2= (char*)malloc(width * height * 3);
   assert(buffer2 != NULL);
   glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
   assertOpenGLError("glReadPixels");
   printf("it works %d\n", (int) *buffer);
   int i, j;
   for (i=0; i<width*height; i++) {
       for (j=0; j<3; j++) {
           buffer2[3*i+j] = buffer[4*i+j];
       }
       //printf("i: %i, v: %i, v: %i, v: %i, v: %i\n", i, buffer[4*i], buffer[4*i+1], buffer[4*i+2], buffer[4*i+3]);
   }
   export_bmp("test1.bmp", width, height, buffer2);
   free(buffer);
   */

   // unbind frame buffer
   glBindRenderbuffer(GL_RENDERBUFFER, 0);
   glBindFramebuffer(GL_FRAMEBUFFER, 0);
   glDeleteRenderbuffers(1, &canvasRenderBuffer);
   glDeleteFramebuffers(1, &canvasFrameBuffer);
}

int main ()
{
    int width = 800;
    int height = 480;
#if RPI
   bcm_host_init();
#endif

   // Start OGLES
   printf("0\n");
   init_ogl(state, width, height);
   assert(glCreateProgram());
   printf("1\n");

   draw_triangle(width, height);
   export_buffer(width, height);
   //draw_export();

   exit_func(state);
   return 0;
}
