// Based on the unity sample gradient node modified to work only two sample points
// https://docs.unity3d.com/Packages/com.unity.shadergraph@12.1/manual/Sample-Gradient-Node.html
float4 SampleBasicGradient(float Time, float4 colour1, float4 colour2, float position)
{
    float4 colourPos = saturate(Time / position) * step(1, 2);
    float4 colour = lerp(0, colour1, lerp(colourPos, step(0.01, colourPos), 1));
    float4 colourPos2 = saturate((Time - position) / (1 - position)) * step(2, 2);
    return lerp(colour, colour2, lerp(colourPos2, step(0.01, colourPos2), 1));
}

// Rotates value of input UV around a reference point defined by input Center by the amount of input Rotation.
// The unit for rotation angle can be selected by the parameter Unit.
// https://docs.unity3d.com/Packages/com.unity.shadergraph@12.1/manual/Rotate-Node.html
float2 Rotate(float2 UV, float2 Center, float Rotation)
{
    Rotation = Rotation * (3.1415926f/180.0f);
    UV -= Center;
    float s = sin(Rotation);
    float c = cos(Rotation);
    float2x2 rMatrix = float2x2(c, -s, s, c);
    rMatrix *= 0.5;
    rMatrix += 0.5;
    rMatrix = rMatrix * 2 - 1;
    UV.xy = mul(UV.xy, rMatrix);
    UV += Center;
    return UV;
}

// Applies a spherical warping effect similar to a fisheye camera lens to the value of input UV. The center reference
// point of the warping effect is defined by input Center and the overall strength of the effect is defined by the value
// of input Strength. Input Offset can be used to offset the individual channels of the result.
// https://docs.unity3d.com/Packages/com.unity.shadergraph@12.1/manual/Spherize-Node.html
float2 Spherize(float2 UV, float2 Center, float Strength, float2 Offset)
{
    float2 delta = UV - Center;
    float delta2 = dot(delta.xy, delta.xy);
    float delta4 = delta2 * delta2;
    float2 delta_offset = delta4 * Strength;
    return UV + delta * delta_offset + Offset;
}

// Generates a gradient, or Perlin, noise based on input UV. The scale of the generated noise is controlled by input Scale.
// https://docs.unity3d.com/Packages/com.unity.shadergraph@12.1/manual/Gradient-Noise-Node.html
float2 GradientNoiseDir(float2 p)
{
    p = p % 289;
    float x = (34 * p.x + 1) * p.x % 289 + p.y;
    x = (34 * x + 1) * x % 289;
    x = frac(x / 41) * 2 - 1;
    return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
}
float GradientNoisePos(float2 p)
{
    float2 ip = floor(p);
    float2 fp = frac(p);
    float d00 = dot(GradientNoiseDir(ip), fp);
    float d01 = dot(GradientNoiseDir(ip + float2(0, 1)), fp - float2(0, 1));
    float d10 = dot(GradientNoiseDir(ip + float2(1, 0)), fp - float2(1, 0));
    float d11 = dot(GradientNoiseDir(ip + float2(1, 1)), fp - float2(1, 1));
    fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
    return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
}
float GradientNoise(float2 UV, float Scale)
{
    return GradientNoisePos(UV * Scale) + 0.5;
}

inline float unity_noise_randomValue (float2 uv)
{
    return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
}


