Shader "Tests/Intergrate"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
		// make fog work
		#pragma multi_compile_fog

		#include "UnityCG.cginc"
		#include "UnityLightingCommon.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float3 normal:NORMAL;
			float2 uv : TEXCOORD0;
		};

		struct v2f
		{
			float2 uv : TEXCOORD0;
			float4 vertex : SV_POSITION;
			half3 intergrate : COLOR0;
		};

		sampler2D _MainTex;
		float4 _MainTex_ST;

		v2f vert(appdata v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.uv = TRANSFORM_TEX(v.uv, _MainTex);
			half3 intergrate = normalize(v.normal);// normalize(_WorldSpaceLightPos0.xyz)
			o.intergrate = intergrate;
			return o;
		}

		fixed4 frag(v2f i) : SV_Target
		{
			// sample the texture
			fixed4 color = fixed4(1,0,0,1);
			float3 a = float3(1, 1, 1);
			float3 b = float3(0.5, 0.2, 0.1);
			color.rgb = a / b;
			//if (color.r == 2) {

			//	color.rgb = fixed3(1, 0, 0);
			//}

			//if (color.g == 5) {

			//	color.rgb = fixed3(0, 1, 0);
			//}

			if (color.b == 10) {

				color.rgb = fixed3(0, 0, 1);
			}

			return color;
		}
		ENDCG
	}
	}
}
