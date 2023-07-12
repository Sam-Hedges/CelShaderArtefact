// Pull in URP library functions and our own common functions
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
// Contains functions used to sample the depth texture
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
// Used to pre-define methods that are shared across multiple shader passes
#include "MyLitCore.hlsl"

// This file contains the vertex and fragment functions for the forward lit pass
// This is the shader pass that computes visible colours for a material
// by reading material, light, shadow, etc. data
TEXTURE2D(_ColourMap); SAMPLER(sampler_ColourMap);
float4 _ColourMap_ST; // Automatically set by Unity. Used in TRANSFORM_TEX to apply UV tiling
float4 _ColourTint;
float _Smoothness;
TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
float4 _NormalMap_ST; // Automatically set by Unity. Used in TRANSFORM_TEX to apply UV tiling
float _BumpStrength;
float _DetailScale;
float _DetailStrength;
float _ScrollSpeed;

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
    float4 tangetOS : TANGENT; // Tangent in object space
    float2 uv : TEXCOORD0; // Material texture UVs
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
    float3 positionWS : TEXCOORD2;
    float4 screenPosition : TEXCOORD3;
    float3 normalOS : TEXCOORD4; // Normal in object space
};

float3 NormalStrength(float3 In, float Strength)
{
    return float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
}

float3 NormalLerp(float3 A, float3 B, float ratio)
{
    float3 blend = normalize(float3(A.rg + B.rg, A.b * B.b));
    return lerp(lerp(A, blend, saturate(ratio * 2)), B, saturate((ratio - 0.5) * 2));
}

float2 ScaleFloat2(float2 In, float Scale)
{
    return float2(In.x * Scale, In.y * Scale);
}

// The vertex function which runs for each vertex on the mesh.
// It must output the position on the screen, where each vertex should appear,
// as well as any data the fragment function will need
Interpolators Vertex(Attributes input)
{
    Interpolators output;
    
    // These helper functions, found in URP/ShaderLib/ShaderVariablesFunctions.hlsl
    // transform object space values into world and clip space
    // CalulateWaves is a custom function that calculates the wave movement
    WaveData waveData = CalculateWave(input.positionOS, _WaveSpeed, _WaveFrequency, _WaveAmplitude);
    VertexPositionInputs posnInputs = GetVertexPositionInputs(waveData.waveVertexPosition);
    VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS);

    if (normInputs.normalWS.y == 1)
    {
        normInputs.normalWS += (waveData.waveVertexNormal * 0.2);   
    }
    
    // Pass position, orientation and normal data to the fragment function
    output.positionCS = posnInputs.positionCS;
    output.uv = TRANSFORM_TEX(input.uv, _ColourMap);
    output.normalWS = normInputs.normalWS;
    output.normalOS = input.normalOS;
    output.positionWS = posnInputs.positionWS;
    output.screenPosition = ComputeScreenPos(output.positionCS);
    
    return output;
}

// The fragment function runs once per fragment, akin to a pixel on the screen but virtualized
// It must output the final colour of this pixel hence the function is a float4
// The function is tagged with a semantic so that the return value is interpreted in a specific way
float4 Fragment(Interpolators input) : SV_TARGET
{
    float2 uv = input.uv;

    float3 dx = ddx(input.positionWS);
    float3 dy = ddy(input.positionWS);
    float3 N = normalize(cross(dx, dy));
    //input.normalOS = -N;
    
    // SampleSceneDepth function with the Screen coords returns the Raw Scene Depth value
    float rawDepth = SampleSceneDepth(input.screenPosition.xy / input.screenPosition.w);
    // LinearEyeDepth function converts the Raw Scene Depth value to Linear Eye Depth
    float sceneEyeDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
    // Final scene depth
    float sceneDepth = sceneEyeDepth - input.screenPosition.w;

    // UV's scaling and scrolling
    float2 uvScaled = ScaleFloat2(uv.xy, input.normalWS.y * 0.5 + 1);
    float2 scrolling = ScaleFloat2(float2(_Time.y, _Time.y), _ScrollSpeed);
    float2 uv1 = uvScaled + scrolling * float2(-0.1, 0.035);
    float2 uv2 = ScaleFloat2(uvScaled, _DetailScale) + scrolling * float2(-0.01, 0.05);

    // Normals
    float3 normal1 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv1));
    float3 normal2 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv2));
    float3 penultimateNormal = NormalLerp(normal1, normal2, 1 - _DetailStrength);
    float strength1 = 1 - saturate((1 - input.normalWS.y) * 0.5);
    float strength2 = saturate(input.normalWS.y + 0.75);
    float3 finalNormal = NormalStrength(NormalStrength(NormalStrength(penultimateNormal, strength1), _BumpStrength), strength2);
    
    // Sample the colour map
    float4 colourSample = SAMPLE_TEXTURE2D(_ColourMap, sampler_ColourMap, uv);

    // This holds information about the position and orientation of the mesh at the current fragment
    InputData lightingInput = (InputData)0;
    // This holds information about the surface material’s physical properties, like colour
    SurfaceData surfaceInput = (SurfaceData)0;
    // Unlike C#, structure fields must be manually initialized. To set all fields to zero, cast zero to the
    // structure type. This looks strange, but it’s an easy way to initialize a structure without having to
    // know all its fields.

    // Populates the fields in the input structs
    surfaceInput.albedo = colourSample.rgb * _ColourTint.rgb;
    surfaceInput.alpha = colourSample.a * _ColourTint.a;
    surfaceInput.specular = 1; // Set Highlights to white
    surfaceInput.smoothness = _Smoothness;
    surfaceInput.normalTS = normalize(finalNormal);
    lightingInput.positionWS = input.positionWS;
    lightingInput.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    lightingInput.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
    // When the normal is rasterized due to the semantic in the Interpolators struct, it's interpolated between
    // values, and for lighting to look its best all normal vectors must have a length of one.
    // Hence the Normalize method, which can be slow, since it has an expensive square root calculation
    // but I think this step is worth the performance cost for smoother lighting. (especially noticeable on specular highlights)
    //lightingInput.normalWS = UnityObjectToWorldNormal(normalize(finalNormal);
    lightingInput.normalWS = normalize(input.normalWS - finalNormal);
    
    // Computes a standard lighting algorithm called the Blinn-Phong lighting model
    float4 finalColour = UniversalFragmentPBR(lightingInput, surfaceInput);

    // Apply Ambient Lighting
    float3 ambientColour = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
    finalColour.rgb += ambientColour * 2 * colourSample - colourSample;
    //return float4(normalize(input.normalWS - finalNormal), 1);
    return finalColour;
}
