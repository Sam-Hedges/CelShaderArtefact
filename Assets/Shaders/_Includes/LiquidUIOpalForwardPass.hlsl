// Pull in URP library functions and our own common functions
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
// Contains all the shadergraph related functions
#include "CommonFunctions.hlsl"

// This file contains the vertex and fragment functions for the forward lit pass
// This is the shader pass that computes visible colours for a material
// by reading material, light, shadow, etc. data

// Shader Properties
TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
TEXTURE2D(_DiffractionMap); SAMPLER(sampler_DiffractionMap);
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
float _Distance;

// Variables
float3 worldTangent;

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

//  SurfaceData & InputData
void InitalizeSurfaceData(Interpolators input, out SurfaceData surfaceData){
	surfaceData = (SurfaceData)0; // avoids "not completely initalized" errors

	// Populates the fields in the input structs
	surfaceData.albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).rgb;
	surfaceData.alpha = 1;
	surfaceData.specular = 1; // Set Highlights to white
	surfaceData.smoothness = 1;
	surfaceData.occlusion = 1.0; // unused

}

void InitializeInputData(Interpolators input, out InputData inputData) {
	inputData = (InputData)0; // avoids "not completely initalized" errors

	inputData.positionWS = input.positionWS;
	inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
	inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
	// When the normal is rasterized due to the semantic in the Interpolators struct, it's interpolated between
	// values, and for lighting to look its best all normal vectors must have a length of one.
	// Hence the Normalize method, which can be slow, since it has an expensive square root calculation
	// but I think this step is worth the performance cost for smoother lighting. (especially noticeable on specular highlights)
	//lightingInput.normalWS = UnityObjectToWorldNormal(normalize(finalNormal);
	inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
	//inputData.normalWS = NormalFromTexture(TEXTURE2D_ARGS(_DiffractionMap, sampler_DiffractionMap), input.uv + _Time.y * 0.1, 1, 1);
	
	inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
}

float3 bump3y (float3 x, float3 yoffset)
{
	float3 y = 1 - x * x;
	y = saturate(y-yoffset);
	return y;
}

float3 spectral_zucconi6 (float w)
{
	// w: [400, 700]
	// x: [0,   1]
	float x = saturate((w - 400.0)/ 300.0);
	const float3 c1 = float3(3.54585104, 2.93225262, 2.41593945);
	const float3 x1 = float3(0.69549072, 0.49228336, 0.27699880);
	const float3 y1 = float3(0.02312639, 0.15225084, 0.52607955);
	const float3 c2 = float3(3.90307140, 3.21182957, 3.96587128);
	const float3 x2 = float3(0.11748627, 0.86755042, 0.66077860);
	const float3 y2 = float3(0.84897130, 0.88445281, 0.73949448);
	return
		bump3y(c1 * (x - x1), y1) +
		bump3y(c2 * (x - x2), y2) ;
}

float4 LightingDiffraction(Interpolators input)
{
    // Setup SurfaceData
    SurfaceData surfaceData;
    InitalizeSurfaceData(input, surfaceData);

    // Setup InputData
    InputData inputData;
    InitializeInputData(input, inputData);

    // Simple Lighting (Lambert & BlinnPhong)
    float4 lighting = UniversalFragmentBlinnPhong(inputData, surfaceData); // v12 only

	// Diffraction grating effect
	float3 L = inputData.bakedGI;
	float3 V = _WorldSpaceCameraPos.xyz - input.positionWS;
	float3 T = worldTangent;
	float d = _Distance;
	float cos_ThetaL = dot(L, T);
	float cos_ThetaV = dot(V, T);
	float u = abs(cos_ThetaL - cos_ThetaV);
	if (u == 0) { return lighting; }
	
	// Calculates the reflection color
	float3 color = 0;
	for (int n = 1; n <= 8; n++)
	{
		float wavelength = u * d / n;
		color += spectral_zucconi6(wavelength);
	}
	color = saturate(color);
	// Adds the reflection to the material colour
	lighting.rgb += color;
    
    return lighting;
}

// The fragment function runs once per fragment, akin to a pixel on the screen but virtualized
// It must output the final colour of this pixel hence the function is a float4
// The function is tagged with a semantic so that the return value is interpreted in a specific way
float4 Fragment(Interpolators input) : SV_TARGET
{
    // Setup UVs
    float2 uv = Rotate(input.uv, 0.5, _Rotation);
    if (_Spherize) { uv = Spherize(uv, 0.5, 10, 0); }
	
	float2 uv_orthogonal = normalize(uv);
	float3 uv_tangent = float3(-uv_orthogonal.y, 0, uv_orthogonal.x);
	worldTangent = normalize(mul(unity_ObjectToWorld, float4(uv_tangent, 0))).xyz;
	worldTangent = NormalFromTexture(TEXTURE2D_ARGS(_DiffractionMap, sampler_DiffractionMap), float2(uv.x, uv.y + _Time.y * 0.1), 1, 2);

	float4 lightingDiffraction = LightingDiffraction(input);
	
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
    float4 finalSimpleNoise = lerp((1 - step(finalBorderNoise, 0.1822373)), lightingDiffraction, saturate(lightingDiffraction.a * 0.4));
	
    // Dissolve
    float dissolveNoise = SimpleNoise(uv + float2(time * -1, 0), 30);
    float dissolveStep1 = step(_DissolveAmount - 0.06, dissolveNoise);
    float dissolveStep2 = step(_DissolveAmount, dissolveNoise);
    float dissolveFinalStep = (dissolveStep1 - dissolveStep2) * 15 + dissolveStep2;
    //float4 finalDissolve = simpleNoiseLerped * _Colour * 3 * dissolveFinalStep;
	float4 finalDissolve = _Colour * 3 * dissolveFinalStep;
	
    // Colour
    float4 finalColour = finalBorderLightNoise + _Colour * finalBorderNoise * finalSimpleNoise;
    finalColour = lerp(finalColour, finalDissolve, _DissolveTransition);
    float colourMask = ColourMask(finalColour.xyz, float3(0, 0, 0), 0, 0).x;
    finalColour.rgb = (finalColour + colourMask * _BackgroundColour).xyz;
    float4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
    finalColour.a = mainTex.a * Remap(colourMask, float2(0, 1), float2(_Colour.a, _BackgroundColour.a)).x;
    
    return finalColour;
}
