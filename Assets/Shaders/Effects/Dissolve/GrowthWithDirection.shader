Shader "Effect/GrowthWithDirection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_NoiseTex("NoiseTex (R)",2D) = "white"{}
		_DissolveThreshold("Dissolve Threshold",float) = 1
		_DissolveDirection("Dissolve Direction",Vector) = (1, 1, 0)
		_DissolveColor("Dissolve Color",Color)=(1,0,0,1)
		_DissolveEdgeColor("Dissolve Edge Color",Color) = (1,1,0,1)
		_DissolveColorFactor("Dissolve Color Factor",Range(0,1)) = 0.02
		_DissolveEdgeColorFactor("Dissolve Edge Color Factor",Range(0,1)) = 0.04
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
			cull Back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			sampler2D _NoiseTex;

			half _DissolveThreshold;
			half3 _DissolveDirection;
			fixed4 _DissolveColor;
			fixed4 _DissolveEdgeColor;
			fixed _DissolveColorFactor;
			fixed _DissolveEdgeColorFactor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
				o.worldPos = mul((float3x3)unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
			{

				float dissolveValue = dot(i.worldPos, normalize(_DissolveDirection));
				dissolveValue += tex2D(_NoiseTex, i.uv).r;
				float clipValue = _DissolveThreshold - dissolveValue  ;
				clip(clipValue);

				fixed4 col = tex2D(_MainTex, i.uv);
				half3 dissolveColor = lerp(_DissolveEdgeColor.rgb, _DissolveColor.rgb, smoothstep(0, _DissolveEdgeColorFactor, clipValue));
				col.rgb = lerp(dissolveColor, col.rgb, smoothstep(_DissolveColorFactor, _DissolveColorFactor, clipValue));

                return col;
            }
            ENDCG
        }
    }
}
