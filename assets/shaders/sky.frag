precision mediump float;

in vec2 v_texCoords;

layout (location = 0) out vec4 colorOut;
#if BLOOM
layout (location = 1) out vec3 brightColor;
#endif

void main()
{
    colorOut = vec4(0.0f, 0.02f, 0.05f, 1);
    #if BLOOM
    brightColor = vec3(0);
    #endif
}