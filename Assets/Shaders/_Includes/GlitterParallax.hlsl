void GlitterParallaxUV_float(float ParallaxHeightScale, float3 ViewDirection, UnityTexture2D HeightMap, float2 UV, UnitySamplerState SampleState, out float2 Out)
{
    // Get the height from the height map   
    float4 heightMap = HeightMap.Sample(SampleState, UV);

    // Calculate the offset based on the view direction and height
    float offset = heightMap.r * ParallaxHeightScale * dot(ViewDirection, float3(0, 0, 1));
    
    // Apply the offset to the UV coordinates
    Out = UV + offset * normalize(ViewDirection.xy);
}