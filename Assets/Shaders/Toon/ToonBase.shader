Shader "Toon/Base"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_ToonEffect("Toon Effect",range(0,1)) = 0.5//卡通化程度（二次元与三次元的交界线）
		_Steps("Steps of toon",range(0,9)) = 3//色阶层数
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
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			half _ToonEffect;
			half _Steps;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				fixed3 worldNormal = normalize(i.worldNormal);
				//把光照方向归一化,如果要求不高，这里可以不归一化
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				//fixed3 worldLightDir = _WorldSpaceLightPos0.xyz;
				//计算diffuse
				half diff = 0.5* dot(i.worldNormal, worldLightDir) + 0.5; //max(0, dot(i.worldNormal, worldLightDir));//  0.5* dot(i.worldNormal, worldLightDir) + 0.5;
				//diff=(diff+1)*0.5;
				half toon = floor(diff*_Steps) / _Steps;
				diff = lerp(diff, toon, _ToonEffect);

				col.rgb *= diff * _LightColor0;
				return col;
			}
			ENDCG
		}
	}
}