// Generates a simple, or Value, noise based on input UV. The scale of the generated noise is controlled by input Scale.
// https://docs.unity3d.com/Packages/com.unity.shadergraph@12.1/manual/Simple-Noise-Node.html
inline float NoiseInterpolate (float a, float b, float t)
{
    return (1.0-t)*a + (t*b);
}
inline float ValueNoise (float2 uv)
{
    float2 i = floor(uv);
    float2 f = frac(uv);
    f = f * f * (3.0 - 2.0 * f);

    uv = abs(frac(uv) - 0.5);
    float2 c0 = i + float2(0.0, 0.0);
    float2 c1 = i + float2(1.0, 0.0);
    float2 c2 = i + float2(0.0, 1.0);
    float2 c3 = i + float2(1.0, 1.0);
    float r0 = unity_noise_randomValue(c0);
    float r1 = unity_noise_randomValue(c1);
    float r2 = unity_noise_randomValue(c2);
    float r3 = unity_noise_randomValue(c3);

    float bottomOfGrid = NoiseInterpolate(r0, r1, f.x);
    float topOfGrid = NoiseInterpolate(r2, r3, f.x);
    float t = NoiseInterpolate(bottomOfGrid, topOfGrid, f.y);
    return t;
}
float SimpleNoise(float2 UV, float Scale)
{
    float t = 0.0;

    float freq = pow(2.0, float(0));
    float amp = pow(0.5, float(3-0));
    t += ValueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

    freq = pow(2.0, float(1));
    amp = pow(0.5, float(3-1));
    t += ValueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

    freq = pow(2.0, float(2));
    amp = pow(0.5, float(3-2));
    t += ValueNoise(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

    return t;
}

// Returns a value between the x and y components of input Out Min Max based on the linear interpolation of the value
// of input In between the x and y components of input In Min Max.
// https://docs.unity3d.com/Packages/com.unity.shadergraph@12.1/manual/Remap-Node.html
float4 Remap(float4 In, float2 InMinMax, float2 OutMinMax)
{
    return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
}

// Creates a mask from values in input In equal to input Mask Color. Input Range can be used to define a wider range
// of values around input Mask Color to create the mask. Colors within this range will return 1, otherwise the node will
// return 0. Input Fuzziness can be used to soften the edges around the selection similar to anti-aliasing.
// https://docs.unity3d.com/Packages/com.unity.shadergraph@12.1/manual/Color-Mask-Node.html
float4 ColourMask(float3 In, float3 MaskColour, float Range, float Fuzziness)
{
    float Distance = distance(MaskColour, In);
    return saturate(1 - (Distance - Range) / max(Fuzziness, 1e-5));
}

// Creates a normal map from a height value defined by input Input with a strength defined by input Strength.
// https://docs.unity3d.com/Packages/com.unity.shadergraph@12.1/manual/Normal-From-Height-Node.html
float3 NormalFromHeight(float In, float Strength, float3 Position, float3x3 TangentMatrix)
{
    float3 worldDerivativeX = ddx(Position);
    float3 worldDerivativeY = ddy(Position);

    float3 crossX = cross(TangentMatrix[2].xyz, worldDerivativeX);
    float3 crossY = cross(worldDerivativeY, TangentMatrix[2].xyz);
    float d = dot(worldDerivativeX, crossY);
    float sgn = d < 0.0 ? (-1.f) : 1.f;
    float surface = sgn / max(0.00000000000001192093f, abs(d));

    float dHdx = ddx(In);
    float dHdy = ddy(In);
    float3 surfGrad = surface * (dHdx*crossY + dHdy*crossX);
    return normalize(TangentMatrix[2].xyz - (Strength * surfGrad));
}

// Converts a height map defined by input Texture into a normal map. UV values and sampler state can be defined by inputs
// UV and Sampler respectively. If nothing is connected to these ports they will use default values from the inputs. See
// Port Bindings for more information.The strength of the created normal map can be defined by inputs Offset and Strength,
// where Offset defines the maximum distance of a normal detail and Strength acts as a multiplier to the result.
// If you experience texture sampling errors while using this node in a graph which includes Custom Function Nodes or
// Sub Graphs, you can resolve them by upgrading to version 10.3 or later.
// https://docs.unity3d.com/Packages/com.unity.shadergraph@12.1/manual/Normal-From-Texture-Node.html
float3 NormalFromTexture(TEXTURE2D_PARAM(textureMap, textureSample), float2 UV, float Offset, float Strength)
{
    float offset = pow(Offset, 3) * 0.1;
    float2 offsetU = float2(UV.x + offset, UV.y);
    float2 offsetV = float2(UV.x, UV.y + offset);
    float normalSample = SAMPLE_TEXTURE2D(textureMap, textureSample, UV).x;
    float uSample = SAMPLE_TEXTURE2D(textureMap, textureSample, offsetU).x;
    float vSample = SAMPLE_TEXTURE2D(textureMap, textureSample, offsetV).x;
    float3 va = float3(1, 0, (uSample - normalSample) * Strength);
    float3 vb = float3(0, 1, (vSample - normalSample) * Strength);
    return normalize(cross(va, vb));
}