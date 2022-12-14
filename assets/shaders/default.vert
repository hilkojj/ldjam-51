precision mediump float;

layout(location = 0) in vec3 a_position;
layout(location = 1) in vec3 a_normal;
layout(location = 2) in vec3 a_tangent;
layout(location = 3) in vec2 a_textureCoord;

#ifdef INSTANCED

layout(location = 4) in mat4 transform;
uniform mat4 viewProjection;

#else
uniform mat4 mvp;
uniform mat4 transform;
#endif

uniform vec3 camPosition;

uniform float time;

#ifdef PORTAL_RENDER
uniform vec4 clipPlane;
out vec4 v_worldPosition;
#endif

out vec3 v_position;
out vec2 v_textureCoord;
out mat3 v_TBN;
#if FOG
out float v_fog;
#endif

#ifdef PORTAL_GUN_COLORED
out vec3 v_modelPosition;
#endif

#ifdef FAN_ROTATING
float rand(float x)
{
    return fract(sin(x) * 999.0f);
}


mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}
#endif

void main()
{
    #ifdef INSTANCED

    mat4 mvp = viewProjection * transform;

    #endif

    vec3 pos = a_position;

    #ifdef FAN_ROTATING

    pos = vec3(rotationMatrix(vec3(0, 0, 1), time * 0.5f * rand(float(gl_InstanceID)) + rand(float(gl_InstanceID)) * 340.0f) * vec4(pos, 1.0f));

    #endif


    #ifdef PORTAL_GUN_COLORED
    v_modelPosition = pos;
    #endif

    gl_Position = mvp * vec4(pos, 1.0);

    vec4 worldPosition = transform * vec4(pos, 1.0);
    v_position = vec3(worldPosition);
    v_textureCoord = a_textureCoord;

    mat3 dirTrans = mat3(transform);

    vec3 normal = normalize(dirTrans * a_normal);
    vec3 tangent = normalize(dirTrans * a_tangent);
    vec3 bitan = normalize(cross(normal, tangent)); // todo, is normalize needed?

    v_TBN = mat3(tangent, bitan, normal);
    #if FOG
    v_fog = 1. - max(0., min(1., (length(v_position - camPosition) - FOG_START) / (FOG_END - FOG_START)));
    #endif

    #ifdef PORTAL_RENDER
    /*
    #ifndef WEB_GL
    gl_ClipDistance[0] = -dot(worldPosition, clipPlane);
    #endif
    */
    v_worldPosition = worldPosition;
    #endif
}
