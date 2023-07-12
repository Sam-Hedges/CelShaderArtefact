#ifndef MY_LIT_FORWARD_LIT_PASS_INCLUDED // Checks that this header hasn't already been defined
#define MY_LIT_FORWARD_LIT_PASS_INCLUDED

// Includes the boilerplate code for the shader
#include "MyLitCommon.hlsl"
#include "Assets/EXTERNAL/_Chroma/Core/Chroma.hlsl"

/*/////////////////////////////////////////////////////////////////////////////

Source Code From:
"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

Altered By Sam Hedges

This contains modified code from the Lighting.hlsl file from the Universal Render Pipeline.
It has been modified to extend custom lighting functions to be used in the Universal
Render Pipeline. This is done so that I can hijack the lighting functions and use my own
math to calculate the cel shaded lighting.

Altered code will be marked with a double slash appended at the end of the line.

/////////////////////////////////////////////////////////////////////////////*/

///////////////////////////////////////////////////////////////////////////////
//                       PBR Lighting Functions                              //
///////////////////////////////////////////////////////////////////////////////

// Lighting Includes
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/AmbientOcclusion.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"

#if defined(LIGHTMAP_ON)
    #define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) float2 lmName : TEXCOORD##index
    #define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT) OUT.xy = lightmapUV.xy * lightmapScaleOffset.xy + lightmapScaleOffset.zw;
    #define OUTPUT_SH(normalWS, OUT)
#else
#define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) half3 shName : TEXCOORD##index
#define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT)
#define OUTPUT_SH(normalWS, OUT) OUT.xyz = SampleSHVertex(normalWS)
#endif

half3 LightingLambert(half3 lightColor, half3 lightDir, half3 normal)
{
    half NdotL = saturate(dot(normal, lightDir));
    return lightColor * NdotL;
}

half3 LightingSpecular(half3 lightColor, half3 lightDir, half3 normal, half3 viewDir, half4 specular, half smoothness)
{
    float3 halfVec = SafeNormalize(float3(lightDir) + float3(viewDir));
    half NdotH = half(saturate(dot(normal, halfVec)));
    half modifier = pow(NdotH, smoothness);
    half3 specularReflection = specular.rgb * modifier;
    return lightColor * specularReflection;
}

half3 LightingPhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat,
                              half3 lightColor, half3 lightDirectionWS, half lightAttenuation,
                              half3 normalWS, half3 viewDirectionWS,
                              half clearCoatMask, bool specularHighlightsOff)
{
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation * NdotL);

    half3 brdf = brdfData.diffuse;
    #ifndef _SPECULARHIGHLIGHTS_OFF
    [branch] if (!specularHighlightsOff)
    {
        brdf += brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);

        #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
        // Clear coat evaluates the specular a second timw and has some common terms with the base specular.
        // We rely on the compiler to merge these and compute them only once.
        half brdfCoat = kDielectricSpec.r * DirectBRDFSpecular(brdfDataClearCoat, normalWS, lightDirectionWS, viewDirectionWS);

            // Mix clear coat and base layer using khronos glTF recommended formula
            // https://github.com/KhronosGroup/glTF/blob/master/extensions/2.0/Khronos/KHR_materials_clearcoat/README.md
            // Use NoV for direct too instead of LoH as an optimization (NoV is light invariant).
            half NoV = saturate(dot(normalWS, viewDirectionWS));
            // Use slightly simpler fresnelTerm (Pow4 vs Pow5) as a small optimization.
            // It is matching fresnel used in the GI/Env, so should produce a consistent clear coat blend (env vs. direct)
            half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * Pow4(1.0 - NoV);

        brdf = brdf * (1.0 - clearCoatMask * coatFresnel) + brdfCoat * clearCoatMask;
        #endif // _CLEARCOAT
    }
    #endif // _SPECULARHIGHLIGHTS_OFF

    return brdf * radiance;
}

half3 LightingPhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat, Light light, half3 normalWS,
                              half3 viewDirectionWS, half clearCoatMask, bool specularHighlightsOff)
{
    return LightingPhysicallyBased(brdfData, brdfDataClearCoat, light.color, light.direction,
                                   light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS,
                                   clearCoatMask, specularHighlightsOff);
}

