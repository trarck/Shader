using System.Collections;
using System.Collections.Generic;
using UnityEngine;
namespace Outline
{
    public enum OutlineType
    {
        Glow = 0,
        Solid = 1
    }

    public enum SortingType
    {
        Overlay = 3,
        DepthFiltered = 4,
    }

    public enum DepthInvertPass
    {
        StencilMapper = 5,
        StencilDrawer = 6
    }

    public enum FillType
    {
        Fill,
        Outline
    }
    public enum RTResolution
    {
        Quarter = 4,
        Half = 2,
        Full = 1
    }

    public enum BlurType
    {
        StandardGauss = 0,
        SgxGauss = 1,
    }

    public struct OutlineData
    {
        public Color color;
        public SortingType sortingType;
        public Renderer renderer;
    }

}