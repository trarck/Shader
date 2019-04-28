Shader "PBS/Standard"
{
    Properties
    {
		[Header(Base)]
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}
	    _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0

		[Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_MetallicGlossMap("Metallic", 2D) = "white" {}

		_BumpScale("Scale", Float) = 1.0
		_BumpMap("Normal Map", 2D) = "bump" {}

		_Parallax("Height Scale", Range(0.005, 0.08)) = 0.02
		_ParallaxMap("Height Map", 2D) = "black" {}

		_OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
		_OcclusionMap("Occlusion", 2D) = "white" {}

		_EmissionColor("Color", Color) = (0,0,0)
		_EmissionMap("Emission", 2D) = "white" {}

		// Blending state
		[HideInInspector] _Mode("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend("__src", Float) = 1.0
		[HideInInspector] _DstBlend("__dst", Float) = 0.0
		[HideInInspector] _ZWrite("__zw", Float) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 300

        Pass
        {
			 Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			Blend[_SrcBlend][_DstBlend]
			ZWrite[_ZWrite]

			CGPROGRAM
			#pragma target 3.0

			#pragma shader_feature _NORMALMAP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _EMISSION
			#pragma shader_feature _METALLICGLOSSMAP
			#pragma shader_feature _PARALLAXMAP

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "Common.cginc"
			#include "ShadingModels.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				half3  normal	 : NORMAL;
				float4 tangent	 : TANGENT;
            };

            struct v2f
            {
				float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
				float3 worldNormal:TEXCOORD1;
            };

			half4       _Color;

			sampler2D   _MainTex;
			float4      _MainTex_ST;

			sampler2D   _BumpMap;
			half        _BumpScale;

			sampler2D   _SpecGlossMap;
			sampler2D   _MetallicGlossMap;
			half        _Metallic;
			float       _Glossiness;
			float       _GlossMapScale;

			sampler2D   _OcclusionMap;
			half        _OcclusionStrength;

			sampler2D   _ParallaxMap;
			half        _Parallax;

			half4       _EmissionColor;
			sampler2D   _EmissionMap;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
