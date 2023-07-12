using System;
using GUIStreamline;
using UnityEngine;
using UnityEditor.Rendering.Universal.ShaderGUI;
using RenderQueue = UnityEngine.Rendering.RenderQueue;

namespace UnityEditor
{
    // This class acts as the main GUI script that determines what sub gui is needed (eg. URP, HDRP, Legacy, Shadergraph, etc)
    public class GUIStreamline : BaseShaderGUI
    {
        private MaterialEditor _materialEditor;
        private Material _material;
        private readonly StreamlineMaterialProperties _materialProperties = new();
        private readonly StreamlineMaterialStyles _materialStyles = new();
        private StreamlineMaterialFoldouts _materialFoldouts;
        private StreamlineMaterialDrawers _materialDrawers;
        
        // "&" is a bitwise AND operator, it compares each bit and only sets an output bit if both inputs are set
        // "~" is a bitwise NOT operator, it flips the value of each bit, so that a 0 becomes a 1, and a 1 becomes a 0
        // The overall effect of uint.MaxValue & ~(uint)Expandable.SurfaceOptions is to clear the bits in uint.MaxValue
        // that are not set in (uint)Expandable.SurfaceOptions, and leave the rest of the bits unchanged. The resulting value is then stored in the materialObjectList variable.
        readonly StreamlineMaterialHeaderObjectList _materialObjectList = new StreamlineMaterialHeaderObjectList(uint.MaxValue & ~(uint)Expandable.SurfaceOptions);
        
        // Variables which must be retrieved from shader at the beginning of GUI
        internal int _autoRenderQueue = 1;
        internal int _renderQueue = (int)RenderQueue.Geometry;
        
        // Variables which just need to be held
        internal bool FirstTimeApply = true;
        internal WorkflowMode m_WorkflowMode;
        internal SurfaceType m_SurfaceType;
        internal BlendMode m_BlendMode;
        internal CullMode m_CullMode;
        
        #region Enums

        // The << operator shifts its left-hand operand left by the number of bits defined by its right-hand operand
        // The increment of 1 per Enum in the right-hand operand will result in the value of the left-hand operand
        // doubling each time, starting at 1
        /// <summary>
        /// This Enum is used to display each drop-down menu, with the elements of the enum as headers
        /// </summary>
        [Flags]
        protected enum Expandable
        {
            SurfaceOptions = 1 << 0,
            LightingInputs = 1 << 1,
            DefaultInputs = 1 << 2,
            AdvancedOptions = 1 << 3
        }
        
        public enum WorkflowMode
        {
            Specular, Metallic
        }
        
        public enum SurfaceType
        {
            Opaque, Transparent
        }
        
        public enum BlendMode
        {
            Alpha, Premultiply, Additive, Multiply
        }
        
        public enum CullMode
        {
            Both, Back, Front
        }

        #endregion
        
        // To define a custom shader GUI use the methods of materialEditor to controls for the materialProperties array.
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            _materialEditor = materialEditor;
            _material = materialEditor.target as Material;
            _materialDrawers = new StreamlineMaterialDrawers(_materialEditor, _materialProperties, _materialStyles);
            _materialFoldouts = new StreamlineMaterialFoldouts(_material, _materialProperties, _materialStyles, _materialEditor, _materialDrawers);
            

            // Fields often appear wider than the minimum width, since Editor GUI controls are usually set to occupy a Rect that
            // expands to fill the available horizontal space. Within this Rect, the field will take up all the space not used by the EditorGUIUtility.labelWidth
            // This enforces the minimum width of the field.
            EditorGUIUtility.fieldWidth = 0;
            
            if (FirstTimeApply)
            {
                _materialProperties.FindProperties(properties);
                OnOpenGUI();
                FirstTimeApply = false;
            }
            
            // _autoRenderQueue = StreamlineMaterialDrawers.MaterialGetInt(_material, StreamlineMaterialProperties.PropAutoRenderQueue);

            EditorGUI.BeginChangeCheck();
            
            ShaderPropertiesGUI(_materialEditor, _material);

            // ApplyQueueAndRenderType(_material);
                
            if (EditorGUI.EndChangeCheck())
            {
                _materialEditor.PropertiesChanged();
            }
        }
        
        // material changed check
        public override void ValidateMaterial(Material material)
        {
            SetMaterialKeywords(material, LitGUI.SetMaterialKeywords);
        }
        //*/
        
        public override void OnClosed(Material material)
        {
            base.OnClosed(material);
        }
        
