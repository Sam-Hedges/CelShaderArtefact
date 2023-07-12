// This function creates an inwards parallax effect on a surface making it appear as if it has depth by outputting a modified set of UV coordinates
/*
void GlitterParallaxUV_float(float ParallaxHeightScale, float3 ViewDirection, UnityTexture2D HeightTex, float2 UV, UnitySamplerState SampleState, out float2 Out)
{
    // The number of layers is calculated based on the view direction of the camera. A lerp function is used to
    // smoothly interpolate between a minimum and maximum number of layers based on the absolute dot product between the
    // view direction of the camera and a vector pointing upwards in the z direction.
    const float minLayers = 30;
    const float maxLayers = 60;
    float numLayers = lerp(maxLayers, minLayers, abs(dot(float3(0, 0, 1), ViewDirection)));

    // The number of steps is calculated based on the number of layers, and the height and step size for each step are calculated.
    // The height starts at 1.0 and is decreased by the step size for each iteration of the loop.
    float numSteps = numLayers;//60.0f; // How many steps the UV ray tracing should take
    float height = 1.0;
    float step = 1.0 / numSteps;

    // The offset is set to the original UV coordinates, and the height map texture is sampled at that offset.
    float2 offset = UV.xy;
    float4 HeightMap = HeightTex.Sample(SampleState, offset);

    // The delta is calculated by multiplying the view direction by the parallax height scale and dividing by the
    // product of the view direction's z component and the number of steps. This delta value represents the change
    // in UV coordinates for each step along the view direction.
    float2 delta = ViewDirection.xy * ParallaxHeightScale / (ViewDirection.z * numSteps);
  
    // Finds UV offset
    // A loop iterates through each step, checking whether the height of the height map at the current offset is less than
    // the current height value. If it is, the height value is decreased by the step size, and the offset is incremented by
    // the delta value. The height map is then sampled again at the new offset. This process continues until the height value
    // is greater than or equal to the height map value or the loop reaches the maximum number of steps.
    for (float i = 0.0f; i < numSteps; i++) {
        if (HeightMap.r < height) {
            height -= step;
            offset += delta;
            HeightMap = HeightTex.Sample(SampleState, offset);
        } else {
            break;
        }
    }

    // Finally, the output variable Out is set to the final offset value, which represents
    // the new UV coordinates that have been adjusted based on the parallax effect.
    Out = offset;
}
*/
void GlitterParallaxUV_float(float ParallaxHeightScale, float3 ViewDirection, UnityTexture2D HeightTex, float2 UV, UnitySamplerState SampleState, out float2 Out)
{
    // determine required number of layers
    const float minLayers = 30;
    const float maxLayers = 60;
    float numLayers = lerp(maxLayers, minLayers, abs(dot(float3(0, 0, 1), ViewDirection)));
  
    float2 offset = UV.xy;
    float4 HeightMap = HeightTex.Sample(SampleState, offset);
  
    float start = 0.0;
    float end = 1.0;
    float depth = 0.0;
  
    // binary search for correct depth
    for (int i = 0; i < 10; i++) {
        depth = (start + end) / 2.0;
        float2 delta = ViewDirection.xy * ParallaxHeightScale * depth / (ViewDirection.z * numLayers);
        float4 HeightMapSample = HeightTex.Sample(SampleState, offset + delta);
        if (HeightMapSample.r > depth) {
            start = depth;
        } else {
            end = depth;
        }
    }
  
    // set final output offset
    Out = offset + ViewDirection.xy * ParallaxHeightScale * depth / ViewDirection.z;
}