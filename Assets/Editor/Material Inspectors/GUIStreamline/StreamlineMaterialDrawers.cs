using System;
using System.Text.RegularExpressions;
using GUIStreamline.Drawers;
using GUIStreamline.Properties;
using UnityEditor;
using UnityEngine;
using DefaultDrawer =
    System.Action<UnityEditor.MaterialEditor, UnityEngine.Material, UnityEditor.MaterialProperty, string, string>;
using Color = UnityEngine.Color;

namespace GUIStreamline
{
    public class StreamlineMaterialDrawers
    {
        private readonly MaterialEditor _materialEditor;
        private StreamlineMaterialProperties _materialProperties;
        private StreamlineMaterialStyles _materialStyles;
    
        public StreamlineMaterialDrawers(MaterialEditor materialEditor, StreamlineMaterialProperties materialProperties, StreamlineMaterialStyles materialStyles)
        {
            _materialEditor = materialEditor;
            _materialProperties = materialProperties;
            _materialStyles = materialStyles;
        }
    
    
        bool ToggleShaderKeyword(Material material, string label, string keyword)
        {
            var isEnabled = material.IsKeywordEnabled(keyword);

            EditorGUI.BeginChangeCheck();
            var ret = EditorGUILayout.Toggle(label, isEnabled);
            if (EditorGUI.EndChangeCheck())
            {
                _materialEditor.RegisterPropertyChangeUndo(label);
                if ( ret == false )
                {
                    material.DisableKeyword(keyword);
                }
                else
                {
                    material.EnableKeyword(keyword);
                }
            }
            return ret;
        }
    
        float FloatProperty(Material material, FloatProperty floatProp)
        {
            float ret = material.GetFloat(floatProp.PropertyName);
            EditorGUI.BeginChangeCheck();
            ret = EditorGUILayout.FloatField(floatProp.GuiContent, ret );

            if (EditorGUI.EndChangeCheck())
            {
                _materialEditor.RegisterPropertyChangeUndo(floatProp.GuiContent.text);
                material.SetFloat(floatProp.PropertyName, ret);
            }
            return ret;
        }

        Color ColourProperty(Material material, ColourProperty colorProp)
        {
            Color ret = material.GetColor(colorProp.PropertyName);
            EditorGUI.BeginChangeCheck();

            ret = EditorGUILayout.ColorField(colorProp.GuiContent, ret, showEyedropper: true, showAlpha: true, hdr: colorProp.IsHDR);

            if (EditorGUI.EndChangeCheck())
            {
                _materialEditor.RegisterPropertyChangeUndo(colorProp.GuiContent.text);
                material.SetColor(colorProp.PropertyName, ret);
            }
            return ret;
        }
        float RangeProperty(Material material, RangeProperty rangeProp)
        {
            return RangeProperty(material, rangeProp.GuiContent, rangeProp.PropertyName, rangeProp.Min, rangeProp.Max);
        }
        float RangeProperty(Material material, GUIContent guiContent, string propName,  float min, float max )
        {
            float ret = material.GetFloat(propName);
            EditorGUI.BeginChangeCheck();
            ret = EditorGUILayout.Slider(guiContent, ret, min, max );

            if (EditorGUI.EndChangeCheck())
            {
                _materialEditor.RegisterPropertyChangeUndo(guiContent.text);
                material.SetFloat( propName, ret);
            }
            return ret;
        }

        bool Toggle(Material material, GUIContent guiContent, string prop, bool value)
        {
            EditorGUI.BeginChangeCheck();
            var ret = EditorGUILayout.Toggle(guiContent, value);
            if (EditorGUI.EndChangeCheck())
            {
                _materialEditor.RegisterPropertyChangeUndo(guiContent.text);
                MaterialSetInt(material, prop, ret ? 1 : 0);
            }
            return ret;
        }