        void OnOpenGUI()
        {
            _materialObjectList.RegisterHeaderScope(_materialStyles.SurfaceOptionsFoldout, Expandable.SurfaceOptions, DrawSurfaceOptions);
            _materialObjectList.RegisterHeaderScope(_materialStyles.LightingInputsFoldout, Expandable.LightingInputs, _materialFoldouts.DrawLightingInputs);
            _materialObjectList.RegisterHeaderScope(_materialStyles.DefaultInputsFoldout, Expandable.DefaultInputs, _materialFoldouts.DrawDefaultInputs);
            _materialObjectList.RegisterHeaderScope(_materialStyles.AdvancedOptionsFoldout, Expandable.AdvancedOptions, DrawAdvancedOptions);
        }
        
        void ShaderPropertiesGUI(MaterialEditor materialEditor, Material material)
        {
            DrawHeaders(materialEditor, material);
        }
        
        void DrawHeaders(MaterialEditor materialEditor, Material material)
        {
            if (material == null)
                throw new ArgumentNullException(nameof(material));

            if (materialEditor == null)
                throw new ArgumentNullException(nameof(materialEditor));

            foreach (var item in _materialObjectList.Items)
            {
                using (var header = new StreamlineMaterialHeader(
                           item.headerTitle,
                           item.expandable,
                           materialEditor,
                           defaultExpandedState: _materialObjectList.DefaultExpandedState))
                {
                    if (!header.expanded)
                        continue;
                    
                    item.drawMaterialScope(material);

                    EditorGUILayout.Space();
                }
            } 
        }
        
        // material main surface options
        public override void DrawSurfaceOptions(Material material)
        {
            GUI_SetWorkflowMode(material);
            GUI_SetSurfaceType(material);
            GUI_SetBlendMode(material);
            GUI_SetCullMode(material);
            _materialEditor.ShaderProperty(_materialProperties.AlphaClip, _materialStyles.AlphaClipText);
            if ((_materialProperties.AlphaClip != null) && (_materialProperties.AlphaClipThreshold != null) && (_materialProperties.AlphaClip.floatValue == 1))
                _materialEditor.ShaderProperty(_materialProperties.AlphaClipThreshold, _materialStyles.AlphaClipThresholdText, 1);
            _materialEditor.ShaderProperty(_materialProperties.ReceiveShadows, _materialStyles.ReceiveShadowsText);
        }
        
