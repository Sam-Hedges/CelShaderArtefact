using UnityEngine;

namespace GUIStreamline.Properties
{
    public class FloatProperty
    {
        internal GUIContent GuiContent;
        internal readonly string PropertyName;
        internal float DefaultValue;
        internal FloatProperty(string label, string tooltip, string propName, float defaultValue)
        {
            GuiContent = new GUIContent(label, tooltip + " The default value is " + defaultValue + ".");
            PropertyName = propName;
            DefaultValue = defaultValue;
        }
    }
}