layout(location = 0) in vec3 a_position;

uniform mat4 mvp;

out vec2 v_textureCoord;

void main()
{
    v_textureCoord = a_position.xy;
    gl_Position = mvp * vec4(a_position, 1.0);
}
