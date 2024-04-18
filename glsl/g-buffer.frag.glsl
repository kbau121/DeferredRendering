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

const float PI = 3.14159f;

// Schlick's fresnel approximation accounting for roughness
vec3 fresnelRoughness(float cosViewAngle, vec3 R, float roughness)
{
    return R + (max(vec3(1.f - roughness), R) - R) * pow(max(1.f - cosViewAngle, 0.f), 5.f);
}

// Reinhard operator tone mapping
vec3 reinhard(vec3 in_Col)
{
    return in_Col / (vec3(1.f) + in_Col);
}

// Gamma correction
vec3 gammaCorrect(vec3 in_Col)
{
    return pow(in_Col, vec3(1.f / 2.2f));
}

// Calculates a PBR material
vec3 computePBR(vec3 N, vec3 albedo, float metallic, float roughness, vec3 wo)
{
    vec3 R = mix(vec3(0.04f), albedo, metallic);
    vec3 F = fresnelRoughness(max(dot(N, wo), 0.f), R, roughness);

    // Cook-Torrence weights
    vec3 ks = F;
    vec3 kd = 1.f - ks;
    kd *= 1.f - metallic;

    // Diffuse color
    vec3 diffuseIrradiance = texture(u_DiffuseIrradianceMap, N).rgb;
    vec3 diffuse = albedo * diffuseIrradiance;

    // Sample the glossy irradiance map
    vec3 wi = reflect(-wo, N);
    const float MAX_REFLECTION_LOD = 4.f;
    vec3 prefilteredColor = textureLod(u_GlossyIrradianceMap, wi, roughness * MAX_REFLECTION_LOD).rgb;

    // Specular color
    vec2 envBRDF = texture(u_BRDFLookupTexture, vec2(max(dot(N, wo), 0.f), roughness)).rg;
    vec3 specular = prefilteredColor * (F * envBRDF.x + envBRDF.y);

    // Ambient color
    vec3 ambient = 0.03f * albedo;

    // Cook-Torrence lighting
    vec3 Lo = ambient + kd * diffuse + specular;

    // Tone mapping
    Lo = reinhard(Lo);
    Lo = gammaCorrect(Lo);

    return Lo;
}

void main()
{
    // Writes the appropriate values into each of the
    // out variables in this shader so that the G-buffer
    // can save each of them in a texture.
    gb_WorldSpacePosition = vec4(fs_Pos, 1.f);
    gb_Normal = vec4(fs_Nor, 0.f);
    gb_Albedo = texture(u_AlbedoTexture, fs_UV).rgb;
    gb_Metal_Rough_Mask = vec3(texture(u_MetallicTexture, fs_UV).x, texture(u_RoughnessTexture, fs_UV).y, 0.f);

    vec3 wo = normalize(u_CamPos - fs_Pos);
    gb_PBR = computePBR(fs_Nor, gb_Albedo, gb_Metal_Rough_Mask.x, gb_Metal_Rough_Mask.y, wo);
}
