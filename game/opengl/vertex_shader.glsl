
attribute vec3 vPosition;
attribute vec3 color;
attribute vec3 normal;
varying vec3 colorout;
uniform mat4 VP;
uniform mat4 model;
uniform vec3 lightdir;
void main()
{
    gl_Position = VP*model*vec4(vPosition.xyz, 1.0);
    vec4 norm_local = model * vec4(normal, 0.0);
    float diff = max(0.0, dot(normalize(normal.xyz), normalize(-lightdir)));
    float c_light_coeff = 0.3;
    colorout = 1.0/(1.0+c_light_coeff) * (c_light_coeff+diff) * color;
}

