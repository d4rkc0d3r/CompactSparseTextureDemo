Shader "d4rkpl4y3r/CompactSparseTexture/Write Active Texels"
{
	Properties
	{
		_DataTex("Sparse Texture", 2D) = "black" {}
	}
	SubShader
	{
		Tags
		{
			"RenderType" = "Transparent"
			"Queue" = "Transparent+2000"
			"DisableBatching"="True"
		}

		Pass
		{
			ZTest Off

			CGPROGRAM
			#pragma vertex empty
			#pragma geometry geom
			#pragma fragment frag
			#pragma target 5.0

			Texture2D _DataTex;
			float4 _DataTex_TexelSize;

			struct v2f
			{
				float4 pos : SV_POSITION;
			};
			
			void empty() {}

			[maxvertexcount(3)]
			void geom(triangle v2f i[3], inout TriangleStream<v2f> tristream, uint triID : SV_PrimitiveID)
			{
				if(any(_ScreenParams.xy != abs(_DataTex_TexelSize.zw)) || triID > 0)
					return;
				v2f o;
				o.pos = float4(1, 1, 1, 1);
				tristream.Append(o);
				o.pos = float4(-3, 1, 1, 1);
				tristream.Append(o);
				o.pos = float4(1, -3, 1, 1);
				tristream.Append(o);
			}
			
			float frag (v2f i) : SV_Target
			{
				return any(_DataTex[i.pos.xy]) ? 1.0 : 0.0;
			}
			ENDCG
		}
	}
}
