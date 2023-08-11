// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/RaymarchSphere"
{
    Properties
    {
        _SphereCenter("Sphere Center", Vector) = (0,0,0,0)
        _SphereRadius("Sphere Radius", Float) = 1
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float4 _SphereCenter;
            float _SphereRadius;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float RaySphereIntersect(float3 ro, float3 rd, float3 sc, float r)
            {
                float3 oc = ro - sc;
                float a = dot(rd, rd);
                float b = 2.0 * dot(oc, rd);
                float c = dot(oc, oc) - (r * r);
                float discriminant = b * b - 4 * a * c;
                if (discriminant > 0.0) {
                    return (-b - sqrt(discriminant)) / (2.0 * a);
                }
                return -1.0;
            }

            half4 frag (v2f i) : SV_Target
            {
                float3 ro = _WorldSpaceCameraPos; // Ray Origin
    
                // Constructing a basic ray direction
                float3 rayScreenSpace = float3(i.uv * 2 - 1, -1);
                float4 rayClipSpace = float4(rayScreenSpace, 1);
                float4 rayWorldSpace = UnityObjectToClipPos(rayClipSpace);
                float3 rd = normalize(rayWorldSpace.xyz / rayWorldSpace.w - ro); // Ray Direction

                float hit = RaySphereIntersect(ro, rd, _SphereCenter.xyz, _SphereRadius);
                if (hit > 0.0) {
                    return half4(1, 0, 0, 1); // Sphere color
                } else {
                    return half4(0, 0, 0, 1); // Background color
                }
            }
            ENDCG
        }
    }
}
