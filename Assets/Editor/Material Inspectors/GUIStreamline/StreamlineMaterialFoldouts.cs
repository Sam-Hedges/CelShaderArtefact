using static UnityEditor.GUIStreamline;
using UnityEditor;
using UnityEngine;

namespace GUIStreamline
{
    public class StreamlineMaterialFoldouts
    {
        private Material _material;
        private StreamlineMaterialProperties _materialProperties;
        private StreamlineMaterialStyles _materialStyles;
        private MaterialEditor _materialEditor;
        private StreamlineMaterialDrawers _materialDrawers;
        private CustomDrawers _customDrawers;

        /// <summary>
        /// Constructor to set parameters needed to define a custom foldout GUI delegate methods to be used within <see cref="StreamlineMaterialHeader"></see>
        /// </summary>
        /// <param name="material">The current instance of <see cref="_material"></see></param>
        /// <param name="materialProperties">The current instance of <see cref="StreamlineMaterialProperties"></see></param>
        /// <param name="materialStyles">The current instance of <see cref="StreamlineMaterialStyles"></see> that contains Foldout Contents and Property Content</param>
        public StreamlineMaterialFoldouts(Material material, StreamlineMaterialProperties materialProperties, StreamlineMaterialStyles materialStyles, MaterialEditor materialEditor, StreamlineMaterialDrawers materialDrawers)
        {
            _material = material;
            _materialProperties = materialProperties;
            _materialStyles = materialStyles;
            _materialEditor = materialEditor;
            _materialDrawers = materialDrawers;
            _customDrawers = new CustomDrawers();
        }
        
        static void Line()
        {
            GUILayout.Box("", GUILayout.ExpandWidth(true), GUILayout.Height(1));
        }

        protected static bool Foldout(bool display, GUIContent title)
        {

            return EditorGUILayout.Foldout(display, title, true );
        }

        static bool FoldoutSubMenu(bool display, GUIContent title)
        {
            return EditorGUILayout.Foldout(display, title, true);
        }

