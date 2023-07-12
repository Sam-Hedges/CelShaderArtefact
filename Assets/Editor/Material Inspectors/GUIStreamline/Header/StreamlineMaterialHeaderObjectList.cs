using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace GUIStreamline
{

    /// <summary>
    /// Collection to store <see cref="StreamlineMaterialHeaderObject"></see>
    /// </summary>
    public class StreamlineMaterialHeaderObjectList
    {
        internal readonly uint DefaultExpandedState;
        internal readonly List<StreamlineMaterialHeaderObject> Items = new();

        /// <summary>
        /// Constructor that initializes it with the default expanded state for the internal scopes
        /// </summary>
        /// <param name="defaultExpandedState">By default, everything is expanded</param>
        public StreamlineMaterialHeaderObjectList(uint defaultExpandedState = uint.MaxValue)
        {
            DefaultExpandedState = defaultExpandedState;
        }

        /// <summary>
        /// Registers a <see cref="StreamlineMaterialHeaderObject"/> into the list
        /// </summary>
        /// <param name="title"><see cref="GUIContent"/> The title of the scope</param>
        /// <param name="expandable">The mask identifying the scope</param>
        /// <param name="action">The action that will be drawn if the scope is expanded</param>
        /// <param name="isTransparent">Flag transparent material header should be drawn</param>        /// 
        /// <param name="isTessellation">Flag Tessellation material header should be drawn</param>        /// 
        public void RegisterHeaderScope<TEnum>(GUIContent title, TEnum expandable, Action<Material> action)
            where TEnum : struct, IConvertible
        {
            Items.Add(new StreamlineMaterialHeaderObject()
            {
                headerTitle = title,
                expandable = Convert.ToUInt32(expandable),
                drawMaterialScope = action
            }); 
        }

        /// <summary>
        /// Draws all the <see cref="StreamlineMaterialHeaderObject"/> with its information stored
        /// </summary>
        /// <param name="materialEditor"><see cref="MaterialEditor"/></param>
        /// <param name="material"><see cref="Material"/></param>
        public void DrawHeaders(MaterialEditor materialEditor, Material material)
        {
            if (material == null)
                throw new ArgumentNullException(nameof(material));

            if (materialEditor == null)
                throw new ArgumentNullException(nameof(materialEditor));

            foreach (var item in Items)
            {
                using (var header = new StreamlineMaterialHeader(
                    item.headerTitle,
                    item.expandable,
                    materialEditor,
                    defaultExpandedState: DefaultExpandedState))
                {
                    if (!header.expanded)
                        continue;

                    item.drawMaterialScope(material);

                    EditorGUILayout.Space();
                }
            }
        }
    }

}