        // Material Advanced Options
        public override void DrawAdvancedOptions(Material material)
        {
            // Draw the default shader properties.
            _materialEditor.ShaderProperty(_materialProperties.SpecularHighlights, _materialStyles.SpecularHighlightsText);
            _materialEditor.ShaderProperty(_materialProperties.EnvironmentReflections, _materialStyles.EnvironmentReflectionsText);
            _materialEditor.RenderQueueField();
            _materialEditor.EnableInstancingField();
            _materialEditor.DoubleSidedGIField();
        }
        
        
        void GUI_SetWorkflowMode(Material material)
        {
            int _WorkflowMode_Setting = MaterialGetInt(material, _materialProperties.WorkflowMode);
            
            // Convert it to Enum format and store it in the offlineMode variable.
            if ((int)WorkflowMode.Specular == _WorkflowMode_Setting)
            {
                m_WorkflowMode = WorkflowMode.Specular;
                //_materialProperties.Metallic.floatValue = 0;
            }
            else
            {
                m_WorkflowMode = WorkflowMode.Metallic;
            }
            
            // GUI description with EnumPopup.
            m_WorkflowMode = (WorkflowMode)EditorGUILayout.EnumPopup(_materialStyles.WorkflowModeText, m_WorkflowMode);
            
            // If the value changes, write to the material.
            if (_WorkflowMode_Setting != (int)m_WorkflowMode)
            {
                switch (m_WorkflowMode)
                {
                    case WorkflowMode.Specular:
                        MaterialSetInt(material, _materialProperties.WorkflowMode, 0);
                        //_materialProperties.Metallic.floatValue = 0;
                        break;
                    case WorkflowMode.Metallic:
                        MaterialSetInt(material, _materialProperties.WorkflowMode, 1);
                        break;
                    default:
                        MaterialSetInt(material, _materialProperties.WorkflowMode, 0);
                        //_materialProperties.Metallic.floatValue = 0;
                        break;
                }
            }
            _materialEditor.Repaint();
        }
        void GUI_SetSurfaceType(Material material)
        {
            int _SurfaceType_Setting = MaterialGetInt(material, _materialProperties.SurfaceType);
            //int renderQueue = material.shader.renderQueue;
            
            //CoreUtils.SetKeyword(material, ShaderKeywordStrings._SURFACE_TYPE_TRANSPARENT, _SurfaceType_Setting == (int)SurfaceType.Transparent);
            
            // Convert it to Enum format and store it in the offlineMode variable.
            if ((int)SurfaceType.Opaque == _SurfaceType_Setting)
            {
                m_SurfaceType = SurfaceType.Opaque;
                //material.SetOverrideTag("RenderType", "Opaque");
                //material.DisableKeyword(ShaderKeywordStrings._ALPHAPREMULTIPLY_ON);
                //material.DisableKeyword(ShaderKeywordStrings._SURFACE_TYPE_TRANSPARENT);
                //renderQueue = (int)RenderQueue.Geometry;
            }
            else
            {
                m_SurfaceType = SurfaceType.Transparent;
                //material.SetOverrideTag("RenderType", "Transparent");
                //material.EnableKeyword(ShaderKeywordStrings._SURFACE_TYPE_TRANSPARENT);
                //material.DisableKeyword(ShaderKeywordStrings._ALPHAPREMULTIPLY_ON);
                //material.DisableKeyword(ShaderKeywordStrings._ALPHAMODULATE_ON);
                //renderQueue = (int)RenderQueue.Transparent;
            }
            
            // GUI description with EnumPopup.
            m_SurfaceType = (SurfaceType)EditorGUILayout.EnumPopup(_materialStyles.SurfaceTypeText, m_SurfaceType);
            
            // If the value changes, write to the material.
            if (_SurfaceType_Setting != (int)m_SurfaceType)
            {
                switch (m_SurfaceType)
                {
                    case SurfaceType.Opaque:
                        MaterialSetInt(material, _materialProperties.SurfaceType, 0);
                        //material.SetOverrideTag("RenderType", "Opaque");
                        //material.DisableKeyword(ShaderKeywordStrings._ALPHAPREMULTIPLY_ON);
                        //material.DisableKeyword(ShaderKeywordStrings._SURFACE_TYPE_TRANSPARENT);
                        //renderQueue = (int)RenderQueue.Geometry;
                        break;
                    case SurfaceType.Transparent:
                        MaterialSetInt(material, _materialProperties.SurfaceType, 1);
                        ////material.SetOverrideTag("RenderType", "Transparent");
                        //material.EnableKeyword(ShaderKeywordStrings._SURFACE_TYPE_TRANSPARENT);
                        //material.DisableKeyword(ShaderKeywordStrings._ALPHAPREMULTIPLY_ON);
                        //material.DisableKeyword(ShaderKeywordStrings._ALPHAMODULATE_ON);
                        //renderQueue = (int)RenderQueue.Transparent;
                        break;
                    default:
                        MaterialSetInt(material, _materialProperties.SurfaceType, 0);
                        //material.SetOverrideTag("RenderType", "Opaque");
                        //material.DisableKeyword(ShaderKeywordStrings._ALPHAPREMULTIPLY_ON);
                        //material.DisableKeyword(ShaderKeywordStrings._SURFACE_TYPE_TRANSPARENT);
                        //renderQueue = (int)RenderQueue.Geometry;
                        break;
                }
            }
        }

