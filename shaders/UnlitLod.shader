Shader "d4rkpl4y3r/CompactSparseTexture/UnlitLod"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [IntRange] _MipLevel ("Mip Level", Range(0, 14)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Cull Off

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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _MipLevel;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                return tex2Dlod(_MainTex, float4(i.uv, 0, _MipLevel));
            }
            ENDCG
        }
    }
}