        internal void SetRenderQueue(Material material, ref int autoRenderQueue, ref int renderQueue)
        {

            EditorGUILayout.BeginHorizontal();

            autoRenderQueue = Toggle(material, _materialStyles.AutoRenderQueueText, StreamlineMaterialProperties.PropAutoRenderQueue, autoRenderQueue == 1) ? 1 : 0;

            EditorGUILayout.EndHorizontal();
            EditorGUI.indentLevel++;
            EditorGUI.BeginDisabledGroup(autoRenderQueue == 1);
            renderQueue = EditorGUILayout.IntField(_materialStyles.RenderQueueText, material.renderQueue);
            EditorGUI.EndDisabledGroup();
            EditorGUI.indentLevel--;
        }

        internal void DoPopup(GUIContent label, MaterialProperty property, string[] options)
        {
            DoPopup(label, property, options, _materialEditor);
        }

        internal static void DoPopup(GUIContent label, MaterialProperty property, string[] options, MaterialEditor materialEditor)
        {
            if (property == null)
                throw new System.ArgumentNullException("property");

            EditorGUI.showMixedValue = property.hasMixedValue;

            var mode = property.floatValue;

            EditorGUI.BeginChangeCheck();
            mode = EditorGUILayout.Popup(label, (int)mode, options);
            if (EditorGUI.EndChangeCheck())
            {
                materialEditor.RegisterPropertyChangeUndo(label.text);
                property.floatValue = mode;
            }

            EditorGUI.showMixedValue = false;
        }
        
        internal static int  MaterialGetInt(Material material, string prop ) { return (int)material.GetFloat(prop); }
        internal static void MaterialSetInt(Material material, string prop, int value) { material.SetFloat(prop, value); }

    
    
        #region Custom Shader Attributes

        public void GradientProperty(MaterialProperty property, MaterialEditor editor, Material material, CustomDrawers drawers,
            DefaultDrawer defaultDraw)
        {
            var trimmedName = RemoveEverythingInBrackets(property.displayName);
            var tooltip = "";

            if (HasGradientAttribute(property)) 
            {
                EditorGUILayout.Space(18);
                int resolution = 512;
                bool hdr = false;
                string[] parameters = ExtractAttributeParameters(property.displayName, "Gradient");
                foreach (var parameter in parameters) {
                    if (int.TryParse(parameter, out var r)) {
                        resolution = r;
                    } else if (string.Equals(parameter.ToLower(), "hdr")) {
                        hdr = true;
                    }
                }

                string key = string.Join("_", parameters);
                if (!drawers.gradient.TryGetValue(key, out GradientDrawer drawer)) {
                    drawer = new GradientDrawer(resolution, hdr ? "hdr" : "");
                    drawers.gradient.Add(key, drawer);
                }

                drawer.OnGUI(Rect.zero, property, trimmedName, editor, tooltip);
            }
            else 
            {
                if (!IsPureAttribute(property.displayName)) 
                {
                    defaultDraw(editor, material, property, trimmedName, tooltip);
                }
            }
        }
    
        public void CurveProperty(MaterialProperty property, MaterialEditor editor, Material material, CustomDrawers drawers,
            DefaultDrawer defaultDraw)
        {
            var trimmedName = RemoveEverythingInBrackets(property.displayName);
            var tooltip = "";
            
            if (HasCurveAttribute(property)) 
            {
                EditorGUILayout.Space(18);
                drawers.curve.OnGUI(Rect.zero, property, trimmedName, editor, tooltip);
            }
            else 
            {
                if (!IsPureAttribute(property.displayName)) 
                {
                    defaultDraw(editor, material, property, trimmedName, tooltip);
                }
            }
        }
        
