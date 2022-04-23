#version 460 core

in vec2 fragmentTextureCoord;
out vec4 fragColor;

uniform sampler2D flake;

void main(void) {
    fragColor = texture(flake, fragmentTextureCoord);
    fragColor.xyz = vec3(1.0, 1.0, 1.0);
    // if (fragColor.x < 0.1) {
    //     fragColor = fragColor.w * vec4(1.0, 1.0, 1.0, 1.0);
    // }
}