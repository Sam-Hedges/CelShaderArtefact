using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEngine.Rendering;

namespace GUIStreamline
{
    internal struct StreamlineMaterialHeaderObject
    {
        /// <summary><see cref="GUIContent"></see> that will be rendered on the <see cref="StreamlineMaterialHeaderObject"></see></summary>
        public GUIContent headerTitle { get; set; }
        
        /// <summary>The bitmask for this scope</summary>
        public uint expandable { get; set; }
        
        /// <summary>The action that will draw the controls for this scope</summary>
        public Action<Material> drawMaterialScope { get; set; }
        
    }
}