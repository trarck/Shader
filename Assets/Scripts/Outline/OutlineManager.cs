using System.Collections;
using System.Collections.Generic;
using UnityEngine;
namespace Outline
{
    public class OutlineManager
    {
        static OutlineManager s_Instance;

        public static OutlineManager Instance
        {
            get
            {
                if (s_Instance == null)
                    s_Instance = new OutlineManager();

                return s_Instance;
            }
        }

        private List<OutlineData> m_ObjectRenderers;
        private List<Renderer> m_ObjectExcluders;

        public List<OutlineData> objectRenderers
        {
            get { return m_ObjectRenderers; }
        }

        public List<Renderer> objectExcluders
        {
            get { return m_ObjectExcluders; }
        }

        public OutlineLayer outlineLayer;

        public OutlineManager()
        {
            m_ObjectRenderers = new List<OutlineData>();
            m_ObjectExcluders = new List<Renderer>();
        }

        public void AddRenderer(Renderer renderer, Color col, SortingType sorting)
        {
            var data = new OutlineData() { color = col, sortingType = sorting ,renderer=renderer};
            m_ObjectRenderers.Add(data);
            if (outlineLayer)
            {
                outlineLayer.dirty = true;
            }
        }


        public void RemoveRenderer(Renderer renderer)
        {
            
            for(int i = 0, l = m_ObjectRenderers.Count; i < l; ++i)
            {
                if (m_ObjectRenderers[i].renderer == renderer)
                {
                    m_ObjectRenderers.RemoveAt(i);
                    break;
                }
            }
            if (outlineLayer)
            {
                outlineLayer.dirty = true;
            }
        }

        public void AddExcluder(Renderer renderer)
        {
            m_ObjectExcluders.Add(renderer);
            if (outlineLayer)
            {
                outlineLayer.dirty = true;
            }
        }

        public void RemoveExcluder(Renderer renderer)
        {
            m_ObjectExcluders.Remove(renderer);
            if (outlineLayer)
            {
                outlineLayer.dirty = true;
            }
        }

        public void ClearOutlineData()
        {
            m_ObjectRenderers.Clear();
            m_ObjectExcluders.Clear();
            if (outlineLayer)
            {
                outlineLayer.dirty = true;
            }
        }
    }
}