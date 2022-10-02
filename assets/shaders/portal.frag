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
uniform vec3 portalColor;
uniform float portalTime;
// --------------------------------------------


vec2 hash(vec2 p)
{
    p = vec2(dot(p, vec2(376.0f, 238.0f)), dot(p, vec2(324.0f, 983.0f)));
    return -1.0f + 2.0f * vec2(fract(sin(p) * 365.0f));
}

float noise(in vec2 p)
{
    const float K1 = 0.366025404f; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865f; // (3-sqrt(3))/6;

    vec2 i = floor(p + (p.x + p.y) * K1);

    vec2 a = p - i + (i.x + i.y) * K2;
    vec2 o = (a.x > a.y) ? vec2(1.0f, 0.0f) : vec2(0.0f, 1.0f);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0f + 2.0f * K2;

    vec3 h = max(0.5f - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0f);

    vec3 n = h * h * h * h * vec3(dot(a, hash(i)), dot(b, hash(i + o)), dot(c, hash(i + 1.0f)));

    return dot(n, vec3(80.0f));
}

float fireNoise(vec2 coords, float t)
{
    coords.y -= t * 2.0f;
    float f = 0.5f * noise(coords);
    coords *= 2.0f;
    coords.y -= t * 1.0f;
    f += 0.5f * noise(coords);
    coords *= 2.0f;
    coords.x += t * 5.0f;
    coords.y -= t * 0.5f;
    f += 0.25f * noise(coords);
    f = 0.5f + 0.5f * f;
    return f;
}

mat2 rotate(float angle)
{
    return mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
}

float rand(float x)
{
    return fract(sin(x) * 999.0f);
}

vec2 pmod(vec2 p, float x)
{
    return mod(p, x) - 0.5 * x;
}

float twist(vec2 uv)
{
    uv *= 0.25f;
    float t = portalTime;

    float result = 0.0f;
    float th = atan(uv.y,uv.x);

    vec2 uv2 = uv + 1.0f;
    vec2 uv3 = uv;
    uv = pmod(uv, 5.0f);
    uv *= rotate(t * 3.5f);

    result += 1.0f * smoothstep(uv.y - 0.1f, uv.y + 0.4f, 0.1f) * 0.5f * step(length(uv), 5.5f)
            * pow(clamp((2.5f - length(uv)), 0.0f, 1.0f), 6.0f);

    result += 0.45f * smoothstep(uv.y - 0.1f, uv.y + 0.1f, -0.5f) * 0.9f * step(length(uv), 5.5f)
            * max(0.0f, (1.4f - length(uv)));
    uv = uv2;

    uv *= 10.0f;
    uv = pmod(uv, 4.0f);
    uv *= rotate(-t * 3.5f);
    uv *= rotate(length(uv * 5.0f));

    result += smoothstep(uv.y - 0.1f, uv.y + 0.4f, 0.1f) * 0.5f * step(length(uv), 5.5f)
            * pow(clamp((2.5f - length(uv)), 0.0f, 1.0f), 6.0f);

    result += 0.45f * smoothstep(uv.y - 0.1f, uv.y + 0.1f, -0.5f) * 0.9f * step(length(uv), 5.5f)
            * max(0.0f, (1.4f - length(uv)));

    result *= step(abs(uv3.x), 0.365);
    return result;
}


void main()
{
    vec2 fireUV = (v_textureCoord) * 10.0f;

    float fireIntensity = 1.0f;
    fireIntensity *= 0.3f + pow(fireNoise(vec2(fireUV.x * 0.1f, fireUV.y * 0.03f), portalTime * 0.2f), 2.0f) * 0.7f;

    float secondFireIntensity = (0.7f + pow(fireNoise(vec2(fireUV.x * 0.3f, -fireUV.y * 0.3f), portalTime * 0.8f), 2.0f) * 0.7f);

    vec2 el = v_textureCoord
        * max(1.0f, pow(clamp(1.0f - portalTime * 10.0f, 0.0f, 1.0f), 2.0f) * 4.0f);   // opening animation

    float elLen = length(el) + fireIntensity * 0.08f;
    if (elLen > 1.0f)
    {
        discard;
    }

    colorOut.rgb = portalColor;

    colorOut.a = 1.0f;//twist(v_textureCoord);

    float portalTextureFactor = (1.0f - elLen) * 1.0f;
    portalTextureFactor += fireIntensity;
    portalTextureFactor -= secondFireIntensity
        * twist(v_textureCoord + vec2(fireIntensity * 0.2f - 0.1f, secondFireIntensity * 0.2f - 0.1f));

    portalTextureFactor = clamp(portalTextureFactor, 0.0f, 1.0f);

    //colorOut = vec4(vec3(portalTextureFactor), 1.0f);


    #if BLOOM
    brightColor = vec4(portalColor * 20.0f * pow(clamp(elLen * 1.5f - 0.5f, 0.0f, 1.0f), 7.0f), 1.2f - portalTextureFactor);
    #endif


    if (hasPortalTexture == 1)
    {
        colorOut.rgb = mix(colorOut.rgb, texture(portalTexture, gl_FragCoord.xy / screenSize).rgb, portalTextureFactor);
        //colorOut.rgb = texture(portalTexture, gl_FragCoord.xy / screenSize).rgb - colorOut.rgb * (1.0f - portalTextureFactor);
    }
    else
    {

    }
}