        void GUI_SetBlendMode(Material material)
        {
            if (m_SurfaceType == SurfaceType.Opaque)
            {
                MaterialSetInt(material, _materialProperties.BlendMode, 0);
                //material.DisableKeyword(ShaderKeywordStrings._ALPHAPREMULTIPLY_ON);
                //material.DisableKeyword(ShaderKeywordStrings._ALPHAMODULATE_ON);
                return;
            }
            
            int _BlendMode_Setting = MaterialGetInt(material, _materialProperties.BlendMode);
            
            // Convert it to Enum format and store it in the offlineMode variable.
            if ((int)BlendMode.Alpha == _BlendMode_Setting)
            {
                m_BlendMode = BlendMode.Alpha;
                //SetMaterialSrcDstBlendProperties(material,
                //UnityEngine.Rendering.BlendMode.SrcAlpha,
                //UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
            }
            else if ((int)BlendMode.Premultiply == _BlendMode_Setting)
            {
                m_BlendMode = BlendMode.Premultiply;
                //SetMaterialSrcDstBlendProperties(material,
                //UnityEngine.Rendering.BlendMode.One,
                //UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                //material.EnableKeyword(ShaderKeywordStrings._ALPHAPREMULTIPLY_ON);
            }
            else if ((int)BlendMode.Additive == _BlendMode_Setting)
            {
                m_BlendMode = BlendMode.Additive;
                //SetMaterialSrcDstBlendProperties(material,
                //UnityEngine.Rendering.BlendMode.SrcAlpha,
                //UnityEngine.Rendering.BlendMode.One);
            }
            else
            {
                m_BlendMode = BlendMode.Multiply;
                //SetMaterialSrcDstBlendProperties(material,
                //UnityEngine.Rendering.BlendMode.DstColor,
                //UnityEngine.Rendering.BlendMode.Zero);
                //material.EnableKeyword(ShaderKeywordStrings._ALPHAMODULATE_ON);
            }
            
            // GUI description with EnumPopup.
            m_BlendMode = (BlendMode)EditorGUILayout.EnumPopup(_materialStyles.BlendModeText, m_BlendMode);
            
            // If the value changes, write to the material.
            if (_BlendMode_Setting != (int)m_BlendMode)
            {
                switch (m_BlendMode)
                {
                    case BlendMode.Alpha:
                        MaterialSetInt(material, _materialProperties.BlendMode, 0);
                        //SetMaterialSrcDstBlendProperties(material,
                        //    UnityEngine.Rendering.BlendMode.SrcAlpha,
                        //    UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                        break;
                    case BlendMode.Premultiply:
                        MaterialSetInt(material, _materialProperties.BlendMode, 1);
                        //SetMaterialSrcDstBlendProperties(material,
                        //    UnityEngine.Rendering.BlendMode.One,
                        //    UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                        //material.EnableKeyword(ShaderKeywordStrings._ALPHAPREMULTIPLY_ON);
                        break;
                    case BlendMode.Additive:
                        MaterialSetInt(material, _materialProperties.BlendMode, 2);
                        //SetMaterialSrcDstBlendProperties(material,
                        //    UnityEngine.Rendering.BlendMode.SrcAlpha,
                        //    UnityEngine.Rendering.BlendMode.One);
                        break;
                    case BlendMode.Multiply:
                        MaterialSetInt(material, _materialProperties.BlendMode, 3);
                        //SetMaterialSrcDstBlendProperties(material,
                        //    UnityEngine.Rendering.BlendMode.DstColor,
                        //    UnityEngine.Rendering.BlendMode.Zero);
                        //material.EnableKeyword(ShaderKeywordStrings._ALPHAMODULATE_ON);
                        break;
                    default:
                        MaterialSetInt(material, _materialProperties.BlendMode, 0);
                        //SetMaterialSrcDstBlendProperties(material,
                        //    UnityEngine.Rendering.BlendMode.SrcAlpha,
                        //    UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                        break;
                }
            }
        }

        void GUI_SetCullMode(Material material)
        {
            int _CullMode_Setting = MaterialGetInt(material, _materialProperties.CullMode);
            
            // Convert it to Enum format and store it in the offlineMode variable.
            if ((int)CullMode.Both == _CullMode_Setting)
            {
                m_CullMode = CullMode.Both;
            }
            else if ((int)CullMode.Back == _CullMode_Setting)
            {
                m_CullMode = CullMode.Back;
            }
            else
            {
                m_CullMode = CullMode.Front;
            }
            
            // GUI description with EnumPopup.
            m_CullMode = (CullMode)EditorGUILayout.EnumPopup(_materialStyles.CullModeText, m_CullMode);
            
            // If the value changes, write to the material.
            if (_CullMode_Setting != (int)m_CullMode)
            {
                switch (m_CullMode)
                {
                    case CullMode.Both:
                        MaterialSetInt(material, _materialProperties.CullMode, 0);
                        break;
                    case CullMode.Back:
                        MaterialSetInt(material, _materialProperties.CullMode, 1);
                        break;
                    case CullMode.Front:
                        MaterialSetInt(material, _materialProperties.CullMode, 2);
                        break;
                    default:
                        MaterialSetInt(material, _materialProperties.CullMode, 2);
                        break;
                }
            }
        }
        
        
        internal static int  MaterialGetInt(Material material, string prop )
        {
            return (int)material.GetFloat(prop);
        }
        internal static void MaterialSetInt(Material material, string prop, int value)
        {
            material.SetFloat(prop, value);
        }
        
