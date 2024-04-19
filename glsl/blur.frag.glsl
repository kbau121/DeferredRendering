#version 330 core

uniform sampler2D u_TextureSSR;
uniform sampler2D u_Kernel;
uniform int u_KernelRadius;

in vec2 fs_UV;
layout (location = 0) out vec4 out_Col;

vec2 screenToPixel(vec2 screenPos, vec2 screenSize)
{
    return vec2(((screenPos.x + 1.f) / 2.f) * screenSize.x,
                ((1.f - screenPos.y) / 2.f) * screenSize.y);
}

vec2 pixelToScreen(vec2 pixelPos, vec2 screenSize)
{
    return vec2((pixelPos.x / screenSize.x) * 2.f - 1.f,
                1.f - (pixelPos.y / screenSize.y) * 2.f);
}

void main() {
    // Apply a Gaussian blur to the screen-space reflection
    // texture using the kernel stored in u_Kernel.
    vec2 screenSize = textureSize(u_TextureSSR, 0);
    vec2 pixelPos = screenToPixel(fs_UV, screenSize);

    int kernelWidth = 2 * u_KernelRadius + 1;
    for (int i = -u_KernelRadius; i <= u_KernelRadius; ++i)
    {
        for (int j = -u_KernelRadius; j <= u_KernelRadius; ++j)
        {
            vec2 sourcePixelPos = pixelPos + vec2(j, i) + vec2(0.5f);
            vec2 sourceUV = pixelToScreen(sourcePixelPos, screenSize);

            vec2 gaussianUV = (vec2(j + u_KernelRadius, i + u_KernelRadius) + vec2(0.5f)) / kernelWidth;

            // SSR * kernel_weight
            out_Col += texture(u_TextureSSR, sourceUV) * texture(u_Kernel, gaussianUV).r;
        }
    }
}
