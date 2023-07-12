using UnityEditor;

namespace UnityEditor
{
    public class StreamlineMaterialProperties : ShaderGUI
    {
        //------------------------------------------------------
        internal const string PropAutoRenderQueue = "_AutoRenderQueue";

        // -----------------------------------------------------
        // Specify only those that use the MaterialEditor method as their UI.
        // Material materialProperties
        protected MaterialProperty ExampleProperty = null;
        internal const string PropExampleProperty = "_exampleProperty";
        
        // Surface Options
        public MaterialProperty WorkflowMode;
        internal const string PropWorkflowMode = "_WorkflowMode";
        
        public MaterialProperty SurfaceType;
        internal const string PropSurfaceType = "_Surface";
        
        public MaterialProperty BlendMode;
        internal const string PropBlendMode = "_Blend";
        
        public MaterialProperty CullMode;
        internal const string PropCullMode = "_Cull";
        
        public MaterialProperty AlphaClip;
        internal const string PropAlphaClip = "_AlphaClip";
        
        public MaterialProperty AlphaClipThreshold;
        internal const string PropAlphaClipThreshold = "_Cutoff";

        public MaterialProperty ReceiveShadows;
        internal const string PropReceiveShadows = "_ReceiveShadows";
        
        public MaterialProperty SrcBlend;
        internal const string PropSrcBlend = "_SrcBlend";
        
        public MaterialProperty DstBlend;
        internal const string PropDstBlend = "_DstBlend";
        
        public MaterialProperty ZWrite;
        internal const string PropZWrite = "_ZWrite";


        // Default Properties
        public MaterialProperty BaseMap;
        internal const string PropBaseMap = "_BaseMap";
        
        public MaterialProperty BaseColour;
        internal const string PropBaseColour = "_BaseColor";
        
        public MaterialProperty Metallic;
        internal const string PropMetallic = "_Metallic";
        
        public MaterialProperty Smoothness;
        internal const string PropSmoothness = "_Smoothness";

        public MaterialProperty SmoothnessMapChannel;
        internal const string PropSmoothnessMapChannel = "_SmoothnessTextureChannel";
        
        public MaterialProperty MetallicGlossMap;
        internal const string PropMetallicGlossMap = "_MetallicGlossMap";
        
        public MaterialProperty SpecGlossMap;
        internal const string PropSpecGlossMap = "_SpecGlossMap";
        
        public MaterialProperty SpecColor;
        internal const string PropSpecColor = "_SpecColor";
        
        public MaterialProperty NormalMap;
        internal const string PropNormalMap = "_BumpMap";
        
        public MaterialProperty NormalScale;
        internal const string PropNormalScale = "_BumpScale";


        // Lighting Options
        public MaterialProperty LightingRampMap;
        internal const string PropLightingRampMap = "_LightingRampMap";
        
        public MaterialProperty SpecularRampMap;
        internal const string PropSpecularRampMap = "_SpecularRampMap";
        
        // Advanced Options
        public MaterialProperty SpecularHighlights;
        internal const string PropSpecularHighlights = "_SpecularHighlights";
        
        public MaterialProperty EnvironmentReflections;
        internal const string PropEnvironmentReflections = "_EnvironmentReflections";
        
        //------------------------------------------------------

        internal void FindProperties(MaterialProperty[] properties)
        {
            // Append false at the end of the FindProperty() call if there is a chance that the property is not in the material
            ExampleProperty = FindProperty(PropExampleProperty, properties, false);
            ExampleProperty = FindProperty("_exampleProperty", properties, false);
            
            // Surface Options
            WorkflowMode = FindProperty(PropWorkflowMode, properties);
            SurfaceType = FindProperty(PropSurfaceType, properties);
            BlendMode = FindProperty(PropBlendMode, properties);
            CullMode = FindProperty(PropCullMode, properties);
            AlphaClip = FindProperty(PropAlphaClip, properties);
            AlphaClipThreshold = FindProperty(PropAlphaClipThreshold, properties);
            ReceiveShadows = FindProperty(PropReceiveShadows, properties);
            SrcBlend = FindProperty(PropSrcBlend, properties);
            DstBlend = FindProperty(PropDstBlend, properties);
            ZWrite = FindProperty(PropZWrite, properties);

            // Default Properties
            BaseMap = FindProperty(PropBaseMap, properties);
            BaseColour = FindProperty(PropBaseColour, properties);
            Metallic = FindProperty(PropMetallic, properties);
            Smoothness = FindProperty(PropSmoothness, properties);
            SmoothnessMapChannel = FindProperty(PropSmoothnessMapChannel, properties);
            MetallicGlossMap = FindProperty(PropMetallicGlossMap, properties);
            SpecGlossMap = FindProperty(PropSpecGlossMap, properties);
            SpecColor = FindProperty(PropSpecColor, properties);
            NormalMap = FindProperty(PropNormalMap, properties);
            NormalScale = FindProperty(PropNormalScale, properties);
            
            // Lighting Options
            LightingRampMap = FindProperty(PropLightingRampMap, properties);
            SpecularRampMap = FindProperty(PropSpecularRampMap, properties);
            
            // Advanced Options
            SpecularHighlights = FindProperty(PropSpecularHighlights, properties);
            EnvironmentReflections = FindProperty(PropEnvironmentReflections, properties);

        }
    }
}