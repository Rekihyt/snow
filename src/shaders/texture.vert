#version 460 core

layout(location = 0) in vec3 position;
uniform int delta_t;
uniform mat4 mvp;

void main(void) { gl_Position = mvp * vec4(position, 1.0); }