// Backwards compatibility
half3 LightingPhysicallyBased(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS)
{
    #ifdef _SPECULARHIGHLIGHTS_OFF
    bool specularHighlightsOff = true;
    #else
    bool specularHighlightsOff = false;
    #endif
    const BRDFData noClearCoat = (BRDFData)0;
    return LightingPhysicallyBased(brdfData, noClearCoat, light, normalWS, viewDirectionWS, 0.0, specularHighlightsOff);
}

half3 LightingPhysicallyBased(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation,
                              half3 normalWS, half3 viewDirectionWS)
{
    Light light;
    light.color = lightColor;
    light.direction = lightDirectionWS;
    light.distanceAttenuation = lightAttenuation;
    light.shadowAttenuation = 1;
    return LightingPhysicallyBased(brdfData, light, normalWS, viewDirectionWS);
}

half3 LightingPhysicallyBased(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS,
                              bool specularHighlightsOff)
{
    const BRDFData noClearCoat = (BRDFData)0;
    return LightingPhysicallyBased(brdfData, noClearCoat, light, normalWS, viewDirectionWS, 0.0, specularHighlightsOff);
}

half3 LightingPhysicallyBased(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation,
                              half3 normalWS, half3 viewDirectionWS, bool specularHighlightsOff)
{
    Light light;
    light.color = lightColor;
    light.direction = lightDirectionWS;
    light.distanceAttenuation = lightAttenuation;
    light.shadowAttenuation = 1;
    return LightingPhysicallyBased(brdfData, light, viewDirectionWS, specularHighlightsOff, specularHighlightsOff);
}

half3 VertexLighting(float3 positionWS, half3 normalWS)
{
    half3 vertexLightColor = half3(0.0, 0.0, 0.0);

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
    uint lightsCount = GetAdditionalLightsCount();
    LIGHT_LOOP_BEGIN(lightsCount)
        Light light = GetAdditionalLight(lightIndex, positionWS);
        half3 lightColor = light.color * light.distanceAttenuation;
        vertexLightColor += LightingLambert(lightColor, light.direction, normalWS);
    LIGHT_LOOP_END
    #endif

    return vertexLightColor;
}

///////////////////////////////////////////////////////////////////////////////
//                            Lighting Data                                  //
///////////////////////////////////////////////////////////////////////////////

struct LightingData
{
    half3 giColor;
    half3 mainLightColor;
    half3 additionalLightsColor;
    half3 vertexLightingColor;
    half3 emissionColor;
};

half3 CalculateLightingColor(LightingData lightingData, half3 albedo)
{
    half3 lightingColor = 0;

    if (IsOnlyAOLightingFeatureEnabled())
    {
        return lightingData.giColor; // Contains white + AO
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_GLOBAL_ILLUMINATION))
    {
        lightingColor += lightingData.giColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_MAIN_LIGHT))
    {
        lightingColor += lightingData.mainLightColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_ADDITIONAL_LIGHTS))
    {
        lightingColor += lightingData.additionalLightsColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_VERTEX_LIGHTING))
    {
        lightingColor += lightingData.vertexLightingColor;
    }

    lightingColor *= albedo;

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_EMISSION))
    {
        lightingColor += lightingData.emissionColor;
    }

    return lightingColor;
}

half4 CalculateFinalColor(LightingData lightingData, half alpha)
{
    half3 finalColor = CalculateLightingColor(lightingData, 1);

    return half4(finalColor, alpha);
}

LightingData CreateLightingData(InputData inputData, SurfaceData surfaceData)
{
    LightingData lightingData;

    lightingData.giColor = inputData.bakedGI;
    lightingData.emissionColor = surfaceData.emission;
    lightingData.vertexLightingColor = 0;
    lightingData.mainLightColor = 0;
    lightingData.additionalLightsColor = 0;

    return lightingData;
}

///////////////////////////////////////////////////////////////////////////////
//                           Custom Lighting                                 //
///////////////////////////////////////////////////////////////////////////////

struct EdgeConstants
{
    float diffuse;
    float specular;
    float rim;
    float distanceAttenuation;
    float shadowAttenuation;
};

struct SurfaceVariables
{
    float smoothness;
    float shininess;

    float rimStrength;
    float rimAmount;
    float rimThreshold;

    float3 normal;
    float3 view;

    EdgeConstants ec;
};

