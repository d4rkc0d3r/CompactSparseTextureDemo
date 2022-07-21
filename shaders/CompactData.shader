Shader "d4rkpl4y3r/CompactSparseTexture/Compact Texels"
{
	Properties
	{
		_DataTex("Sparse Texture", 2D) = "black" {}
		_ActiveTexelMap("Active Texel Map", 2D) = "black" {}
		[Toggle(Z_ORDER_CURVE)] _ZOrderCurve("Z Order Curve", Int) = 0
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
			#pragma shader_feature_local Z_ORDER_CURVE

			Texture2D _DataTex;
			Texture2D<float> _ActiveTexelMap;
			float4 _ActiveTexelMap_TexelSize;
			bool _ZOrderCurve;

			#define WIDTH ((uint)_ActiveTexelMap_TexelSize.z)
			#define HEIGHT ((uint)_ActiveTexelMap_TexelSize.w)

			struct v2f
			{
				float4 pos : SV_POSITION;
			};
			
			void empty() {}

			[maxvertexcount(3)]
			void geom(triangle v2f i[3], inout TriangleStream<v2f> tristream, uint triID : SV_PrimitiveID)
			{
				if(any(_ScreenParams.xy != abs(_ActiveTexelMap_TexelSize.zw)) || triID > 0)
					return;
				v2f o;
				o.pos = float4(1, 1, 1, 1);
				tristream.Append(o);
				o.pos = float4(-3, 1, 1, 1);
				tristream.Append(o);
				o.pos = float4(1, -3, 1, 1);
				tristream.Append(o);
			}
			
			// adapted from: https://lemire.me/blog/2018/01/08/how-fast-can-you-bit-interleave-32-bit-integers/
			uint InterleaveWithZero(uint word)
			{
				word = (word ^ (word << 8)) & 0x00ff00ff;
				word = (word ^ (word << 4)) & 0x0f0f0f0f;
				word = (word ^ (word << 2)) & 0x33333333;
				word = (word ^ (word << 1)) & 0x55555555;
				return word;
			}

			// adapted from: https://stackoverflow.com/questions/3137266/how-to-de-interleave-bits-unmortonizing
			uint DeinterleaveWithZero(uint word)
			{
				word &= 0x55555555;
				word = (word | (word >> 1)) & 0x33333333;
				word = (word | (word >> 2)) & 0x0f0f0f0f;
				word = (word | (word >> 4)) & 0x00ff00ff;
				word = (word | (word >> 8)) & 0x0000ffff;
				return word;
			}

			uint2 IndexToUV(uint index)
			{
				#ifdef Z_ORDER_CURVE
				return uint2(DeinterleaveWithZero(index), DeinterleaveWithZero(index >> 1));
				#else
				return uint2(index % HEIGHT, index / HEIGHT);
				#endif
			}

			uint UVToIndex(uint2 uv)
			{
				#ifdef Z_ORDER_CURVE
				return InterleaveWithZero(uv.x) | (InterleaveWithZero(uv.y) << 1);
				#else
				return uv.x + uv.y * WIDTH;
				#endif
			}

			float CountActiveTexels(int3 uv, int2 offset)
			{
				return (float)(1 << (uv.z + uv.z)) * _ActiveTexelMap.Load(uv, offset);
			}

			float CountActiveTexels(int3 uv)
			{
				return CountActiveTexels(uv, int2(0, 0));
			}

			int2 ActiveTexelIndexToUV(float index)
			{
				float maxLod = round(log2(HEIGHT));
				int3 uv = int3(0, 0, maxLod);
				if (index >= CountActiveTexels(uv))
					return -1;
				float activeTexelSumInPreviousLods = 0;
				while (uv.z >= 1)
				{
					uv += int3(uv.xy, -1);
					float count00 = CountActiveTexels(uv);
					float count01 = CountActiveTexels(uv, int2(1, 0));
					float count10 = CountActiveTexels(uv, int2(0, 1));
					bool in00 = index < (activeTexelSumInPreviousLods + count00);
					bool in01 = index < (activeTexelSumInPreviousLods + count00 + count01);
					bool in10 = index < (activeTexelSumInPreviousLods + count00 + count01 + count10);
					if (in00)
					{
						uv.xy += int2(0, 0);
					}
					else if (in01)
					{
						uv.xy += int2(1, 0);
						activeTexelSumInPreviousLods += count00;
					}
					else if (in10)
					{
						uv.xy += int2(0, 1);
						activeTexelSumInPreviousLods += count00 + count01;
					}
					else
					{
						uv.xy += int2(1, 1);
						activeTexelSumInPreviousLods += count00 + count01 + count10;
					}
				}
				return uv.xy;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				int2 uv = ActiveTexelIndexToUV(UVToIndex(i.pos.xy));
				if (uv.x == -1)
				{
					return 0;
				}
				return _DataTex[uv];
			}
			ENDCG
		}
	}
}
