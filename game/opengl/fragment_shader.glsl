
precision mediump float;
varying vec3 colorout;
varying vec2 texcoord;
varying float isfront;
uniform sampler2D outTexture;
uniform float usetexture;
void main()
{
  gl_FragColor = mix(vec4(colorout, 1.0 ), texture2D(outTexture, texcoord), usetexture*isfront);
}

