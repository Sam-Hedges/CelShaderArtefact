// Pull in URP library functions and our own common functions
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
// Used to pre-define methods that are shared across multiple shader passes
#include "MyLitCore.hlsl"


float3 _LightDirection;

// Wave parameters
float _WaveAmplitude;
float _WaveFrequency;
float _WaveSpeed;

// This attributes struct receives data about the mesh we're currently rendering
// Data automatically populates fields according to their semantic
struct Attributes
{
    float3 positionOS : POSITION; // Position in object space
    float3 normalOS : NORMAL; // Normal in object space
};

// This struct is output by the vertex function and input to the fragment function
// Note that fields will be transformed by the intermediary rasterization stage
struct Interpolators
{
    // This value should contain the position in clip space when output from the
    // vertex function. It will be transformed into the pixel position of the
    // current fragment on the screen when read from the fragment function
    float4 positionCS : SV_POSITION;
};

// This function calculates an offset clip space position to reduce shadow acne
float4 GetShadowCasterPositionCS(float3 positionWS, float3 normalWS) {
    
    float3 lightDirectionWS = _LightDirection;

    // ApplyShadowBias will read and apply shadow bias settings
    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
    
    #if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
    #else
    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
    #endif
    return positionCS;
}


// The vertex function which runs for each vertex on the mesh.
// It must output the position on the screen, where each vertex should appear,
// as well as any data the fragment function will need
Interpolators Vertex(Attributes input)
{
    Interpolators output;

    // These helper functions, found in URP/ShaderLib/ShaderVariablesFunctions.hlsl
    // transform object space values into world and clip space
    WaveData waveData = CalculateWave(input.positionOS, _WaveSpeed, _WaveFrequency, _WaveAmplitude);
    VertexPositionInputs posnInputs = GetVertexPositionInputs(waveData.waveVertexPosition);
    VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS);

    output.positionCS = GetShadowCasterPositionCS(posnInputs.positionWS, normInputs.normalWS);

    return output;
}

// The fragment function runs once per fragment, akin to a pixel on the screen but virtualized
// It must output the final colour of this pixel hence the function is a float4
// The function is tagged with a semantic so that the return value is interpreted in a specific way
float4 Fragment(Interpolators input) : SV_TARGET
{
    return 0;
}
