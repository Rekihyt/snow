#version 460 core

layout(points) in;
layout(triangle_strip, max_vertices = 4) out;

out vec2 fragmentTextureCoord;

uniform int delta_t;
uniform int time;
// uniform mat4 rotation;
uniform mat4 mvp;

// Credit:
// https://github.com/mattatz/ShibuyaCrowd/blob/master/source/shaders/common/quaternion.glsl
vec4 quaternionMul(vec4 q1, vec4 q2) {
    return vec4(q2.xyz * q1.w + q1.xyz * q2.w + cross(q1.xyz, q2.xyz),
                q1.w * q2.w - dot(q1.xyz, q2.xyz));
}
vec3 rotate_vector(vec3 vec, vec4 rotation) {
    vec4 rotation_conj = rotation * vec4(-1, -1, -1, 1);
    return quaternionMul(rotation, quaternionMul(vec4(vec, 0), rotation_conj))
        .xyz;
}

void main() {
    float size = 0.005;
    vec4 pos = gl_in[0].gl_Position;
    float period = 8;
    float amount = period * (pos.x + pos.y + pos.z) / 2;
    vec4 rotation = vec4(0, 0, sin(amount), cos(amount));
    // vec4 rotation = vec4(0, 1, 1, 1);
    gl_Position = pos;
    gl_Position +=
        mvp * vec4(rotate_vector((vec3(-size, size, 0)), rotation), 0);
    fragmentTextureCoord = vec2(0.0, 0.0);
    EmitVertex();

    gl_Position = pos;
    gl_Position +=
        mvp * vec4(rotate_vector((vec3(-size, -size, 0)), rotation), 0);
    fragmentTextureCoord = vec2(0.0, 1.0);
    EmitVertex();

    gl_Position = pos;
    gl_Position +=
        mvp * vec4(rotate_vector((vec3(size, size, 0)), rotation), 0);
    fragmentTextureCoord = vec2(1.0, 0.0);
    EmitVertex();

    gl_Position = pos;
    gl_Position +=
        mvp * vec4(rotate_vector((vec3(size, -size, 0)), rotation), 0);
    fragmentTextureCoord = vec2(1.0, 1.0);
    EmitVertex();

    EndPrimitive();
}