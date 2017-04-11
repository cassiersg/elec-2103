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
#include "shaders.hpp"

#define GLM_FORCE_RADIANS
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#define SIZE_VEC(x) (sizeof((x))/sizeof((x)[0]))


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

typedef struct {
    GLuint program;
    GLint vertex_loc;
    GLint color_loc;
    GLint normal_loc;
    GLint VP_loc;
    GLint model_loc;
    GLint lightdir_loc;
    int width;
    int height;
} cubes_gl_data;

typedef struct {
    glm::vec3 lightdir;
    glm::mat4 VP;
} cubes_draw_settings;

cubes_gl_data init_cube_drawing(int width, int height)
{
    cubes_gl_data env;
    env.width = width;
    env.height = height;
   // Draw whatever you want here
   env.program = gen_program(vertex_shader_glsl, fragment_shader_glsl);
   assert(env.program);
    // Position attributes
    env.vertex_loc = glGetAttribLocation(env.program, "vPosition");
    env.color_loc = glGetAttribLocation(env.program, "color");
    env.normal_loc = glGetAttribLocation(env.program, "normal");
    env.VP_loc = glGetUniformLocation(env.program, "VP");
    env.model_loc = glGetUniformLocation(env.program, "model");
    env.lightdir_loc = glGetUniformLocation(env.program, "lightdir");


    // Enable depth test
    glEnable(GL_DEPTH_TEST);
    // Accept fragment if it closer to the camera than the former one
    glDepthFunc(GL_LESS); 

   // Set the viewport
   glViewport ( 0, 0, width, height );
   assertOpenGLError("glviewport");

   // Use the program object
   glUseProgram(env.program);
   assertOpenGLError("gluseprogram");

   // Load the vertex data
    glVertexAttribPointer(env.vertex_loc, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat),
           g_vertex_buffer_data);
    // Load normals
    glVertexAttribPointer(env.normal_loc, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat),
           g_vertex_buffer_data+3);
    // Enable/Disable attributes
    glEnableVertexAttribArray(env.vertex_loc);
    glEnableVertexAttribArray(env.normal_loc);
    glDisableVertexAttribArray(env.color_loc);

   return env;
}

void draw_cube(cubes_gl_data *env, cubes_draw_settings *params, glm::vec3 color, glm::mat4 model)
{
    // Set uniforms & attributes
    glUniformMatrix4fv(env->VP_loc, 1, GL_FALSE, glm::value_ptr(params->VP));
    glUniformMatrix4fv(env->model_loc, 1, GL_FALSE, glm::value_ptr(model));
    glUniform3fv(env->lightdir_loc, 1, glm::value_ptr(params->lightdir));
    glVertexAttrib3fv(env->color_loc, glm::value_ptr(color));

    glDrawArrays(GL_TRIANGLES, 0, 6*6);
}

void draw_cubes(cubes_gl_data *env)
{
    cubes_draw_settings params;
    params.lightdir = glm::vec3(0, 0.2, -1);
    // Projection matrix : 45° Field of View, 4:3 ratio, display range : 0.1 unit <-> 100 units
    glm::mat4 projection = glm::perspective(glm::radians(45.0f), 4.0f / 3.0f, 0.1f, 100.0f);
    // Camera matrix
    glm::mat4 view = glm::lookAt(
            glm::vec3(0,-2,10), // Camera is at (2,2,-5), in World Space
            glm::vec3(0,0,0), // and looks at the origin
            glm::vec3(0,1,0)  // Head is up (set to 0,-1,0 to look upside-down)
            );
    // Our ModelViewProjection : multiplication of our 3 matrices
    params.VP = projection * view;

    // reset background
    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glm::mat4 model = glm::mat4(1.0f);
    glm::vec3 color = glm::vec3(1.0f, 0.0f, 0.0f);
    draw_cube(env, &params, color, model);

    model = glm::translate(glm::mat4(1.0f), glm::vec3(3.0f, 0.0f, 0.0f));
    draw_cube(env, &params, color, model);

    model = glm::translate(glm::mat4(1.0f), glm::vec3(-3.0f, 0.0f, 0.0f));
    draw_cube(env, &params, color, model);
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

   cubes_gl_data env = init_cube_drawing(width, height);
   draw_cubes(&env);
   unsigned char *buf = glbuf2rgb(width, height);
   export_bmp((char *)"img.bmp", width, height, buf);
   free(buf);

   platform_gl_exit();
   return 0;
}