        internal static int  MaterialGetInt(Material material, MaterialProperty prop )
        {
            return (int)material.GetFloat(prop.name);
        }
        internal static void MaterialSetInt(Material material, MaterialProperty prop, int value)
        {
            material.SetFloat(prop.name, value);
        }
        
        /*
        #region Material Validation
        
        static void SetMaterialKeywords(Material material, Action<Material> shadingModelFunc = null, Action<Material> shaderFunc = null)
        {
            UpdateMaterialSurfaceOptions(material, automaticRenderQueue: true);

            // Setup double sided GI based on Cull state
            if (material.HasProperty(Property.CullMode))
                material.doubleSidedGI = (RenderFace)material.GetFloat(Property.CullMode) != RenderFace.Front;

            // Temporary fix for lightmapping. TODO: to be replaced with attribute tag.
            if (material.HasProperty("_MainTex"))
            {
                material.SetTexture("_MainTex", material.GetTexture("_BaseMap"));
                material.SetTextureScale("_MainTex", material.GetTextureScale("_BaseMap"));
                material.SetTextureOffset("_MainTex", material.GetTextureOffset("_BaseMap"));
            }
            if (material.HasProperty("_Color"))
                material.SetColor("_Color", material.GetColor("_BaseColor"));

            // Emission
            if (material.HasProperty(Property.EmissionColor))
                MaterialEditor.FixupEmissiveFlag(material);

            bool shouldEmissionBeEnabled =
                (material.globalIlluminationFlags & MaterialGlobalIlluminationFlags.EmissiveIsBlack) == 0;

            // Not sure what this is used for, I don't see this property declared by any Unity shader in our repo...
            // I'm guessing it is some kind of legacy material upgrade support thing?  Or maybe just dead code now...
            if (material.HasProperty("_EmissionEnabled") && !shouldEmissionBeEnabled)
                shouldEmissionBeEnabled = material.GetFloat("_EmissionEnabled") >= 0.5f;

            CoreUtils.SetKeyword(material, ShaderKeywordStrings._EMISSION, shouldEmissionBeEnabled);

            // Normal Map
            if (material.HasProperty("_BumpMap"))
                CoreUtils.SetKeyword(material, ShaderKeywordStrings._NORMALMAP, material.GetTexture("_BumpMap"));

            // Shader specific keyword functions
            shadingModelFunc?.Invoke(material);
            shaderFunc?.Invoke(material);
        }
        
        // this function is shared with ShaderGraph Lit/Unlit GUIs and also the hand-written GUIs
        void UpdateMaterialSurfaceOptions(Material material, bool automaticRenderQueue)
        {
            // Setup blending - consistent across all Universal RP shaders
            SetupMaterialBlendModeInternal(material, out int renderQueue);

            // apply automatic render queue
            if (automaticRenderQueue && (renderQueue != material.renderQueue))
                material.renderQueue = renderQueue;

            bool isShaderGraph = material.IsShaderGraph();

            // Cast Shadows
            bool castShadows = true;
            if (material.HasProperty(Property.CastShadows))
            {
                castShadows = (material.GetFloat(Property.CastShadows) != 0.0f);
            }
            else
            {
                if (isShaderGraph)
                {
                    // Lit.shadergraph or Unlit.shadergraph, but no material control defined
                    // enable the pass in the material, so shader can decide...
                    castShadows = true;
                }
                else
                {
                    // Lit.shader or Unlit.shader -- set based on transparency
                    castShadows = Rendering.Universal.ShaderGUI.LitGUI.IsOpaque(material);
                }
            }
            material.SetShaderPassEnabled("ShadowCaster", castShadows);

            // Receive Shadows
            if (material.HasProperty(Property.ReceiveShadows))
                CoreUtils.SetKeyword(material, ShaderKeywordStrings._RECEIVE_SHADOWS_OFF, material.GetFloat(Property.ReceiveShadows) == 0.0f);
        }
        
        void SetupMaterialBlendModeInternal(Material material, out int automaticRenderQueue)
        {
            if (material == null)
                throw new ArgumentNullException("material");

            bool alphaClip = false;
            if (material.HasProperty(Property.AlphaClip))
                alphaClip = material.GetFloat(Property.AlphaClip) >= 0.5;
            CoreUtils.SetKeyword(material, ShaderKeywordStrings._ALPHATEST_ON, alphaClip);

            // default is to use the shader render queue
            int renderQueue = material.shader.renderQueue;
            material.SetOverrideTag("RenderType", "");      // clear override tag
            if (material.HasProperty(Property.SurfaceType))
            {
                SurfaceType surfaceType = (SurfaceType)material.GetFloat(Property.SurfaceType);
                bool zwrite = false;
                CoreUtils.SetKeyword(material, ShaderKeywordStrings._SURFACE_TYPE_TRANSPARENT, surfaceType == SurfaceType.Transparent);
                if (surfaceType == SurfaceType.Opaque)
                {
                    if (alphaClip)
                    {
                        renderQueue = (int)RenderQueue.AlphaTest;
                        material.SetOverrideTag("RenderType", "TransparentCutout");
                    }
                    else
                    {
                        renderQueue = (int)RenderQueue.Geometry;
                        material.SetOverrideTag("RenderType", "Opaque");
                    }

                    SetMaterialSrcDstBlendProperties(material, UnityEngine.Rendering.BlendMode.One, UnityEngine.Rendering.BlendMode.Zero);
                    zwrite = true;
                    material.DisableKeyword(ShaderKeywordStrings._ALPHAPREMULTIPLY_ON);
                    material.DisableKeyword(ShaderKeywordStrings._SURFACE_TYPE_TRANSPARENT);
                }
                else // SurfaceType Transparent
                {
                    BlendMode blendMode = (BlendMode)material.GetFloat(Property.BlendMode);

                    material.DisableKeyword(ShaderKeywordStrings._ALPHAPREMULTIPLY_ON);
                    material.DisableKeyword(ShaderKeywordStrings._ALPHAMODULATE_ON);

                    // Specific Transparent Mode Settings
                    switch (blendMode)
                    {
                        case BlendMode.Alpha:
                            SetMaterialSrcDstBlendProperties(material,
                                UnityEngine.Rendering.BlendMode.SrcAlpha,
                                UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                            break;
                        case BlendMode.Premultiply:
                            SetMaterialSrcDstBlendProperties(material,
                                UnityEngine.Rendering.BlendMode.One,
                                UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                            material.EnableKeyword(ShaderKeywordStrings._ALPHAPREMULTIPLY_ON);
                            break;
                        case BlendMode.Additive:
                            SetMaterialSrcDstBlendProperties(material,
                                UnityEngine.Rendering.BlendMode.SrcAlpha,
                                UnityEngine.Rendering.BlendMode.One);
                            break;
                        case BlendMode.Multiply:
                            SetMaterialSrcDstBlendProperties(material,
                                UnityEngine.Rendering.BlendMode.DstColor,
                                UnityEngine.Rendering.BlendMode.Zero);
                            material.EnableKeyword(ShaderKeywordStrings._ALPHAMODULATE_ON);
                            break;
                    }

                    // General Transparent Material Settings
                    material.SetOverrideTag("RenderType", "Transparent");
                    zwrite = false;
                    material.EnableKeyword(ShaderKeywordStrings._SURFACE_TYPE_TRANSPARENT);
                    renderQueue = (int)RenderQueue.Transparent;
                }

                // check for override enum
                if (material.HasProperty(Property.ZWriteControl))
                {
                    var zwriteControl = (UnityEditor.Rendering.Universal.ShaderGraph.ZWriteControl)material.GetFloat(Property.ZWriteControl);
                    if (zwriteControl == UnityEditor.Rendering.Universal.ShaderGraph.ZWriteControl.ForceEnabled)
                        zwrite = true;
                    else if (zwriteControl == UnityEditor.Rendering.Universal.ShaderGraph.ZWriteControl.ForceDisabled)
                        zwrite = false;
                }
                SetMaterialZWriteProperty(material, zwrite);
                material.SetShaderPassEnabled("DepthOnly", zwrite);
            }
            else
            {
                // no surface type property -- must be hard-coded by the shadergraph,
                // so ensure the pass is enabled at the material level
                material.SetShaderPassEnabled("DepthOnly", true);
            }

            // must always apply queue offset, even if not set to material control
            if (material.HasProperty(Property.QueueOffset))
                renderQueue += (int)material.GetFloat(Property.QueueOffset);

            automaticRenderQueue = renderQueue;
        }
        
        void SetMaterialZWriteProperty(Material material, bool zwriteEnabled)
        {
            if (material.HasProperty(Property.ZWrite))
                material.SetFloat(Property.ZWrite, zwriteEnabled ? 1.0f : 0.0f);
        }

        
        #endregion
        */
    }
}