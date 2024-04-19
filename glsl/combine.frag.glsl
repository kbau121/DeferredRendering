#version 330 core

// [0] is the specular reflection.
// [4] is the diffuse reflection.
// [1][2][3] are intermediate levels of glossy reflection.
uniform sampler2D u_TexSSR[5];

uniform sampler2D u_TexPositionWorld;
uniform sampler2D u_TexNormal;
uniform sampler2D u_TexAlbedo;
uniform sampler2D u_TexMetalRoughMask;

uniform samplerCube u_DiffuseIrradianceMap;
uniform samplerCube u_GlossyIrradianceMap;
uniform sampler2D u_BRDFLookupTexture;

uniform vec3 u_CamPos;

in vec2 fs_UV;

out vec4 out_Col;

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

vec3 computeLTE(vec3 pos, vec3 N,
                vec3 albedo, float metallic, float roughness,
                vec3 wo,
                vec4 Li_Diffuse,
                vec4 Li_Glossy) {
    // TODO: Implement this based on your PBR shader code.
    // Don't apply the Reinhard operator or gamma correction;
    // they should be applied at the end of main().

    // When you evaluate the Diffuse BSDF portion of your LTE,
    // the Li term should be a LERP between Li_Diffuse and the
    // color in u_DiffuseIrradianceMap based on the alpha value
    // of Li_Diffuse.

    // Likewise, your Microfacet BSDF portion's Li will be a mix
    // of Li_Glossy and u_GlossyIrradianceMap's color based on
    // Li_Glossy.a

    // Everything else will be the same as in the code you
    // wrote for the previous assignment.

    vec3 R = mix(vec3(0.04f), albedo, metallic);
    vec3 F = fresnelRoughness(max(dot(N, wo), 0.f), R, roughness);

    // Cook-Torrence weights
    vec3 ks = F;
    vec3 kd = 1.f - ks;
    kd *= 1.f - metallic;

    // Diffuse color
    vec3 diffuseIrradiance = mix(texture(u_DiffuseIrradianceMap, N).rgb, Li_Diffuse.rgb, Li_Diffuse.a);
    vec3 diffuse = albedo * diffuseIrradiance;

    // Sample the glossy irradiance map
    vec3 wi = reflect(-wo, N);
    const float MAX_REFLECTION_LOD = 4.f;
    vec3 prefilteredColor = mix(textureLod(u_GlossyIrradianceMap, wi, roughness * MAX_REFLECTION_LOD).rgb, Li_Glossy.rgb, Li_Glossy.a);

    // Specular color
    vec2 envBRDF = texture(u_BRDFLookupTexture, vec2(max(dot(N, wo), 0.f), roughness)).rg;
    vec3 specular = prefilteredColor * (F * envBRDF.x + envBRDF.y);

    // Ambient color
    vec3 ambient = 0.03f * albedo;

    // Cook-Torrence lighting
    vec3 Lo = ambient + kd * diffuse + specular;

    return Lo;
}

void main() {
    // TODO: Combine all G-buffer textures into your final
    // output color. Compared to the environment-mapped
    // PBR shader, you will have two additional Li terms.

    // One represents your diffuse screen reflections, sampled
    // from the last index in the u_TexSSR sampler2D array.

    // The other represents your glossy screen reflections,
    // interpolated between two levels of glossy reflection stored
    // in the lower indices of u_TexSSR. Your interpolation t will
    // be dependent on your roughness.
    // For example, if your roughness were 0.1, then your glossy
    // screen-space reflected color would be:
    // mix(u_TexSSR[0], u_TexSSR[1], fract(0.1 * 4))
    // If roughness were 0.9, then your color would be:
    // mix(u_TexSSR[2], u_TexSSR[3], fract(0.9 * 4))

    vec3 N = texture(u_TexNormal, fs_UV).xyz;
    if (N == vec3(0.f)) return; // No object was hit

    vec3 pos = texture(u_TexPositionWorld, fs_UV).xyz;
    vec3 albedo = texture(u_TexAlbedo, fs_UV).rgb;
    float metallic = texture(u_TexMetalRoughMask, fs_UV).x;
    float roughness = texture(u_TexMetalRoughMask, fs_UV).y;
    vec3 wo = normalize(u_CamPos - pos);
    vec4 Li_Diffuse = vec4(0.f);
    vec4 Li_Glossy = vec4(0.f);

    // Compute the PBR light
    vec3 Lo = computeLTE(pos, N, albedo, metallic, roughness, wo, Li_Diffuse, Li_Glossy);

    // Compute the screen space reflection specular roughness
    float SSR_ind = roughness * 4;
    int SSR_level = int(SSR_ind);
    float SSR_mix = fract(SSR_ind);

    vec4 SSR = mix(
                texture(u_TexSSR[SSR_level], fs_UV),
                texture(u_TexSSR[SSR_level + 1], fs_UV),
                SSR_mix
            );

    // Add the screen space reflection contribution to the image
    Lo = mix(Lo, SSR.rgb, SSR.a);

    // Tone-mapping
    Lo = reinhard(Lo);
    Lo = gammaCorrect(Lo);

    out_Col = vec4(Lo, 1.f);
}
