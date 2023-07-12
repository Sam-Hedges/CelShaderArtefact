using GUIStreamline.Properties;
using UnityEngine;

namespace UnityEditor
{
    public class StreamlineMaterialStyles
    {
        // Foldout Contents
        public readonly GUIContent ExampleFoldout = EditorGUIUtility.TrTextContent("Text",
            "Tooltip");
        
        public readonly GUIContent SurfaceOptionsFoldout = EditorGUIUtility.TrTextContent("Surface Options",
            "Controls how URP renders the material.");
        
        public readonly GUIContent LightingInputsFoldout = EditorGUIUtility.TrTextContent("Lighting",
            "Tooltip");
        
        public readonly GUIContent DefaultInputsFoldout = EditorGUIUtility.TrTextContent("Surface Inputs",
            "Tooltip");
        
        public readonly GUIContent AdvancedOptionsFoldout = EditorGUIUtility.TrTextContent("Advanced Options",
            "Tooltip");
        
        // Text Surface Settings
        public readonly GUIContent WorkflowModeText = new("Workflow Mode", "Choose a workflow that suits your textures. Either Metallic or Specular.");
        public readonly GUIContent SurfaceTypeText = new("Surface Type", "Select a surface type for the material. Opaque surfaces fully obstruct light while transparent surfaces allow light to pass through via the alpha channel.");
        public readonly GUIContent BlendModeText = new("Blend Mode", "Controls how the color of the transparent surface blends with the Material color of the background.");
        public readonly GUIContent CullModeText = new("Render Face", "Specifies which faces of the mesh to render. Front faces are the default. Back faces can be used for skyboxes. Both makes the geometry double sided.");
        public readonly GUIContent AlphaClipText = new("Alpha Clip", "When enabled, the Material is clipped based on the alpha value. This is useful for masking out parts of a Material.");
        public readonly GUIContent AlphaClipThresholdText = new("Alpha Clip Threshold", "The alpha value above which pixels are discarded. Ranges from 0 to 1.");
        public readonly GUIContent ReceiveShadowsText = new("Receive Shadows", "When enabled, other Gameobjects in the scene can cast shadows on this Gameobject.");

        // Text Contents
        public readonly GUIContent exampleText =
            new GUIContent("Text", "Tooltip");
            
        // Texture materialProperties
        public readonly GUIContent BaseMapText = new("Base Map", "Base Color : Texture(sRGB) × Color(RGB) Default:White");
        public readonly GUIContent NormalMapText = new("Normal Map", "Normal Map : Texture(Non-SRGB) × Vector(RGB) Default:None");
        public readonly GUIContent NormalScaleText = new("Normal Scale", "Normal Map Scale : Float Default:1");
        public readonly GUIContent MetallicMapText = new("Metallic Gloss Map", "");
        public readonly GUIContent SpecularMapText = new("Specular Gloss Map", "");
        public readonly string[] MetallicSmoothnessChannelNames = { "Metallic Alpha", "Albedo Alpha" };
        public readonly string[] SpecularSmoothnessChannelNames = { "Specular Alpha", "Albedo Alpha" };
        public readonly GUIContent SmoothnessMapChannelText = new("Source", "Specifies where to sample a smoothness map from. By default, uses the alpha channel for your map.");
        public readonly RangeProperty MetallicText = new RangeProperty(
            label: "Metallic",
            tooltip: "Metallic",
            propName: StreamlineMaterialProperties.PropMetallic, defaultValue: 0, min: 0.0f, max: 1.0f);
        public readonly RangeProperty SmoothnessText = new RangeProperty(
            label: "Smoothness",
            tooltip: "Smoothness",
            propName: StreamlineMaterialProperties.PropSmoothness, defaultValue: 0, min: 0.0f, max: 1.0f);
        
        // Advanced Options
        public readonly GUIContent SpecularHighlightsText = new("Specular Highlights", "When enabled, the Material reflects the shine from direct lighting.");
        public readonly GUIContent EnvironmentReflectionsText = new("Environment Reflections", "When enabled, the Material samples reflections from the nearest Reflection Probes or Lighting Probe.");
        public readonly GUIContent AutoRenderQueueText = new("Auto Render Queue", "When enabled, rendering order is determined by system automatically.");
        public readonly GUIContent RenderQueueText = new("Render Queue", "Rendering order in the scene.");

        // Range materialProperties
        public readonly RangeProperty exampleRangePropertyText = new RangeProperty(
            label: "Label",
            tooltip: "Tooltip",
            propName: StreamlineMaterialProperties.PropExampleProperty, defaultValue: 0, min: 0.0f, max: 4.0f);

        // Float materialProperties
        public readonly FloatProperty exampleFloatPropertyText = new FloatProperty(label: "Base Speed (Time)",
            tooltip:
            "Specifies the base update speed of scroll animation. If the value is 1, it will be updated in 1 second. Specifying " +
            "a value of 2 results in twice the speed of a value of 1, so it will be updated in 0.5 seconds.",
            propName: "_Base_Speed", defaultValue: 0);

        // Color materialProperties
        public readonly ColourProperty exampleColourPropertyText = new ColourProperty(
            label: "Shifting Target Color",
            tooltip: "Target color above, must be specified in HDR.",
            propName: "_ViewShift", isHDR: true);
        
    }
}