float3 CalculateCelShading(Light l, SurfaceVariables s)
{
    float attenuation =
        smoothstep(0.0f, s.ec.distanceAttenuation, l.distanceAttenuation) *
        smoothstep(0.0f, s.ec.shadowAttenuation, l.shadowAttenuation);

    float diffuse = saturate(dot(s.normal, l.direction));
    diffuse *= attenuation;

    float3 h = SafeNormalize(l.direction + s.view);
    float specular = saturate(dot(s.normal, h));
    specular = pow(specular, s.shininess);
    specular *= diffuse;

    float rim = 1 - dot(s.view, s.normal);
    rim *= pow(diffuse, s.rimThreshold);

    diffuse = smoothstep(0.0f, s.ec.diffuse, diffuse);
    specular = s.smoothness * smoothstep(0.005f,
                                         0.005f + s.ec.specular * s.smoothness, specular);
    rim = s.rimStrength * smoothstep(
        s.rimAmount - 0.5f * s.ec.rim,
        s.rimAmount + 0.5f * s.ec.rim,
        rim
    );

    return l.color * (diffuse + max(specular, rim));
}

float3 LightingCelShaded(float Smoothness,
                         float RimStrength, float RimAmount, float RimThreshold,
                         float3 Position, float3 Normal, float3 View, float EdgeDiffuse,
                         float EdgeSpecular, float EdgeDistanceAttenuation,
                         float EdgeShadowAttenuation, float EdgeRim)
{
    SurfaceVariables s;
    s.smoothness = Smoothness;
    s.shininess = exp2(10 * Smoothness + 1);
    s.rimStrength = RimStrength;
    s.rimAmount = RimAmount;
    s.rimThreshold = RimThreshold;
    s.normal = normalize(Normal);
    s.view = SafeNormalize(View);
    s.ec.diffuse = EdgeDiffuse;
    s.ec.specular = EdgeSpecular;
    s.ec.distanceAttenuation = EdgeDistanceAttenuation;
    s.ec.shadowAttenuation = EdgeShadowAttenuation;
    s.ec.rim = EdgeRim;

    #if SHADOWS_SCREEN
    float4 clipPos = TransformWorldToHClip(Position);
    float4 shadowCoord = ComputeScreenPos(clipPos);
    #else
    float4 shadowCoord = TransformWorldToShadowCoord(Position);
    #endif

    Light light = GetMainLight(shadowCoord);
    float3 Color = CalculateCelShading(light, s);

    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; i++)
    {
        light = GetAdditionalLight(i, Position, 1);
        Color += CalculateCelShading(light, s);
    }

    return Color;
}

float3 CalculateCelLighting(Light l, SurfaceVariables s)
{
    float attenuation =
        smoothstep(0.0f, s.ec.distanceAttenuation, l.distanceAttenuation) *
        smoothstep(0.0f, s.ec.shadowAttenuation, l.shadowAttenuation);

    float diffuse = saturate(dot(s.normal, l.direction));
    diffuse *= attenuation;

    float3 h = SafeNormalize(l.direction + s.view);
    float specular = saturate(dot(s.normal, h));
    specular = pow(specular, s.shininess);
    specular *= diffuse;

    float rim = 1 - dot(s.view, s.normal);
    rim *= pow(diffuse, s.rimThreshold);

    diffuse = smoothstep(0.0f, s.ec.diffuse, diffuse);
    specular = s.smoothness * smoothstep(0.005f,
                                         0.005f + s.ec.specular * s.smoothness, specular);
    rim = s.rimStrength * smoothstep(
        s.rimAmount - 0.5f * s.ec.rim,
        s.rimAmount + 0.5f * s.ec.rim,
        rim
    );

    return l.color * (diffuse + max(specular, rim));
}