        public void MinMaxProperty(MaterialProperty property, MaterialEditor editor, Material material, CustomDrawers drawers,
            DefaultDrawer defaultDraw)
        {
            var trimmedName = RemoveEverythingInBrackets(property.displayName);
            var tooltip = "";
            
            if (HasMinMaxAttribute(property)) 
            {
                EditorGUILayout.Space(18);
                Vector2 range = new Vector2(0, 1);
                string[] parameters = ExtractAttributeParameters(property.displayName, "MinMax");
                if (parameters.Length == 0) {
                    // No parameters, use default range.
                } else if (parameters.Length == 1) {
                    range = new Vector2(0, float.Parse(parameters[0]));
                } else if (parameters.Length == 2) {
                    range = new Vector2(float.Parse(parameters[0]), float.Parse(parameters[1]));
                } else {
                    var message = $"MinMax attribute {trimmedName} has invalid parameters. Expected up to 2 " +
                                  $"parameters, but got {parameters.Length}. Material: {editor.target.name}, " +
                                  $"Property: {property.displayName}, Parameters: {string.Join(", ", parameters)}";
                    Log.M(message);
                }

                if (!drawers.minMax.TryGetValue(range, out MinMaxDrawer drawer)) {
                    drawer = new MinMaxDrawer(range, range);
                    drawers.minMax.Add(range, drawer);
                }

                drawer.OnGUI(Rect.zero, property, trimmedName, editor);
            }
            else 
            {
                if (!IsPureAttribute(property.displayName)) 
                {
                    defaultDraw(editor, material, property, trimmedName, tooltip);
                }
            }
        }
    
        private static bool HasMiniAttribute(string displayName) {
            var s = displayName.ToLower();
            return s.Contains("[mini]") || s.Contains("[m]");
        }

        private static bool HasGradientAttribute(MaterialProperty property) {
            return property.type == MaterialProperty.PropType.Texture && HasGradientSubstring(property.displayName);
        }

        private static bool HasGradientSubstring(string displayName) {
            var s = displayName.ToLower();
            return s.Contains("[gradient") || s.Contains("[g]") || s.Contains("[g(");
        }

        private static bool HasCurveAttribute(MaterialProperty property) {
            return property.type == MaterialProperty.PropType.Texture && HasCurveSubstring(property.displayName);
        }

        private static bool HasCurveSubstring(string displayName) {
            var s = displayName.ToLower();
            return s.Contains("[curve") || s.Contains("[c]") || s.Contains("[c(");
        }

        private static bool HasMinMaxAttribute(MaterialProperty property) {
            return property.type == MaterialProperty.PropType.Vector && HasMinMaxSubstring(property.displayName);
        }

        private static bool HasMinMaxSubstring(string displayName) {
            var s = displayName.ToLower();
            return s.Contains("[minmax") || s.Contains("[mm");
        }

        private static bool IsPureAttribute(string displayName) {
            var s = RemoveEverythingInBrackets(displayName);
            s = Regex.Replace(s, @"[\d\(\)]", "");
            return string.IsNullOrWhiteSpace(s);
        }

        private static int NumTabs(string displayName) {
            var s = displayName.ToLower();
            // Count occurrences of "[tab]" or "[t]".
            var count = Regex.Matches(s, @"\[tab\]|\[t\]").Count;
            return count;
        }

        // Comma-separated parameters.
        private static string[] ExtractAttributeParameters(string displayName, string attribute) {
            // Example string: "[MinMax(0, 1)][Header(Hello)]". Result: "0, 1".
            var regex = new Regex($@"(?i)\[{attribute}\((?<parameters>.*?)\)\]");
            var match = regex.Match(displayName);
            return match.Success ? match.Groups["parameters"].Value.Split(',') : Array.Empty<string>();
        }

        // Everything in round parenthesis.
        private static string ExtractAttributeParameter(string displayName, string attribute) {
            // Example string: "[Line(rgb(100, 90, 80))][Space(10)]". Result: "rgb(100, 90, 80)"
            var regex = new Regex($@"(?i)\[{attribute}\((?<parameter>.*?)\)\]");
            var match = regex.Match(displayName);
            return match.Success ? match.Groups["parameter"].Value : null;
        }

        private static string RemoveEverythingInBrackets(string s) {
            s = Regex.Replace(s, @" ?\[.*?\]", string.Empty);
            s = Regex.Replace(s, @" ?\{.*?\}", string.Empty);
            // Remove leading whitespace.
            s = Regex.Replace(s, @"^\s+", string.Empty);
            return s;
        }
    
        #endregion
    }
}