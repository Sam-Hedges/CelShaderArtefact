Shader "SamHedges/Water" {
	
	// Properties are options set per material, exposed by the material inspector
		Properties {
			[Header(Surface Options)]
			// [MainColor] & [MainTexture] allows Material.color & Material.mainTexture in C# to use the correct properties
			_ColourMap("Albedo", 2D) = "white" {}
			_ColourTint("Colour", Color) = (1,1,1,1)
		 	_Smoothness("Smoothness", Float) = 0
			_NormalMap("Normal Map", 2D) = "bump" {}
			_BumpStrength("Bump Strength", Float) = 0.5
			_DetailScale("Detail Scale", Float) = 0.2
			_DetailStrength("Detail Strength", Range(0,1)) = 0.2
			_ScrollSpeed("Scroll Speed", Float) = 1
			
			[Header(Wave Options)]
			_WaveFrequency("Frequency", Float) = 0
			_WaveAmplitude("Amplitude", Float) = 0
			_WaveSpeed("Speed", Float) = 0
		}
	
		
	// Sub-shaders allow for different behaviour and options for different pipelines and platforms
	Subshader {
		// Tags are shared by all passed in this subshader
		Tags {"RenderPipeline" = "UniversalPipeline"}

		// Shader can have several passes which are used to render different data about the material and
		// each pass has it's own vertex and fragment function and shader variant keywords
		Pass {
			Name "ForwardLit" // For debugging 
			Tags {"LightMode" = "UniversalForward"} // Pass specific tags
			// "UniversalForward" tells unity this is the main lighting pass of this shader

			HLSLPROGRAM // Begin HLSL code

			// Keywords are like boolean constants you enable using a #define command.
            // Shaders make extensive use of keywords to turn on and off different features
			// This keyword is used to toggle highlights on in the UniversalFragmentBlinnPhong method
			#define _SPECULAR_COLOR

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

			#pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma _ADDITIONAL_LIGHT_SHADOWS
			#pragma _SHADOWS_SOFT
			#pragma LIGHTMAP_ON
			#pragma DIRLIGHTMAP_COMBINED
			#pragma LIGHTMAP_SHADOW_MIXING
			#pragma SHADOWS_SHADOWMASK
			#pragma _SCREEN_SPACE_OCCLUSION
			
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
            Name "ShadowCaster" // For debugging 
            Tags{"LightMode" = "ShadowCaster"}
			// "ShadowCaster" tells unity this is the shadow casting pass of this shader
			
			// This command directs the renderer to write no color as it's not needed for shadows
			ColorMask 0
			
            HLSLPROGRAM
            
            #pragma vertex Vertex
            #pragma fragment Fragment

            // Include our hlsl file
            #include "MyLitShadowCasterPass.hlsl"
            
            ENDHLSL
        }
	}
}
