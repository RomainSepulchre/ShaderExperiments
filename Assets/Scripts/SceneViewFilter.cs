using System;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

public class SceneViewFilter : MonoBehaviour
{
    bool hasChanged = false;

    public void OnValidate()
    {
        hasChanged = true;
    }

    static SceneViewFilter()
    {
        SceneView.duringSceneGui += CheckMe; // onSceneGUI obsolete and replaced by duringSceneGui
    }

    static void CheckMe(SceneView sceneView)
    {
        if (Event.current.type != EventType.Layout) return;

        if (!Camera.main) return; // No main camera
        
        // Get list of what must be synced on the main camera
        SceneViewFilter[] cameraFilters = Camera.main.GetComponents<SceneViewFilter>();
        SceneViewFilter[] sceneFilters = sceneView.camera.GetComponents<SceneViewFilter>();
        
        // Compare list and if necessary recreate them from main camera
        if (cameraFilters.Length != sceneFilters.Length)
        {
            Recreate(sceneView);
            return;
        }

        for (int i = 0; i < cameraFilters.Length; i++)
        {
            if (cameraFilters[i].GetType() != sceneFilters[i].GetType())
            {
                Recreate(sceneView);
            }
        }
        
        // Copy settings when a filter has changed
        for (int i = 0; i < cameraFilters.Length; i++)
        {
            if (cameraFilters[i].hasChanged || sceneFilters[i].enabled != cameraFilters[i].enabled)
            {
                EditorUtility.CopySerialized(cameraFilters[i], sceneFilters[i]);
                cameraFilters[i].hasChanged = false;
            }
        }
    }

    static void Recreate(SceneView sceneView)
    {
        SceneViewFilter filter;
        
        while(filter = sceneView.camera.GetComponent<SceneViewFilter>()) DestroyImmediate(filter);

        foreach (SceneViewFilter svf in Camera.main.GetComponents<SceneViewFilter>())
        {
            SceneViewFilter newFilter = sceneView.camera.gameObject.AddComponent(svf.GetType()) as SceneViewFilter;
            EditorUtility.CopySerialized(svf, newFilter);
        }
    }
}