float4 UniversalFragmentCelPBR(InputData inputData, SurfaceData surfaceData)
{
    #if defined(_SPECULARHIGHLIGHTS)
    bool specularHighlightsOff = false;
    #else
    bool specularHighlightsOff = true;
    #endif
    BRDFData brdfData;

    // NOTE: can modify "surfaceData"...
    InitializeBRDFData(surfaceData, brdfData);

    // Clear-coat calculation...
    BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    uint meshRenderingLayers = GetMeshRenderingLightLayer();
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    // NOTE: We don't apply AO to the GI here because it's done in the lighting calculation below...
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    LightingData lightingData = CreateLightingData(inputData, surfaceData);

    lightingData.giColor = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                                              inputData.bakedGI, aoFactor.indirectAmbientOcclusion,
                                              inputData.positionWS,
                                              inputData.normalWS, inputData.viewDirectionWS);

    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
    {
        lightingData.mainLightColor = LightingPhysicallyBased(brdfData, brdfDataClearCoat,
                                                              mainLight,
                                                              inputData.normalWS, inputData.viewDirectionWS,
                                                              surfaceData.clearCoatMask, specularHighlightsOff);
    }

    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
        {
            lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                                          surfaceData.clearCoatMask, specularHighlightsOff);
        }
    LIGHT_LOOP_END
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting * brdfData.diffuse;
    #endif

    return CalculateFinalColor(lightingData, surfaceData.alpha);
}


///////////////////////////////////////////////////////////////////////////////
//                             PBR Lighting                                  //
///////////////////////////////////////////////////////////////////////////////

half4 UniversalFragmentPBR(InputData inputData, SurfaceData surfaceData)
{
    #if defined(_SPECULARHIGHLIGHTS)
    bool specularHighlightsOff = false;
    #else
    bool specularHighlightsOff = true;
    #endif
    BRDFData brdfData;

    // NOTE: can modify "surfaceData"...
    InitializeBRDFData(surfaceData, brdfData);

    // Clear-coat calculation...
    BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    uint meshRenderingLayers = GetMeshRenderingLightLayer();
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    // NOTE: We don't apply AO to the GI here because it's done in the lighting calculation below...
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    LightingData lightingData = CreateLightingData(inputData, surfaceData);

    lightingData.giColor = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                                              inputData.bakedGI, aoFactor.indirectAmbientOcclusion,
                                              inputData.positionWS,
                                              inputData.normalWS, inputData.viewDirectionWS);

    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
    {
        lightingData.mainLightColor = LightingPhysicallyBased(brdfData, brdfDataClearCoat,
                                                              mainLight,
                                                              inputData.normalWS, inputData.viewDirectionWS,
                                                              surfaceData.clearCoatMask, specularHighlightsOff);
    }

    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
        {
            lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                                          surfaceData.clearCoatMask, specularHighlightsOff);
        }
    LIGHT_LOOP_END
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting * brdfData.diffuse;
    #endif

    return CalculateFinalColor(lightingData, surfaceData.alpha);
}


///////////////////////////////////////////////////////////////////////////////
//                             Shader Code                                   //
///////////////////////////////////////////////////////////////////////////////

// This attributes struct receives data about the mesh we're currently rendering
// Data automatically populates fields according to their semantic
struct Attributes
{
    // Vertex position in object space
    float3 positionOS : POSITION;

    // Vertex normal in object space
    float3 normalOS : NORMAL;

    // Vertex tangent in object space
    float4 tangentOS : TANGENT;

    // Texture coordinates
    float2 uv : TEXCOORD0;
};

// This struct is output by the vertex function and input to the fragment function
// Note that fields will be transformed by the intermediary rasterization stage
struct Interpolators
{
    // This value should contain the position in clip space when output from the
    // vertex function. It will be transformed into the pixel position of the
    // current fragment on the screen when read from the fragment function
    float4 positionCS : SV_POSITION;

    // The following variables will retain their values from the vertex stage, except the
    // rasterizer will interpolate them between vertices
    // Two fields should not have the same semantic, the rasterizer can handle many TEXCOORD variables

    // Texture coordinates
    float2 uv : TEXCOORD0;

    // Vertex position in world space
    float3 positionWS : TEXCOORD1;

    // Vertex normal in world space
    float3 normalWS : TEXCOORD2;

    // Vertex tangent in world space
    float4 tangentWS : TEXCOORD3;
};

Interpolators Vertex(Attributes input)
{
    Interpolators output;

    // Get vertex position inputs
    VertexPositionInputs posnInputs = GetVertexPositionInputs(input.positionOS);
    // Get vertex normal inputs
    VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    // Set output position in clip space
    output.positionCS = posnInputs.positionCS;
    // Transform texture coordinates using the _ColorMap texture
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    // Set output normal in world space
    output.normalWS = normInputs.normalWS;
    // Set output tangent in world space
    output.tangentWS = float4(normInputs.tangentWS, input.tangentOS.w);
    // Set output position in world space
    output.positionWS = posnInputs.positionWS;

    return output;
}

