using UnityEngine;

namespace GUIStreamline.Properties
{
    public class RangeProperty
    {
        internal GUIContent GuiContent;
        internal readonly string PropertyName;
        internal float Min;
        internal float Max;
        internal float DefaultValue;

        internal RangeProperty(string label, string tooltip, string propName, float defaultValue, float min, float max )
        {
            GuiContent = new GUIContent(label,tooltip + " The range is from " +  min + " to " + max + ". " + "The default value is " + defaultValue + ".");
            PropertyName = propName;
            Min = min;
            Max = max;
            DefaultValue = defaultValue;
        }
    }
}