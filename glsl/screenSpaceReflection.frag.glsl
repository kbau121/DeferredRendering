#version 330 core

#define epsilon 0.1f
#define maxDistance 20.f
#define isectTolerance 0.5f
#define startFade 15.f
#define stepSize 0.1f

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

// Takes a world space coordinate into camera space
vec3 worldToCamera(vec4 worldPos)
{
    return (u_View * worldPos).xyz;
}

// Takes a world space coordinate into screen space
vec3 worldToScreen(vec4 worldPos)
{
    vec4 unhomogenizedScreenPos = u_Proj * u_View * worldPos;
    return unhomogenizedScreenPos.xyz / unhomogenizedScreenPos.w;
}

// Finds the UV coordinate at a world space coordinate, relative to the camera
vec2 worldToUV(vec4 worldPos)
{
    vec3 screenPos = worldToScreen(worldPos);
    return (screenPos.xy + vec2(1.f)) * 0.5f;
}

// Checks the bounds of a UV
bool isValidUV(vec2 UV)
{
    return  0.f <= UV.x && UV.x <= 1.f &&
            0.f <= UV.y && UV.y <= 1.f;
}

void main() {
    vec2 screenSize = textureSize(u_TexPBR, 0);

    // Calculate the reflected ray
    vec3 worldPos = texture(u_TexPositionWorld, fs_UV).xyz;
    vec3 normal = texture(u_TexNormal, fs_UV).xyz;
    vec3 wo = normalize(worldPos - u_CamPos);
    vec3 wi = reflect(wo, normal);

    // Find the start and end points for ray marching
    vec3 startMarchWorld = worldPos.xyz + (normal * epsilon);
    vec3 endMarchWorld = worldPos.xyz + (wi * maxDistance);

    // Find the amount to step each ray march and the maximum number of steps
    vec3 delta = wi * stepSize;
    int maxDepth = int(ceil(maxDistance / stepSize));

    // Initialize loop outputs
    vec2 marchUV = worldToUV(vec4(startMarchWorld, 1.f)).xy;    // UV coordinates of GBuffer data
    vec3 marchWorld = startMarchWorld;                          // World space coordinates of ray march
    bool doIntersect = false;                                   // Whether the ray has intersected something
    float t;                                                    // Distance along the ray something was intersected
    float isectOffset;                                          // Distance from the GBuffer's stored position
    int depth;                                                  // How many steps it took to find an intersection

    for (depth = 1; depth <= maxDepth; ++depth)
    {
        // Remove out of bound rays
        if (!isValidUV(marchUV))
        {
            break;
        }

        // Check for an intersection at the current pixel with the GBuffer
        vec3 samplePos = texture(u_TexPositionWorld, marchUV).xyz;
        isectOffset = dot(-u_CamForward, samplePos - marchWorld);
        if (isectOffset > 0.f && isectOffset < isectTolerance)
        {
            if (dot(-u_CamForward, texture(u_TexNormal, marchUV).xyz) > 0.f)
            {
                t = length(marchWorld - startMarchWorld) / length(endMarchWorld - startMarchWorld);
                doIntersect = true;
                break;
            }
        }

        // Step to the next ray march
        marchWorld += delta;
        marchUV = worldToUV(vec4(marchWorld, 1.f)).xy;
    }

    if (!doIntersect) return;

    // Copy over the PBR output from the found intersection pixel
    gb_Reflection = vec4(texture(u_TexPBR, marchUV).rgb, 1.f);

    // Fall-off at the edges of the screen space reflection data
    gb_Reflection.a *= smoothstep(0.f, 0.05f, marchUV.x);
    gb_Reflection.a *= 1.f - smoothstep(0.95f, 1.f, marchUV.x);

    gb_Reflection.a *= smoothstep(0.f, 0.05f, marchUV.y);
    gb_Reflection.a *= 1.f - smoothstep(0.95f, 1.f, marchUV.y);

    // Fall-off at retroreflective directions
    gb_Reflection.a *= (1.f - max(dot(-wo, wi), 0.f));

    // Favor reflections that are closer to their intersection point
    gb_Reflection.a *= (1 - clamp(isectOffset / isectTolerance, 0.f, 1.f));

    // Fade out as the distance approaches the maximum allowed
    gb_Reflection.a *= smoothstep(maxDistance, startFade, t * maxDistance);
}
