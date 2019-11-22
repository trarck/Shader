using UnityEngine;
using System.Collections.Generic;
#if UNITY_EDITOR
using UnityEditor;
#endif

public class SkinnedBoneInfo : MonoBehaviour
{
    public string rootBone;
    public string[] bones;
}

#if UNITY_EDITOR

[CustomEditor(typeof(SkinnedBoneInfo))]
public class SkinnedBoneInfoEditor : Editor
{
    private SerializedObject m_object;
    SkinnedBoneInfo m_SkinnedBoneInfo;

    public void OnEnable()
    {
        m_SkinnedBoneInfo = (SkinnedBoneInfo)target;
        m_object = new SerializedObject(target);
    }

    public override void OnInspectorGUI()
    {
        m_object.Update();

        var rootBone = m_object.FindProperty("rootBone");
        EditorGUILayout.PropertyField(rootBone, true);

        var bones = m_object.FindProperty("bones");
        EditorGUILayout.PropertyField(bones, true);

        //var Tests = m_object.FindProperty("Tests");
        //EditorGUILayout.PropertyField(Tests, true);

        if (GUILayout.Button("Refresh"))
        {
            Refresh();
        }

        m_object.ApplyModifiedProperties();
    }

    public void Refresh()
    {
        List<string> bones = new List<string>();

        SkinnedMeshRenderer smr = m_SkinnedBoneInfo.GetComponent<SkinnedMeshRenderer>();
        if (smr)
        {
            for (int i = 0; i < smr.bones.Length; ++i)
            {
                Transform t = smr.bones[i];
                bones.Add(t.name);
            }
            m_SkinnedBoneInfo.bones = bones.ToArray();
            m_SkinnedBoneInfo.rootBone = smr.rootBone.name;
            bones.Clear();
        }
        else
        {
            m_SkinnedBoneInfo.bones= bones.ToArray();
            m_SkinnedBoneInfo.rootBone = string.Empty;
        }
    }
}

#endif