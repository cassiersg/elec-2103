#include "gl_utils.hpp"

#include <stdlib.h>
#include <assert.h>
#include <stdio.h>

void assertOpenGLError(const char *msg)
{
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        printf("openGL error %s, %x\n", msg, error);
        assert(0);
    }
}

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
GLuint gen_program(const char* vertex_shader_src, const char* fragment_shader_src)
{
   GLuint vertexShader;
   GLuint fragmentShader;
   GLuint programObject;
   GLint linked;

   // Load the vertex/fragment shaders
   vertexShader = loadShader ( GL_VERTEX_SHADER, vertex_shader_src);
   fragmentShader = loadShader ( GL_FRAGMENT_SHADER, fragment_shader_src);

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

void glbuf2rgb(unsigned char *buffer, int width, int height)
{
    unsigned char *buf2 = (unsigned char*)malloc(width * height * 4);
    assert(buf2 != NULL);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, buf2);
    assertOpenGLError("glReadPixels");
    // pack pixels to remove Alpha of RGBA
    for (int i=0; i<width*height; i++) {
        for (int j=0; j<3; j++) {
            buffer[3*i+j] = buf2[4*i+j];
        }
    }
    free(buf2);
}

