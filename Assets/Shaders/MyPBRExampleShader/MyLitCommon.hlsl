// This file contains the properties for the forward lit pass
// To reduce the amount of boiler plate within the forward pass
#ifndef MY_LIT_COMMON_INCLUDED // Checks that this header hasn't already been defined
#define MY_LIT_COMMON_INCLUDED

// Includes
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

///////////////////////////////////////////////////////////////////////////////
//                              Properties                                   //
///////////////////////////////////////////////////////////////////////////////

TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
TEXTURE2D(_MetalnessMask); SAMPLER(sampler_MetalnessMask);
TEXTURE2D(_SpecularMap); SAMPLER(sampler_SpecularMap);
TEXTURE2D(_SmoothnessMask); SAMPLER(sampler_SmoothnessMask);
TEXTURE2D(_EmissionMap); SAMPLER(sampler_EmissionMap);

TEXTURE2D(_LightingRampMap); SAMPLER(sampler_LightingRampMap);

float4 _BaseMap_ST;
float4 _BaseColor;
float _Cutoff;
float _NormalStrength;
float _Metalness;
float3 _SpecularTint;
float _Smoothness;
float3 _EmissionTint;

float _RimThreshold;
float _RimStrength;
float _RimAmount;
float _EdgeDiffuse;
float _EdgeSpecular;
float _EdgeSpecularOffset;
float _EdgeDistanceAttenuation;
float _EdgeShadowAttenuation;
float _EdgeRim;
float _EdgeRimOffset;

///////////////////////////////////////////////////////////////////////////////
//                      Material Property Helpers                            // 
///////////////////////////////////////////////////////////////////////////////

void TestAlphaClip(float4 colorSample) {
    #ifdef _ALPHA_CUTOUT
    clip(colorSample.a * _BaseColor.a - _Cutoff);
    #endif
}

//////////////////////////////////////////////////////////////////////////////////////////
// Needed to satisfy calls from the default unity "DepthOnly" and "DepthNormals" passes //
//////////////////////////////////////////////////////////////////////////////////////////

half Alpha(half albedoAlpha, half4 color, half cutoff)
{
    #if !defined(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A) && !defined(_GLOSSINESS_FROM_BASE_ALPHA)
    half alpha = albedoAlpha * color.a;
    #else
    half alpha = color.a;
    #endif

    #if defined(_ALPHATEST_ON) 
    clip(alpha - cutoff);
    #endif

    return alpha;
}

half4 SampleAlbedoAlpha(float2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap))
{
    return half4(SAMPLE_TEXTURE2D(albedoAlphaMap, sampler_albedoAlphaMap, uv));
}

half3 SampleNormal(float2 uv, TEXTURE2D_PARAM(bumpMap, sampler_bumpMap), half scale = half(1.0))
{
    #ifdef _NORMALMAP
    half4 n = SAMPLE_TEXTURE2D(bumpMap, sampler_bumpMap, uv);
    #if BUMP_SCALE_NOT_SUPPORTED
    return UnpackNormal(n);
    #else
    return UnpackNormalScale(n, scale);
    #endif
    #else
    return half3(0.0h, 0.0h, 1.0h);
    #endif
}

half3 SampleEmission(float2 uv, half3 emissionColor, TEXTURE2D_PARAM(emissionMap, sampler_emissionMap))
{
    #ifndef _EMISSION
    return 0;
    #else
    return SAMPLE_TEXTURE2D(emissionMap, sampler_emissionMap, uv).rgb * emissionColor;
    #endif
}

#endif