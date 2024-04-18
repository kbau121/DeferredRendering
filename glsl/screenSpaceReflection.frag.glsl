#version 330 core

uniform samplerCube u_DiffuseIrradianceMap;
uniform samplerCube u_GlossyIrradianceMap;
uniform sampler2D u_BRDFLookupTexture;

uniform sampler2D u_TexPositionWorld;
uniform sampler2D u_TexNormal;
uniform sampler2D u_TexAlbedo;
uniform sampler2D u_TexMetalRoughMask;
uniform sampler2D u_TexPBR;

uniform vec3 u_CamPos;
uniform vec3 u_CamForward;
uniform mat4 u_View;
uniform mat4 u_Proj;

in vec2 fs_UV;

const float PI = 3.14159f;

layout (location = 0) out vec4 gb_Reflection;

void main() {
    // TODO: Compute the screen-space reflection of the scene
    // stored in the G-buffer, represented by the sampler2Ds

    // We recommend using helper functions to make your code
    // easier to read.
}
