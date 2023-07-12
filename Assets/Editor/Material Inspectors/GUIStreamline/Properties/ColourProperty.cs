using UnityEngine;

namespace GUIStreamline.Properties
{
    public class ColourProperty
    {
        internal GUIContent GuiContent;
        internal readonly string PropertyName;
        internal bool IsHDR;

        internal ColourProperty(string label, string tooltip, string propName, bool isHDR)
        {
            GuiContent = new GUIContent(label, tooltip );
            PropertyName = propName;
            IsHDR = isHDR;
        }
    }
}