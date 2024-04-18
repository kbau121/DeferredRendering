#version 330 core

uniform sampler2D u_AlbedoTexture;
uniform sampler2D u_MetallicTexture;
uniform sampler2D u_RoughnessTexture;

// Image-based lighting (only used if computing PBR reflection here)
uniform samplerCube u_DiffuseIrradianceMap;
uniform samplerCube u_GlossyIrradianceMap;
uniform sampler2D u_BRDFLookupTexture;

in vec3 fs_Pos;
in vec3 fs_Nor;
in vec2 fs_UV;

layout (location = 0) out vec4 gb_WorldSpacePosition;
layout (location = 1) out vec4 gb_Normal;
layout (location = 2) out vec3 gb_Albedo;
// R channel is metallic, G channel is roughness, B channel is mask
layout (location = 3) out vec3 gb_Metal_Rough_Mask;
layout (location = 4) out vec3 gb_PBR; // Optional

uniform vec3 u_CamPos;

void main()
{
    // TODO: Write the appropriate values into each of the
    // out variables in this shader so that the G-buffer
    // can save each of them in a texture.
}