float4 Fragment(Interpolators input
                #ifdef _DOUBLE_SIDED_NORMALS
                , FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC
                #endif
) : SV_TARGET
{
    // Get world space normal
    float3 normalWS = input.normalWS;
    #ifdef _DOUBLE_SIDED_NORMALS
    // Flip the normal if double-sided rendering is enabled
    normalWS *= IS_FRONT_VFACE(frontFace, 1, -1);
    #endif

    // Get world space position
    float3 positionWS = input.positionWS;
    // Get world space view direction
    float3 viewDirWS = GetWorldSpaceNormalizeViewDir(positionWS); // In ShaderVariablesFunctions.hlsl

    // Get texture coordinates
    float2 uv = input.uv;

    // Sample color texture and apply color tint
    float4 colorSample = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv) * _BaseColor;
    // Clip alpha if it is below the threshold
    TestAlphaClip(colorSample);

    // Get tangent space normal
    #if defined(_NORMALMAP)
    float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv), _NormalStrength);
    #else
    float3 normalTS = float3(0, 0, 1);
    #endif
    // Create tangent to world space matrix
    float3x3 tangentToWorld = CreateTangentToWorld(normalWS, input.tangentWS.xyz, input.tangentWS.w);
    // Transform tangent space normal to world space
    normalWS = normalize(TransformTangentToWorld(normalTS, tangentToWorld));

    // Set lighting input
    InputData lightingInput = (InputData)0;
    lightingInput.positionWS = positionWS;
    lightingInput.normalWS = normalWS;
    lightingInput.viewDirectionWS = viewDirWS;
    lightingInput.shadowCoord = TransformWorldToShadowCoord(positionWS);
    #if UNITY_VERSION >= 202120
	lightingInput.positionCS = input.positionCS; // Assign the clip-space position to the lighting input
	lightingInput.tangentToWorld = tangentToWorld; // Assign the tangent to world matrix to the lighting input
    #endif

    SurfaceData surfaceInput = (SurfaceData)0;
    surfaceInput.albedo = colorSample.rgb; // Assign the color sample's RGB channels to the surface input's albedo
    surfaceInput.alpha = colorSample.a; // Assign the color sample's alpha channel to the surface input's alpha
    #ifdef _SPECULAR_SETUP
	surfaceInput.specular = SAMPLE_TEXTURE2D(_SpecularMap, sampler_SpecularMap, uv).rgb * _SpecularTint; // Sample the specular map and apply the tint, if using a specular setup
	surfaceInput.metallic = 0; // Set metallic to 0 if using a specular setup
    #else
    surfaceInput.specular = 1; // Set specular to 1 if not using a specular setup
    surfaceInput.metallic = SAMPLE_TEXTURE2D(_MetalnessMask, sampler_MetalnessMask, uv).r * _Metalness;
    // Sample the metalness mask and apply the metalness
    #endif
    // Sample the smoothness mask and apply the smoothness
    surfaceInput.smoothness = SAMPLE_TEXTURE2D(_SmoothnessMask, sampler_SmoothnessMask, uv).r * _Smoothness;
    // Sample the emission map and apply the tint
    #if defined(_EMISSION)
    surfaceInput.emission = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, uv).rgb * _EmissionTint;
    #else
    surfaceInput.emission = 0;
    #endif

    surfaceInput.normalTS = normalTS; // Assign the tangent-space normal to the surface input

    float4 lighting;
    lighting.rgb = LightingCelShaded(_Smoothness,
                                     _RimStrength, _RimAmount, _RimThreshold,
                                     positionWS, normalWS, viewDirWS, _EdgeDiffuse,
                                     _EdgeSpecular, _EdgeDistanceAttenuation,
                                     _EdgeShadowAttenuation, _EdgeRim);
    lighting.a = colorSample.a;
    //return lighting * colorSample.rgba;

    return UniversalFragmentCelPBR(lightingInput, surfaceInput);
    // Call the UniversalFragmentPBR function with the lighting and surface inputs, and return the result as a float4
}
#endif
