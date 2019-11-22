using System.Collections;
using System.Collections.Generic;
using UnityEngine;
namespace Outline
{
#if UNITY_2018_3_OR_NEWER
    [ExecuteAlways]
#else
    [ExecuteInEditMode]
#endif
    [RequireComponent(typeof(Renderer))]
    public class OutlineVolume : MonoBehaviour
    {
        public Color color;
        public SortingType sortingType;

        void OnEnable()
        {
            OutlineManager.Instance.AddRenderer(GetComponent<Renderer>(),color,sortingType);
        }

        void OnDisable()
        {
            OutlineManager.Instance.RemoveRenderer(GetComponent<Renderer>());
        }
    }
}
