Shader "Custom/Decal"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_DecalTex("Texture", 2D) = "white" {}
		_DecalRect("Dissolve Direction",Vector) = (0, 0, 0,1)
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
				float3 worldNormal:TEXCOORD1;
				float2 decalUV : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _DecalTex;
			float4 _DecalTex_ST;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.decalUV = TRANSFORM_TEX(v.uv, _DecalTex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				half4 decalColor = tex2D(_DecalTex, i.decalUV);
				col.rgb = lerp(col.rgb, decal.rgb, decal.a);



				fixed3 worldNormal = normalize(i.worldNormal);
				//把光照方向归一化,如果要求不高，这里可以不归一化
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				//fixed3 worldLightDir = _WorldSpaceLightPos0.xyz;
				half nl = 0.5* dot(i.worldNormal, worldLightDir) + 0.5;
				col.rgb *= nl * _LightColor0;
				return col;
			}
			ENDCG
		}
	}
}
