using UnityEditor;
using UnityEngine;

namespace GUIStreamline
{
    public static class DefaultPropertyDrawer
    {
        public static void Draw(MaterialEditor editor, Material material, MaterialProperty property, string label,
            string tooltip)
        {
            var guiContent = new GUIContent(label, tooltip);
            editor.ShaderProperty(property, guiContent);
        }
    }
}