using System.Collections.Generic;
using GUIStreamline.Drawers;
using UnityEngine;

namespace UnityEditor {
public class CustomDrawers {
    public readonly Dictionary<string, GradientDrawer> gradient = new Dictionary<string, GradientDrawer>();
    public readonly CurveDrawer curve = new CurveDrawer();
    public readonly Vector2Drawer vector2 = new Vector2Drawer();
    public readonly Vector3Drawer vector3 = new Vector3Drawer();
    public readonly Dictionary<Vector2, MinMaxDrawer> minMax = new Dictionary<Vector2, MinMaxDrawer>();
}
}