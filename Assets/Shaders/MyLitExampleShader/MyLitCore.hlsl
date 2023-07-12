// Contains URP library common functions
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct WaveData
{
    float3 waveVertexPosition;
    float3 waveVertexNormal;
};

// The CalculateWaveHeight methods are above the CalculateWave function so that they can be accessed
float CalculateWaveHeight(float3 positionOS, float speed, float frequency, float amplitude)
{
    // Get the world space position of the vertex
    float3 positionWS = GetVertexPositionInputs(positionOS).positionWS;
    
    // Calculate the wave movement speed
    float waveMovement = _Time.y * speed;

    // Calculate the wave offset
    float waveOffset = sin(waveMovement + frequency * positionWS.x) + cos(waveMovement + frequency * positionWS.z);

    // Scale the waves to the desired amplitude
    float waveScaled = waveOffset * amplitude;

    // Used to ensure only the top vertices are moved
    float steppedPosY = step(0.5, positionOS.y);

    // Calculate the new vertex position
    float finalWaveHeight = positionOS.y + waveScaled * steppedPosY;

    // Return the output wave position
    return finalWaveHeight;
}

float CalculateWaveHeight(float3 positionOS, float3 offset, float speed, float frequency, float amplitude)
{
    // Get the world space position of the vertex
    float3 positionWS = GetVertexPositionInputs(positionOS).positionWS;

    // Apply the offset to the current world position
    positionWS += offset;
    
    // Calculate the wave movement speed
    float waveMovement = _Time.y * speed;

    // Calculate the wave offset
    float waveOffset = sin(waveMovement + frequency * positionWS.x) + cos(waveMovement + frequency * positionWS.z);

    // Scale the waves to the desired amplitude
    float waveScaled = waveOffset * amplitude;

    // Used to ensure only the top vertices are moved
    float steppedPosY = step(0.5, positionOS.y);

    // Calculate the new vertex position
    float finalWaveHeight = positionOS.y + waveScaled * steppedPosY;

    // Return the output wave position
    return finalWaveHeight;
}

// This method calculates the offset vertex positions to create a wave effect
WaveData CalculateWave(float3 positionOS, float waveSpeed, float waveFrequency, float waveAmplitude)
{
    // Contains the wave data to be returned
    WaveData output;
    
    // Get the world space position of the vertex
    float3 positionWS = GetVertexPositionInputs(positionOS).positionWS;
    
    // Calculate the new vertex position
    float finalWavePosition = CalculateWaveHeight(positionOS, waveSpeed, waveFrequency, waveAmplitude);

    // Return the output wave position
    output.waveVertexPosition = float3(positionOS.x, finalWavePosition, positionOS.z);
    
    // This code is used to generate correct normals for the displaced vertices. To achieve this we need to
    // calculate the positions of neighboring surface points and recalculate the normal from those points.
    float sampleDistance = 0.005; // This controls how far away the neighboring points are sampled from the current vertex

    // Calculate the neighboring vertex positions' wave heights
    float nSampleHeight = CalculateWaveHeight(positionOS, float3(sampleDistance, 0, 0), waveSpeed, waveFrequency, waveAmplitude);
    float sSampleHeight = CalculateWaveHeight(positionOS, float3(-sampleDistance, 0, 0), waveSpeed, waveFrequency, waveAmplitude);
    float eSampleHeight = CalculateWaveHeight(positionOS, float3(0, 0, sampleDistance), waveSpeed, waveFrequency, waveAmplitude);
    float wSampleHeight = CalculateWaveHeight(positionOS, float3(0, 0, -sampleDistance), waveSpeed, waveFrequency, waveAmplitude);
    
    // The neighboring vertex positions
    float3 nSamplePos = float3(positionOS.x + sampleDistance, nSampleHeight, positionOS.z);
    float3 sSamplePos = float3(positionOS.x - sampleDistance, sSampleHeight, positionOS.z);
    float3 eSamplePos = float3(positionOS.x, eSampleHeight, positionOS.z + sampleDistance);
    float3 wSamplePos = float3(positionOS.x, wSampleHeight, positionOS.z - sampleDistance);

    float3 sn = normalize(sSamplePos - nSamplePos);
    float3 ew = normalize(eSamplePos - wSamplePos);
    
    // Calculate the normal by cross product of the neighboring vertex positions
    float3 finalNormal = normalize(cross(sn, ew));
    
    // Return the output wave normal in world space
    output.waveVertexNormal = mul(finalNormal, unity_ObjectToWorld);
    
    return output;
}