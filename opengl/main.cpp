#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <unistd.h>

#include "GLES/gl.h"
#include "GLES2/gl2.h"

#include "gl_platform.hpp"
#include "gl_utils.hpp"
#include "utils.hpp"

#define GLM_FORCE_RADIANS
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#define SIZE_VEC(x) (sizeof((x))/sizeof((x)[0]))

void draw_cube(int width, int height);

static const char *vertex_shader_src =  
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

static const char *fragment_shader_src =  
"precision mediump float;\n"
"varying vec3 colorout;\n"
"void main()                                  \n"
"{                                            \n"
//"  gl_FragColor = vec4 ( 1.0, 0.0, 0.0, 1.0 );\n"
"  gl_FragColor = vec4 (colorout, 1.0 );\n"
"}                                            \n";

void draw_cube(int width, int height)
{
   // Draw whatever you want here
   GLuint program = gen_program(vertex_shader_src, fragment_shader_src);
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
    GLint vertexloc = glGetAttribLocation(program, "vPosition");
    GLint colorloc = glGetAttribLocation(program, "color");
    GLint normalloc = glGetAttribLocation(program, "normal");
    glVertexAttribPointer(vertexloc, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat),
           g_vertex_buffer_data);
    glEnableVertexAttribArray(vertexloc);
    assertOpenGLError("gl enable vertex attrix array");
    // Color attribute
    glVertexAttribPointer(colorloc, 3, GL_FLOAT, GL_FALSE, 0,
            g_color_buffer_data_uniform);
    glEnableVertexAttribArray(colorloc);
    glVertexAttribPointer(normalloc, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat),
           g_vertex_buffer_data+3);
    glEnableVertexAttribArray(normalloc);

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

int main ()
{
    int width = 800;
    int height = 480;
#if RPI
   bcm_host_init();
#endif

   // Start OGLES
   platform_gl_init(width, height);
   assert(glCreateProgram());

   draw_cube(width, height);
   unsigned char *buf = glbuf2rgb(width, height);
   export_bmp((char *)"img.bmp", width, height, buf);
   free(buf);

   platform_gl_exit();
   return 0;
}
