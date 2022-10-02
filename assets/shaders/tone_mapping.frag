precision mediump float;

in vec2 v_texCoords;
out vec4 colorOut;

uniform sampler2D hdrImage;
#if BLOOM
uniform sampler2D blurImage;
#endif
uniform float exposure;
uniform float canShootSince;
uniform vec2 screenSize;

vec3 standard(vec3 x)
{
    return vec3(1.0) - exp(-x * exposure);
}

void main()
{
    vec3 hdr = texture(hdrImage, v_texCoords).rgb;
    #if BLOOM
    hdr += texture(blurImage, v_texCoords).rgb;
    #endif
    // exposure tone mapping
    vec3 mapped = standard(hdr);

    colorOut = vec4(mapped, 1.0);
    // We must explicitly set alpha to 1.0 in WebGL, otherwise the screen becomes black.

    float cursorActive = pow(clamp((canShootSince * 4.0f) + 0.7f, 0.0f, 1.0f), 2.0f);
    float cursorSize = cursorActive * 20.0f;

    float distanceFromCursor = length((gl_FragCoord.xy) - vec2(0.5f * screenSize));

    if (distanceFromCursor < cursorSize && distanceFromCursor > cursorSize * 0.8f)
    {
        colorOut.rgb += vec3(cursorActive * min(cursorSize - distanceFromCursor, distanceFromCursor - cursorSize * 0.8f));
    }
}