precision mediump float;

#if FOG
in float v_fog;
#endif

in vec2 v_textureCoord;

layout (location = 0) out vec4 colorOut;
#if BLOOM
layout (location = 1) out vec4 brightColor;
#endif

uniform sampler2D portalTexture;
uniform int hasPortalTexture;
uniform vec2 screenSize;
// --------------------------------------------

void main()
{
    if (hasPortalTexture == 1)
    {
        colorOut = texture(portalTexture, gl_FragCoord.xy / screenSize);
        #if BLOOM
        brightColor = vec4(0.0f);
        #endif
    }
    else
    {
        colorOut = vec4(1.0f);

        #if BLOOM
        brightColor = vec4(1.0f);
        #endif
    }

}