        public void DrawLightingInputs(Material material)
        {
            _materialDrawers.GradientProperty(_materialProperties.LightingRampMap, _materialEditor, material, _customDrawers, DefaultPropertyDrawer.Draw);
            
            _materialDrawers.GradientProperty(_materialProperties.SpecularRampMap, _materialEditor, material, _customDrawers, DefaultPropertyDrawer.Draw);
        }
        public void DrawDefaultInputs(Material material)
        {
            _materialEditor.TexturePropertySingleLine(_materialStyles.BaseMapText, _materialProperties.BaseMap, _materialProperties.BaseColour);

            //EditorGUILayout.Space();
            
            string[] smoothnessChannelNames;
            bool hasGlossMap = false;
            if (_materialProperties.WorkflowMode == null ||
                (WorkflowMode)_materialProperties.WorkflowMode.floatValue == WorkflowMode.Metallic)
            {
                hasGlossMap = _materialProperties.MetallicGlossMap.textureValue != null;
                smoothnessChannelNames = _materialStyles.MetallicSmoothnessChannelNames;
                _materialEditor.TexturePropertySingleLine(_materialStyles.MetallicMapText, _materialProperties.MetallicGlossMap,
                    hasGlossMap ? null : _materialProperties.Metallic);
            }
            else
            {
                hasGlossMap = _materialProperties.SpecGlossMap.textureValue != null;
                smoothnessChannelNames = _materialStyles.SpecularSmoothnessChannelNames;
                BaseShaderGUI.TextureColorProps(_materialEditor, _materialStyles.SpecularMapText, _materialProperties.SpecGlossMap,
                    hasGlossMap ? null : _materialProperties.SpecColor);
            }
            
            EditorGUI.indentLevel += 2;

            _materialEditor.ShaderProperty(_materialProperties.Smoothness, _materialStyles.SmoothnessText.GuiContent.text);

            if (_materialProperties.SmoothnessMapChannel != null) // smoothness channel
            {
                var opaque = _materialProperties.SurfaceType.floatValue == 0f;
                EditorGUI.indentLevel++;
                EditorGUI.showMixedValue = _materialProperties.SmoothnessMapChannel.hasMixedValue;
                if (opaque)
                {
                    EditorGUI.BeginChangeCheck();
                    var smoothnessSource = (int)_materialProperties.SmoothnessMapChannel.floatValue;
                    smoothnessSource = EditorGUILayout.Popup(_materialStyles.SmoothnessMapChannelText, smoothnessSource, smoothnessChannelNames);
                    if (EditorGUI.EndChangeCheck())
                        _materialProperties.SmoothnessMapChannel.floatValue = smoothnessSource;
                }
                else
                {
                    EditorGUI.BeginDisabledGroup(true);
                    EditorGUILayout.Popup(_materialStyles.SmoothnessMapChannelText, 0, smoothnessChannelNames);
                    EditorGUI.EndDisabledGroup();
                }
                EditorGUI.showMixedValue = false;
                EditorGUI.indentLevel--;
            }
            EditorGUI.indentLevel -= 2;
            
            _materialEditor.TexturePropertySingleLine(_materialStyles.NormalMapText, _materialProperties.NormalMap, _materialProperties.NormalScale);

            //_materialEditor.RangeProperty(_materialProperties.Smoothness, _materialStyles.SmoothnessText.GuiContent.text);
            
            //_materialEditor.RangeProperty(_materialProperties.Metallic, _materialStyles.MetallicText.GuiContent.text);
            
            /*
            //v.2.0.7 Synchronize _Color to _BaseColor.
            if (_material.HasProperty("_Color"))
            {
                _material.SetColor("_Color", material.GetColor("_BaseColor"));
            }
            //

            EditorGUI.indentLevel += 2;
            var applyTo1st = GUI_Toggle(material, Styles.applyTo1stShademapText, ShaderPropUse_BaseAs1st, MaterialGetInt(material, ShaderPropUse_BaseAs1st) != 0);
            EditorGUI.indentLevel -= 2;





            if (applyTo1st)
            {

                EditorGUI.indentLevel += 2;
                m_MaterialEditor.ColorProperty( firstShadeColor, Styles.firstShadeColorText.text);
                EditorGUI.indentLevel -= 2;

            }
            else
            {
                m_MaterialEditor.TexturePropertySingleLine(Styles.firstShadeColorText, firstShadeMap, firstShadeColor);
            }
            //            EditorGUI.EndDisabledGroup();

            EditorGUI.indentLevel+=2;
            var applyTo2nd =  GUI_Toggle(material, Styles.applyTo2ndShademapText, ShaderPropUse_1stAs2nd, MaterialGetInt(material, ShaderPropUse_1stAs2nd) != 0);
            EditorGUI.indentLevel-=2;


            if (applyTo2nd)
            {
                EditorGUI.indentLevel += 2;
                m_MaterialEditor.ColorProperty(secondShadeColor, Styles.secondShadeColorText.text);
                EditorGUI.indentLevel -= 2;
            }
            else
            {
                m_MaterialEditor.TexturePropertySingleLine(Styles.secondShadeColorText, secondShadeMap, secondShadeColor);
            }
            EditorGUILayout.Space();

            /*
            _NormalMap_Foldout = FoldoutSubMenu(_NormalMap_Foldout, Styles.normalMapFoldout);
            if (_NormalMap_Foldout)
            {
            }
            */
            /*
            _ShadowControlMaps_Foldout = FoldoutSubMenu(_ShadowControlMaps_Foldout, Styles.shadowControlMapFoldout);
            if (_ShadowControlMaps_Foldout)
            {
                EditorGUI.indentLevel++;
                GUI_ShadowControlMaps(material);
                EditorGUI.indentLevel--;
                EditorGUILayout.Space();
            }
            */
        }
    }
}
