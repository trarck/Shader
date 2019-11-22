using UnityEngine;
using System.Collections.Generic;
using UnityEngine.Rendering;

namespace Outline
{
#if UNITY_2018_3_OR_NEWER
    [ExecuteAlways]
#else
    [ExecuteInEditMode]
#endif
    [RequireComponent(typeof(Camera))]
    public class OutlineLayer : MonoBehaviour
    {
        #region serialize vars

        [Header("Outline Settings")]

        [SerializeField]
        OutlineType m_SelectionType = OutlineType.Glow;
        [SerializeField]
        FillType m_FillType = FillType.Outline;
        [SerializeField]
        RTResolution m_Resolution = RTResolution.Full;
        [Range(0f, 1f)]
        [SerializeField]
        float m_ControlValue = 0.5f;

        public CameraEvent BufferDrawEvent = CameraEvent.BeforeImageEffects;

        [Header("BlurOptimized Settings")]

        public BlurType blurType = BlurType.StandardGauss;
        [Range(0, 2)]
        public int downSample = 0;
        [Range(0.0f, 10.0f)]
        public float blurSize = 3.0f;
        [Range(1, 4)]
        public int blurIterations = 2;

        [SerializeField]
        Material m_OutlineMaterial;
        [SerializeField]
        Material m_BlurMaterial;

        #endregion

        #region private field

        private CommandBuffer m_CommandBuffer;

        private int m_OutlineRTID, m_BlurredRTID, m_TemporaryRTID;

        private Camera m_Camera;

        private int m_RTWidth = 512;
        private int m_RTHeight = 512;

        #endregion

        public bool dirty { get; set; }

        private void Awake()
        {
            m_CommandBuffer = new CommandBuffer();
            m_CommandBuffer.name = "Outline Command Buffer";

            m_OutlineRTID = Shader.PropertyToID("_OutlineRT");
            m_BlurredRTID = Shader.PropertyToID("_BlurredRT");
            m_TemporaryRTID = Shader.PropertyToID("_TemporaryRT");

            m_RTWidth = (int)(Screen.width / (float)m_Resolution);
            m_RTHeight = (int)(Screen.height / (float)m_Resolution);

            if (!m_OutlineMaterial)
            {
                m_OutlineMaterial = new Material(Shader.Find("Custom/Outline"));
            }

            if (!m_BlurMaterial)
            {
                m_BlurMaterial = new Material(Shader.Find("Hidden/FastBlur"));
            }

            m_Camera = GetComponent<Camera>();
            m_Camera.depthTextureMode = DepthTextureMode.Depth;
            m_Camera.AddCommandBuffer(BufferDrawEvent, m_CommandBuffer);
        }

        private void Update()
        {
            if (dirty)
            {
                dirty = false;
                RecreateCommandBuffer(OutlineManager.Instance.objectRenderers, OutlineManager.Instance.objectExcluders);
            }
        }

        public void RecreateCommandBuffer(List<OutlineData> objectRenderers, List<Renderer> objectExcluders)
        {
            m_CommandBuffer.Clear();

            if (objectRenderers.Count == 0)
                return;

            // initialization

            m_CommandBuffer.GetTemporaryRT(m_OutlineRTID, m_RTWidth, m_RTHeight, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
            m_CommandBuffer.SetRenderTarget(m_OutlineRTID, BuiltinRenderTextureType.CurrentActive);
            m_CommandBuffer.ClearRenderTarget(false, true, Color.clear);

            // rendering into texture
            //group by colors
            List<Color> colors = new List<Color>();
            int colorIndex = 0;
            Dictionary<int, List<OutlineData>> grouped = new Dictionary<int, List<OutlineData>>();
            foreach(var outline in objectRenderers)
            {
                colorIndex = colors.IndexOf(outline.color);
                if (colorIndex==-1)
                {
                    colorIndex = 0;
                    colors.Add(outline.color);
                }
                if (!grouped.ContainsKey(colorIndex))
                {
                    grouped[colorIndex] = new List<OutlineData>();
                }
                grouped[colorIndex].Add(outline);
            }

            foreach (var iter in grouped)
            {
                m_CommandBuffer.SetGlobalColor("_Color", colors[iter.Key]);
                foreach (var outline in iter.Value)
                {
                    m_CommandBuffer.DrawRenderer(outline.renderer, m_OutlineMaterial, 0, (int)outline.sortingType);
                }
            }

            // excluding from texture 

            m_CommandBuffer.SetGlobalColor("_Color", Color.clear);
            foreach (var render in objectExcluders)
            {
                m_CommandBuffer.DrawRenderer(render, m_OutlineMaterial, 0, (int)SortingType.Overlay);
            }

            // Bluring texture

            float widthMod = 1.0f / (1.0f * (1 << downSample));

            int rtW = m_RTWidth >> downSample;
            int rtH = m_RTHeight >> downSample;

            m_CommandBuffer.GetTemporaryRT(m_BlurredRTID, rtW, rtH, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
            m_CommandBuffer.GetTemporaryRT(m_TemporaryRTID, rtW, rtH, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);

            m_CommandBuffer.Blit(m_OutlineRTID, m_TemporaryRTID, m_BlurMaterial, 0);

            var passOffs = blurType == BlurType.StandardGauss ? 0 : 2;

            for (int i = 0; i < blurIterations; i++)
            {
                float iterationOffs = (i * 1.0f);
                var blurHorizParam = blurSize * widthMod + iterationOffs;
                var blurVertParam = -blurSize * widthMod - iterationOffs;

                m_CommandBuffer.SetGlobalVector("_Parameter", new Vector4(blurHorizParam, blurVertParam));

                m_CommandBuffer.Blit(m_TemporaryRTID, m_BlurredRTID, m_BlurMaterial, 1 + passOffs);
                m_CommandBuffer.Blit(m_BlurredRTID, m_TemporaryRTID, m_BlurMaterial, 2 + passOffs);
            }

            // occlusion

            if (m_FillType == FillType.Outline)
            {
                // Excluding the original image from the blurred image, leaving out the areal alone
                m_CommandBuffer.SetGlobalTexture("_SecondaryTex", m_OutlineRTID);
                m_CommandBuffer.Blit(m_TemporaryRTID, m_BlurredRTID, m_OutlineMaterial, 2);

                m_CommandBuffer.SetGlobalTexture("_SecondaryTex", m_BlurredRTID);
            }
            else
            {
                m_CommandBuffer.SetGlobalTexture("_SecondaryTex", m_TemporaryRTID);
            }

            // back buffer
            m_CommandBuffer.Blit(BuiltinRenderTextureType.CameraTarget, m_OutlineRTID);

            // overlay
            m_CommandBuffer.SetGlobalFloat("_ControlValue", m_ControlValue);
            m_CommandBuffer.Blit(m_OutlineRTID, BuiltinRenderTextureType.CameraTarget, m_OutlineMaterial, (int)m_SelectionType);

            m_CommandBuffer.ReleaseTemporaryRT(m_TemporaryRTID);
            m_CommandBuffer.ReleaseTemporaryRT(m_BlurredRTID);
            m_CommandBuffer.ReleaseTemporaryRT(m_OutlineRTID);
        }
    }
}