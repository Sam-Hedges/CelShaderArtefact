using System;
using UnityEditor;
using UnityEditor.Rendering;
using UnityEngine;


namespace GUIStreamline
{

    /// <summary>
    /// Create a toggleable header for material UI, must be used within a scope.
    /// <example>Example:
    /// <code>
    /// void OnGUI()
    /// {
    ///     using (var header = new MaterialHeader (text, ExpandBit, editor))
    ///     {
    ///         if (!header.expanded)
    ///             continue;
    ///         
    ///         EditorGUILayout.LabelField("Hello World !");
    ///     }
    /// }
    /// </code>
    /// </example>
    /// </summary>
    public struct StreamlineMaterialHeader : IDisposable
    {
        /// <summary>Indicates whether the header is expanded or not. Is true if the header is expanded, false otherwise.</summary>
        public readonly bool expanded;
        bool spaceAtEnd;
#if !UNITY_2020_1_OR_NEWER
        int oldIndentLevel;
#endif
        internal static void DrawSplitter(bool isBoxed = false)
        {
            var rect = GUILayoutUtility.GetRect(1f, 1f);
            float xMin = rect.xMin;

            // Splitter rect should be full-width
            rect.xMin = 0f;
            rect.width += 4f;

            if (isBoxed)
            {
                rect.xMin = xMin == 7.0 ? 4.0f : EditorGUIUtility.singleLineHeight;
                rect.width -= 1;
            }

            if (Event.current.type != EventType.Repaint)
                return;

            EditorGUI.DrawRect(rect, !EditorGUIUtility.isProSkin
                ? new Color(0.6f, 0.6f, 0.6f, 1.333f)
                : new Color(0.12f, 0.12f, 0.12f, 1.333f));
        }
        /// <summary> Draw a foldout header </summary>
        /// <param name="title"> The title of the header </param>
        /// <param name="state"> The state of the header </param>
        /// <returns>return the state of the foldout header</returns>
        internal static bool HeaderFoldout(GUIContent title, bool state, bool isBoxed = false, Func<bool> hasMoreOptions = null, Action toggleMoreOptions = null, string documentationURL = "", Action<Vector2> contextAction = null)
        {
            return DrawHeaderFoldout(title, state, documentationURL: documentationURL);
            return EditorGUILayout.Foldout(state, title);
            return CoreEditorUtils.DrawHeaderFoldout(title, state, documentationURL: documentationURL);
        }
        internal static bool SubHeaderFoldout(GUIContent title, bool state, bool isBoxed = false)
        {
            return CoreEditorUtils.DrawSubHeaderFoldout(title, state, isBoxed: false);
        }

        /// <summary>
        /// Creates a material header scope to display the foldout in the material UI.
        /// </summary>
        /// <param name="title">GUI Content of the header.</param>
        /// <param name="bitExpanded">Bit index which specifies the state of the header (whether it is open or collapsed) inside Editor Prefs.</param>
        /// <param name="materialEditor">The current material editor.</param>
        /// <param name="spaceAtEnd">Set this to true to make the block include space at the bottom of its UI. Set to false to not include any space.</param>
        /// <param name="subHeader">Set to true to make this into a sub-header. This affects the style of the header. Set to false to make this use the standard style.</param>
        /// <param name="defaultExpandedState">The default state if the header is not present</param>
        /// <param name="documentationURL">[optional] Documentation page</param>
        public StreamlineMaterialHeader(GUIContent title, uint bitExpanded, MaterialEditor materialEditor, bool spaceAtEnd = true, bool subHeader = false, uint defaultExpandedState = uint.MaxValue, string documentationURL = "")
        {
            if (title == null)
                throw new ArgumentNullException(nameof(title));

            bool beforeExpanded = materialEditor.IsAreaExpanded(bitExpanded, defaultExpandedState);

#if !UNITY_2020_1_OR_NEWER
            oldIndentLevel = EditorGUI.indentLevel;
            EditorGUI.indentLevel = subHeader ? 1 : 0; //fix for preset in 2019.3 (preset are one more indentation depth in material)
#endif
            Rect rect = default;
            
            this.spaceAtEnd = spaceAtEnd;
            if (!subHeader)
                DrawSplitter();
            GUILayout.BeginVertical();

            bool saveChangeState = GUI.changed;
            expanded = subHeader
                ? SubHeaderFoldout(title, beforeExpanded, isBoxed: false)
                : HeaderFoldout(title, beforeExpanded, documentationURL: documentationURL);
            if (expanded ^ beforeExpanded)
            {
                materialEditor.SetIsAreaExpanded((uint)bitExpanded, expanded);
                saveChangeState = true;
            }
            GUI.changed = saveChangeState;

            if (expanded)
                ++EditorGUI.indentLevel;
        }

