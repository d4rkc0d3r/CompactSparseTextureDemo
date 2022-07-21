Shader "d4rkpl4y3r/CompactSparseTexture/Generate Random Texels"
{
	Properties
	{
		_DataTex("Sparse Texture", 2D) = "black" {}

		_TexelProbability("Texel Probability", Range(0, 1)) = 0.25
		_RandomSeed("Random Seed", Range(0, 1)) = 0
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
			float _TexelProbability;
			float _RandomSeed;

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

			uint pcg_hash(uint seed)
			{
				uint state = seed * 747796405u + 2891336453u;
				uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
				return (word >> 22u) ^ word;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				uint seed = pcg_hash(asuint(_RandomSeed) ^ pcg_hash((uint)i.pos.x ^ pcg_hash((uint)i.pos.y)));
				if (seed * exp2(-32) > _TexelProbability)
					return 0;
				uint4 random;
				random.x = pcg_hash(seed);
				random.y = pcg_hash(random.x ^ seed);
				random.z = pcg_hash(random.y ^ seed);
				random.w = pcg_hash(random.z ^ seed);
				float4 color = random * exp2(-32);
				color.rgb = pow(color.rgb, 2.2);
				return color;
			}
			ENDCG
		}
	}
}
