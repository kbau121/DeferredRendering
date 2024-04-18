#version 330 core

uniform sampler2D u_TextureSSR;
uniform sampler2D u_Kernel;
uniform int u_KernelRadius;

in vec2 fs_UV;
layout (location = 0) out vec4 out_Col;

void main() {
    // TODO: Apply a Gaussian blur to the screen-space reflection
    // texture using the kernel stored in u_Kernel.
}