        /// <summary>
        /// Creates a material header scope to display the foldout in the material UI.
        /// </summary>
        /// <param name="title">Title of the header.</param>
        /// <param name="bitExpanded">Bit index which specifies the state of the header (whether it is open or collapsed) inside Editor Prefs.</param>
        /// <param name="materialEditor">The current material editor.</param>
        /// <param name="spaceAtEnd">Set this to true to make the block include space at the bottom of its UI. Set to false to not include any space.</param>
        /// <param name="subHeader">Set to true to make this into a sub-header. This affects the style of the header. Set to false to make this use the standard style.</param>
        public StreamlineMaterialHeader(string title, uint bitExpanded, MaterialEditor materialEditor, bool spaceAtEnd = true, bool subHeader = false)
            : this(EditorGUIUtility.TrTextContent(title, string.Empty), bitExpanded, materialEditor, spaceAtEnd, subHeader)
        {
        }

        /// <summary>Disposes of the material scope header and cleans up any resources it used.</summary>
        void IDisposable.Dispose()
        {
            if (expanded)
            {
                if (spaceAtEnd && (Event.current.type == EventType.Repaint || Event.current.type == EventType.Layout))
                    EditorGUILayout.Space();
                --EditorGUI.indentLevel;
            }

#if !UNITY_2020_1_OR_NEWER
            EditorGUI.indentLevel = oldIndentLevel;
#endif
            GUILayout.EndVertical();
        }
        
        /// <summary> Draw a foldout header </summary>
        /// <param name="title"> The title of the header </param>
        /// <param name="state"> The state of the header </param>
        /// <param name="isBoxed"> [optional] is the eader contained in a box style ? </param>
        /// <param name="hasMoreOptions"> [optional] Delegate used to draw the right state of the advanced button. If null, no button drawn. </param>
        /// <param name="toggleMoreOption"> [optional] Callback call when advanced button clicked. Should be used to toggle its state. </param>
        /// <returns>return the state of the foldout header</returns>
        public static bool DrawHeaderFoldout(string title, bool state, bool isBoxed = false, Func<bool> hasMoreOptions = null, Action toggleMoreOption = null)
            => DrawHeaderFoldout(EditorGUIUtility.TrTextContent(title), state, isBoxed, hasMoreOptions, toggleMoreOption);

