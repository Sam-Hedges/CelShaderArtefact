Shader "SamHedges/MyLit" {
    
    // Properties are options set per material, exposed by the material inspector
    Properties {
        [Header(Surface options)]
        
        _BaseMap("[Gradient] Color", 2D) = "white" {}
        _BaseColor("Tint", Color) = (1, 1, 1, 1)
        
        [Toggle(_ALPHATEST_ON)] _AlphaTestToggle ("Alpha Clipping", Float) = 0
        _Cutoff("Alpha cutout threshold", Range(0, 1)) = 0.5
        
        [Toggle(_NORMALMAP)] _NormalMapToggle ("Normal Mapping", Float) = 0
        [NoScaleOffset][Normal] _NormalMap("Normal", 2D) = "bump" {}
        _NormalStrength("Normal strength", Range(0, 1)) = 1
        
    	[Gradient(512, HDR)] _LightingRampMap("Lighting Ramp", 2D) = "white" {}
    	
        _RimThreshold ("Rim Threshold", Float) = 1
    	_RimStrength ("Rim Strength", Float) = 1
    	_RimAmount ("Rim Amount", Float) = 1
        _EdgeDiffuse ("Edge Diffuse", Float) = 1
    	_EdgeSpecular ("Edge Specular", Float) = 1
    	_EdgeSpecularOffset ("Edge Specular Offset", Float) = 1
    	_EdgeDistanceAttenuation ("Edge Distance Attenuation", Float) = 1
    	_EdgeShadowAttenuation ("Edge Shado wAttenuation", Float) = 1
    	_EdgeRim ("Edge Rim", Float) = 1
    	_EdgeRimOffset ("Edge Rim Offset", Float) = 1
    	
        [NoScaleOffset] _MetalnessMask("Metalness mask", 2D) = "white" {}
        _Metalness("Metalness strength", Range(0, 1)) = 0
        
        [Toggle(_SPECULARHIGHLIGHTS)] _SpecularSetupToggle("Specular Highlights", Float) = 1
        [NoScaleOffset] _SpecularMap("Specular map", 2D) = "white" {}
        _SpecularTint("Specular tint", Color) = (1, 1, 1, 1)
        [NoScaleOffset] _SmoothnessMask("Smoothness mask", 2D) = "white" {}
        _Smoothness("Smoothness multiplier", Range(0, 1)) = 0.5
        
        [Toggle(_EMISSION)] _Emission ("Emission", Float) = 0
        [NoScaleOffset] _EmissionMap("Emission map", 2D) = "white" {}
        [HDR] _EmissionTint("Emission tint", Color) = (0, 0, 0, 0)
        
        [HideInInspector] _Cull("Cull mode", Float) = 2 // 2 is "Back"
        [HideInInspector] _SourceBlend("Source blend", Float) = 0
        [HideInInspector] _DestBlend("Destination blend", Float) = 0
        [HideInInspector] _ZWrite("ZWrite", Float) = 0
        [HideInInspector] _SurfaceType("Surface type", Float) = 0
        [HideInInspector] _BlendType("Blend type", Float) = 0
        [HideInInspector] _FaceRenderingMode("Face rendering type", Float) = 0
    }
	
	// Sub-shaders allow for different behaviour and options for different pipelines and platforms
    SubShader {
    	// Tags are shared by all passed in this subshader
        Tags {"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"} 
        
    	HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

		CBUFFER_START(UnityPerMaterial)
		#include "MyLitCommon.hlsl" 
		CBUFFER_END
		ENDHLSL

    	// Shader can have several passes which are used to render different data about the material and
		// each pass has it's own vertex and fragment function and shader variant keywords
        Pass {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            Blend[_SourceBlend][_DestBlend]
            ZWrite[_ZWrite] 
            Cull[_Cull]

            HLSLPROGRAM

            // Keywords are like boolean constants you enable using a #define command.
            // Shaders make extensive use of keywords to turn on and off different features
			// This keyword is used to toggle highlights on in the UniversalFragmentBlinnPhong method
			// Material Keywords
            #pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local _ALPHA_CUTOUT
            #pragma shader_feature_local _DOUBLE_SIDED_NORMALS
            #pragma shader_feature_local_fragment _SPECULAR_SETUP
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON

            #pragma shader_feature_local _SPECULARHIGHLIGHTS
            
			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			//#pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
			#pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
			//#pragma shader_feature_local_fragment _ _SPECGLOSSMAP _SPECULAR_Colour
			#pragma shader_feature_local_fragment _ _SPECGLOSSMAP
			#define _SPECULAR_Colour // always on
			#pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA

			// URP Keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING // v10+ only, renamed from "_MIXED_LIGHTING_SUBTRACTIVE"
			#pragma multi_compile _ SHADOWS_SHADOWMASK // v10+ only

			// Unity Keywords
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile_fog

			// GPU Instancing (not supported)
			#pragma multi_compile_instancing
            
            // Register our programmable stage functions
			// #pragma has variety of uses related to shader metadata
			// vertex and fragment sub-commands register the corresponding functions
			// to the containing pass; the names MUST MATCH those within the hlsl file
            #pragma vertex Vertex
            #pragma fragment Fragment

            // Include our hlsl file
            #include "MyLitForwardLitPass.hlsl"
            
            ENDHLSL
        }

        Pass {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}
			
        	ZWrite On
			ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM

			// Material Keywords
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			// GPU Instancing
			#pragma multi_compile_instancing
			//#pragma multi_compile _ DOTS_INSTANCING_ON

			// Universal Pipeline Keywords
			// (v11+) This is used during shadow map generation to differentiate between directional and punctual (point/spot) 
			// light shadows, as they use different formulas to apply Normal Bias
			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            
            #pragma shader_feature_local _ALPHA_CUTOUT
            #pragma shader_feature_local _DOUBLE_SIDED_NORMALS

            #pragma vertex Vertex
            #pragma fragment Fragment

            #include "MyLitShadowCasterPass.hlsl"
            ENDHLSL
        }
        
        // DepthOnly, used for Camera Depth Texture (if cannot copy depth buffer instead, and the DepthNormals below isn't used)
		Pass {
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ColorMask 0
			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			#pragma vertex DepthOnlyVertex
			#pragma fragment DepthOnlyFragment

			// Material Keywords
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			// GPU Instancing
			#pragma multi_compile_instancing
			//#pragma multi_compile _ DOTS_INSTANCING_ON
			
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
			
			ENDHLSL
		}

		// DepthNormals, used for SSAO & other custom renderer features that request it  
		Pass {
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormals" }

			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			#pragma vertex DepthNormalsVertex
			#pragma fragment DepthNormalsFragment

			// Material Keywords
			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			// GPU Instancing
			#pragma multi_compile_instancing
			//#pragma multi_compile _ DOTS_INSTANCING_ON
			
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"
			
			ENDHLSL
		}
    }
	
	CustomEditor "Chroma"
    CustomEditor "MyLitCustomInspector"
}
