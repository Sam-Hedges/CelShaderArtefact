// Pull in URP library functions and our own common functions
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
// Contains all the shadergraph related functions
#include "CommonFunctions.hlsl"

// This file contains the vertex and fragment functions for the forward lit pass
// This is the shader pass that computes visible colours for a material
// by reading material, light, shadow, etc. data

// Shader Properties
TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
float4 _MainTex_ST; // Automatically set by Unity. Used in TRANSFORM_TEX to apply UV tiling
float _Progress;
float4 _Colour;
float4 _BackgroundColour;
float _BorderNoiseScale;
float _MovingAmount;
float _DissolveTransition;
float _DissolveAmount;
float _Rotation;
float _NoiseScale;
float _NoiseIntensity;
bool _Spherize;
float _BorderDistortionAmount;
float _NoiseRoundFactor;

// This attributes struct receives data about the mesh we're currently rendering
// Data automatically populates fields according to their semantic
struct Attributes
{
    float3 positionOS : POSITION; // Position in object space
    float3 normalOS : NORMAL; // Normal in object space
    float4 tangetOS : TANGENT; // Tangent in object space
    float2 uv : TEXCOORD0; // Material texture UVs
	float2 lightmapUV	: TEXCOORD6;
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
    float2 uv : TEXCOORD0; // Material texture UVs
    float3 normalWS : TEXCOORD1; // Normal in world space
    float3 normalOS : TEXCOORD2; // Normal in object space
    float3 normalTS : TEXCOORD3; // Normal in object space
    float3 positionWS : TEXCOORD4;
    float4 screenPosition : TEXCOORD5;

	DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 6);
};

// The vertex function which runs for each vertex on the mesh.
// It must output the position on the screen, where each vertex should appear,
// as well as any data the fragment function will need
Interpolators Vertex(Attributes input)
{
    Interpolators output;
    
    // These helper functions, found in URP/ShaderLib/ShaderVariablesFunctions.hlsl
    // transform object space values into world and clip space
    // CalulateWaves is a custom function that calculates the wave movement
    VertexPositionInputs posnInputs = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS);
	
    // Pass position, orientation and normal data to the fragment function
    output.uv = input.uv;
    output.uv = TRANSFORM_TEX(input.uv, _MainTex);
    output.positionCS = posnInputs.positionCS;
    output.normalWS = normInputs.normalWS;
    output.normalOS = input.normalOS;
    output.normalTS = normInputs.tangentWS;
    output.positionWS = posnInputs.positionWS;
    output.screenPosition = ComputeScreenPos(output.positionCS);
	
    return output;
}

// The fragment function runs once per fragment, akin to a pixel on the screen but virtualized
// It must output the final colour of this pixel hence the function is a float4
// The function is tagged with a semantic so that the return value is interpreted in a specific way
float4 Fragment(Interpolators input) : SV_TARGET
{
    // Setup UVs
    float2 uv = Rotate(input.uv, 0.5, _Rotation);
    if (_Spherize) { uv = Spherize(uv, 0.5, 10, 0); }
	
    // Sample scene time
    float time = _Time.y;

    // Border Shape, Light & Noise
    float gradientNoise = GradientNoise(uv + float2(0, time * 0.2), _BorderNoiseScale);
    //float borderNoise = _Progress - lerp(uv1.x, gradientNoise, _BorderDistortionAmount);
    float borderNoise = _Progress - lerp(uv.x, gradientNoise, _BorderDistortionAmount);
    float4 finalBorderNoise = SampleBasicGradient(borderNoise, 1, 0.678431, 0.0009);
    float4 finalBorderLightNoise = SampleBasicGradient(borderNoise, 1, 0, 0.0005) * _MovingAmount;
    
    // Inside Noise
    float simpleNoise1 = SimpleNoise(uv + float2(0, time * 0.1), _NoiseScale);
    float simpleNoise2 = SimpleNoise(uv + float2(0, time * 0.03), _NoiseScale * 1.3);
    float simpleNoise3 = SimpleNoise(uv + float2(0, time * -0.03), _NoiseScale * 1.5);
    float simpleNoiseMerged = simpleNoise2 * simpleNoise3 * simpleNoise1;
    float simpleNoisePixelated = Remap((round(simpleNoiseMerged * _NoiseRoundFactor ) / _NoiseRoundFactor).xxxx, float2(0, 1), float2(0, 10)).x;
    float simpleNoiseLerped = lerp(1, simpleNoisePixelated, _NoiseIntensity);
    float simpleNoiseClamped = clamp(simpleNoiseLerped, 0.1, 1);
    float4 finalSimpleNoise = (1 - step(finalBorderNoise, 0.1822373)) * simpleNoiseClamped;
	
    // Dissolve
    float dissolveNoise = SimpleNoise(uv + float2(time * -1, 0), 30);
    float dissolveStep1 = step(_DissolveAmount - 0.06, dissolveNoise);
    float dissolveStep2 = step(_DissolveAmount, dissolveNoise);
    float dissolveFinalStep = (dissolveStep1 - dissolveStep2) * 15 + dissolveStep2;
    float4 finalDissolve = simpleNoiseLerped * _Colour * 3 * dissolveFinalStep;
	
    // Colour
    float4 finalColour = finalBorderLightNoise + _Colour * finalBorderNoise * finalSimpleNoise;
    finalColour = lerp(finalColour, finalDissolve, _DissolveTransition);
    float colourMask = ColourMask(finalColour.xyz, float3(0, 0, 0), 0, 0).x;
    finalColour.rgb = (finalColour + colourMask * _BackgroundColour).xyz;
    float4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
    finalColour.a = mainTex.a * Remap(colourMask, float2(0, 1), float2(_Colour.a, _BackgroundColour.a)).x;
    
    return finalColour;
}
