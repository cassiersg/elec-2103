#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <unistd.h>

#include "GLES2/gl2.h"

#include "cubes.hpp"

#include "gl_platform.hpp"
#include "gl_utils.hpp"
#include "utils.hpp"
#include "shaders.hpp"
#include "compression.hpp"

#define GLM_FORCE_RADIANS
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#define SIZE_VEC(x) (sizeof((x))/sizeof((x)[0]))

#define ROUND_GAUGE_INIT 65535

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
} cubes_gl_data;
cubes_gl_data env;

typedef struct {
    glm::vec3 lightdir;
    glm::mat4 VP;
} cubes_draw_settings;

static void program_gl_config(void)
{
   env.program = gen_program(vertex_shader_glsl, fragment_shader_glsl);
   assert(env.program);
    // Position attributes
    env.vertex_loc = glGetAttribLocation(env.program, "vPosition");
    env.color_loc = glGetAttribLocation(env.program, "color");
    env.normal_loc = glGetAttribLocation(env.program, "normal");
    env.VP_loc = glGetUniformLocation(env.program, "VP");
    env.model_loc = glGetUniformLocation(env.program, "model");
    env.lightdir_loc = glGetUniformLocation(env.program, "lightdir");

   // Set the viewport
   glViewport ( 0, 0, width, height );
   assertOpenGLError("glviewport");

   // Use the program object
   glUseProgram(env.program);
   assertOpenGLError("gluseprogram");

    // Enable depth test
    glEnable(GL_DEPTH_TEST);
    glDepthMask(GL_TRUE);
    // Accept fragment if it closer to the camera than the former one
    glDepthFunc(GL_LESS); 
   assertOpenGLError("gldepth");

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
}

static void draw_cube(cubes_draw_settings *params, glm::vec3 color, glm::mat4 model)
{
    // Set uniforms & attributes
    glUniformMatrix4fv(env.VP_loc, 1, GL_FALSE, glm::value_ptr(params->VP));
    glUniformMatrix4fv(env.model_loc, 1, GL_FALSE, glm::value_ptr(model));
    glUniform3fv(env.lightdir_loc, 1, glm::value_ptr(params->lightdir));
    glVertexAttrib3fv(env.color_loc, glm::value_ptr(color));

    glDrawArrays(GL_TRIANGLES, 0, 6*6);
}

static void draw_cube_grid(cubes_draw_settings *params, glm::vec3 color, int i, int j, float z)
{
    glm::mat4 model = glm::mat4(1.0f); // identity matrix
    model = glm::translate(model, glm::vec3(j*2.0f, i*-2.0f, z));
    draw_cube(params, color, model);
}

void draw_cubes(
        unsigned char *grid, int grid_size,
        int n, int m,
        int p1x, int p1y, int p2x, int p2y,
        int player_id,
        int round_gauge,
        unsigned int wall_color)
{
    float wfr = (float) (0xFF & (wall_color >> 16)) / 255.0;
    float wfg = (float) (0xFF & (wall_color >> 8)) / 255.0;
    float wfb = (float) (0xFF & wall_color) / 255.0;
    glm::vec3 wall_color_float = glm::vec3(wfr, wfg, wfb);
    cubes_draw_settings params;
    params.lightdir = glm::vec3(0, 0.5, -1);
    // Projection matrix : 45° Field of View, 4:3 ratio, display range : 0.1 unit <-> 100 units
    glm::mat4 projection = glm::perspective(glm::radians(45.0f), 4.0f / 3.0f, 1.0f, 100.0f);
    // Camera matrix
    glm::mat4 view = glm::lookAt(
            glm::vec3(m-1, -1.5*n, 30), // position of camera in world space
            glm::vec3(m-1,-1*n,0), // and looks at ...
            glm::vec3(0,1,0)  // Head is up (set to 0,-1,0 to look upside-down)
            );
    // Combined view-projection operator
    params.VP = projection * view;

    // reset background
    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    for (int i=0; i < n; i++) {
        for (int j=0; j < m; j++) {
            char kind = grid[i*m+j];
            glm::vec3 color;
            float z_offset = 0.0f;
            if (kind == 0) {
                // struct, gray
                color = glm::vec3(0.5f, 0.5f, 0.5f);
            } else if (kind == 3) {
                // wall
                color = wall_color_float;
                z_offset = -50.0f * (float) round_gauge / (float) ROUND_GAUGE_INIT;
            } else if (kind == 4) {
                // HOLE, do nothing
                continue;
            } else {
                printf("invalid cube kind: %i (at (%i, %i))\n", kind, i, j);
                assert(0);
            }
            draw_cube_grid(&params, color, i, j, z_offset);
        }
    }
    glm::vec3 color;
    glm::vec3 color_p1 = glm::vec3(1.0f, 0.0f, 0.0f);
    glm::vec3 color_p2 = glm::vec3(1.0f, 1.0f, 0.0f);
    draw_cube_grid(&params, color_p1, p1y, p1x, 0.0f);
    draw_cube_grid(&params, color_p2, p2y, p2x, 0.0f);
}


void cubes_init()
{
#if RPI
   bcm_host_init();
#endif
   // Start OGLES
   platform_gl_init(width, height);
   // Set global env & gl view
   program_gl_config();
}

void cubes_exit(void)
{
    platform_gl_exit();
}

void cubes_image_export(unsigned char *buf, int buf_size)
{
    assert(buf_size >= 4*width*height);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, buf);
    assertOpenGLError("glReadPixels");
    unsigned int *pixel_buf = (unsigned int *) buf;
    for (int i=0; i<width*height; i++) {
        unsigned int pixel = pixel_buf[i];
        unsigned char r = pixel;
        unsigned char g = pixel >> 8;
        unsigned char b = pixel >> 16;
        pixel_buf[i] = 0xff000000 | (r << 16) | (g << 8) | (b);
    }
}