        /// <summary> Draw a foldout header </summary>
        /// <param name="title"> The title of the header </param>
        /// <param name="state"> The state of the header </param>
        /// <param name="isBoxed"> [optional] is the eader contained in a box style ? </param>
        /// <param name="hasMoreOptions"> [optional] Delegate used to draw the right state of the advanced button. If null, no button drawn. </param>
        /// <param name="toggleMoreOptions"> [optional] Callback call when advanced button clicked. Should be used to toggle its state. </param>
        /// <param name="documentationURL">[optional] The URL that the Unity Editor opens when the user presses the help button on the header.</param>
        /// <param name="contextAction">[optional] The callback that the Unity Editor executes when the user presses the burger menu on the header.</param>
        /// <returns>return the state of the foldout header</returns>
        public static bool DrawHeaderFoldout(GUIContent title, bool state, bool isBoxed = false, Func<bool> hasMoreOptions = null, Action toggleMoreOptions = null, string documentationURL = "", Action<Vector2> contextAction = null)
        {
            const float height = 17f;
            var backgroundRect = GUILayoutUtility.GetRect(1f, height);
            float xMin = backgroundRect.xMin;

            var labelRect = backgroundRect;
            labelRect.xMin += 16f;
            labelRect.xMax -= 20f;

            var foldoutRect = backgroundRect;
            foldoutRect.y += 1f;
            foldoutRect.width = 13f;
            foldoutRect.height = 13f;
            foldoutRect.x = labelRect.xMin + 15 * (EditorGUI.indentLevel - 1); //fix for presset

            // Background rect should be full-width
            backgroundRect.xMin = 0f;
            backgroundRect.width += 4f;

            if (isBoxed)
            {
                labelRect.xMin += 5;
                foldoutRect.xMin += 5;
                backgroundRect.xMin = xMin == 7.0 ? 4.0f : EditorGUIUtility.singleLineHeight;
                backgroundRect.width -= 1;
            }

            // Background
            float backgroundTint = EditorGUIUtility.isProSkin ? 0.1f : 1f;
            EditorGUI.DrawRect(backgroundRect, new Color(backgroundTint, backgroundTint, backgroundTint, 0.2f));

            // Title
            EditorGUI.LabelField(labelRect, title, EditorStyles.boldLabel);

            // Active checkbox
            state = GUI.Toggle(foldoutRect, state, GUIContent.none, EditorStyles.foldout);

            // Context menu
            var menuIcon = CoreEditorStyles.paneOptionsIcon;
            var menuRect = new Rect(labelRect.xMax + 3f, labelRect.y + 1f, 16, 16);

            // Add context menu for "Additional Properties"
            if (contextAction == null && hasMoreOptions != null)
            {
                contextAction = pos => OnContextClick(pos, hasMoreOptions, toggleMoreOptions);
            }

            if (contextAction != null)
            {
                if (GUI.Button(menuRect, CoreEditorStyles.contextMenuIcon, CoreEditorStyles.contextMenuStyle))
                    contextAction(new Vector2(menuRect.x, menuRect.yMax));
            }

            // Documentation button
            ShowHelpButton(menuRect, documentationURL, title);

            var e = Event.current;

            if (e.type == EventType.MouseDown)
            {
                if (backgroundRect.Contains(e.mousePosition))
                {
                    if (e.button != 0 && contextAction != null)
                        contextAction(e.mousePosition);
                    else if (e.button == 0)
                    {
                        state = !state;
                        e.Use();
                    }

                    e.Use();
                }
            }

            return state;
        }
        
        static void ShowHelpButton(Rect contextMenuRect, string documentationURL, GUIContent title)
        {
            if (string.IsNullOrEmpty(documentationURL))
                return;

            var documentationRect = contextMenuRect;
            documentationRect.x -= 16 + 2;

            var documentationIcon = new GUIContent(CoreEditorStyles.iconHelp, $"Open Reference for {title.text}.");

            if (GUI.Button(documentationRect, documentationIcon, CoreEditorStyles.iconHelpStyle))
                Help.BrowseURL(documentationURL);
        }

        static void OnContextClick(Vector2 position, Func<bool> hasMoreOptions, Action toggleMoreOptions)
        {
            var menu = new GenericMenu();

            menu.AddItem(EditorGUIUtility.TrTextContent("Show Additional Properties"), hasMoreOptions.Invoke(), () => toggleMoreOptions.Invoke());
            menu.AddItem(EditorGUIUtility.TrTextContent("Show All Additional Properties..."), false, () => CoreRenderPipelinePreferences.Open());

            menu.DropDown(new Rect(position, Vector2.zero));
        }
    }

}
