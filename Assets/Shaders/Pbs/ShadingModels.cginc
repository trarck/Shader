/*=============================================================================
	ShadingModels.cginc: Shader models
=============================================================================*/
#ifndef __PBS_SHADING_MODELS___
#define __PBS_SHADING_MODELS___

#include "BRDF.cginc"
#include "FastMath.cginc"

float3 StandardShading( float3 DiffuseColor, float3 SpecularColor, float Roughness, float3 LobeEnergy, float3 L, float3 V, half3 N )
{
	float NoL = dot(N, L);
	float NoV = dot(N, V);
	float LoV = dot(L, V);
	float InvLenH = rsqrt( 2 + 2 * LoV );
	float NoH = saturate( ( NoL + NoV ) * InvLenH );
	float VoH = saturate( InvLenH + InvLenH * LoV );
	NoL = saturate(NoL);
	NoV = saturate(abs(NoV) + 1e-5);

	// Generalized microfacet specular
	float D = D_GGX(Roughness, NoH ) * LobeEnergy[1];
	float Vis = Vis_SmithJointApprox(Roughness, NoV, NoL );
	float3 F = F_Schlick( SpecularColor, VoH );

	float3 Diffuse = Diffuse_Lambert( DiffuseColor );
	//float3 Diffuse = Diffuse_Burley( DiffuseColor, Roughness, NoV, NoL, VoH );
	//float3 Diffuse = Diffuse_OrenNayar( DiffuseColor, Roughness, NoV, NoL, VoH );

	return Diffuse * LobeEnergy[2] + (D * Vis) * F;
}

float3 SimpleShading( float3 DiffuseColor, float3 SpecularColor, float Roughness, float3 L, float3 V, half3 N )
{
	float3 H = normalize(V + L);
	float NoH = saturate( dot(N, H) );
	
	// Generalized microfacet specular
	float D = D_GGX( Roughness, NoH );
	float Vis = Vis_Implicit();
	float3 F = F_None( SpecularColor );

	return Diffuse_Lambert( DiffuseColor ) + (D * Vis) * F;
}

//Í¸Ã÷Í¿²ã»ò³µÆá
float3 ClearCoatShading(float3 DiffuseColor, float3 SpecularColor, float Roughness, float3 LobeEnergy, float3 L, float3 V, half3 N, float ClearCoat,float ClearCoatRoughness,float2 ClearCoatOctahedron)
{
#if 1
	float3 H = normalize(V + L);
	float NoL = saturate(dot(N, L));
	float NoV = saturate(abs(dot(N, V)) + 1e-5);
	float NoH = saturate(dot(N, H));
	float VoH = saturate(dot(V, H));

	// Generalized microfacet specular
	float D = D_GGX(ClearCoatRoughness, NoH) * LobeEnergy[0];
	float Vis = Vis_Kelemen(VoH);

	// F_Schlick
	float F0 = 0.04;
	float Fc = Pow5(1 - VoH);
	float F = Fc + (1 - Fc) * F0;
	F *= ClearCoat;

	float Fr1 = D * Vis * F;

	float LayerAttenuation = (1 - F);


#if CLEAR_COAT_BOTTOM_NORMAL
	{
		//const float3 ClearCoatUnderNormal = OctahedronToUnitVector((ClearCoatOctahedron * 2) - (256.0/255.0));
		const float2 oct1 = ((ClearCoatOctahedron * 2) - (256.0 / 255.0)) + UnitVectorToOctahedron(WorldNormal);
		const float3 ClearCoatUnderNormal = OctahedronToUnitVector(oct1);
		//float CNoL = saturate( dot(ClearCoatUnderNormal, L) );
		//float CNoV = saturate( dot(ClearCoatUnderNormal, V) );
		float CNoH = saturate(dot(ClearCoatUnderNormal, H));

		float D2 = D_GGX(Roughness, CNoH) * LobeEnergy[1];
		float Vis2 = Vis_SmithJointApprox(Roughness, NoV, NoL);
		//float3 F2 = F_Schlick( SpecularColor, VoH );
		float3 F2 = saturate(50.0 * SpecularColor.g) * Fc + (1 - Fc) * SpecularColor;

		//Optional term taking into account Basic NdotL response of bottom normal. Not important for metallic which is the most common clearcoat case. Not energy conserving.
		//float3 Fr2 = Diffuse_Lambert( DiffuseColor ) * CNoL + (D2 * Vis2) * F2;

		float3 Fr2 = Diffuse_Lambert(DiffuseColor) + (D2 * Vis2) * F2;

		return Fr1 + Fr2 * LayerAttenuation;
		//return float3(2,0,0);
		//return ClearCoatUnderNormal;
	}
#endif

	// Generalized microfacet specular
	float D2 = D_GGX(Roughness, NoH) * LobeEnergy[1];
	float Vis2 = Vis_SmithJointApprox(Roughness, NoV, NoL);
	//float3 F2 = F_Schlick( SpecularColor, VoH );
	float3 F2 = saturate(50.0 * SpecularColor.g) * Fc + (1 - Fc) * SpecularColor;

	//float3 Fr2 = Diffuse_Burley( DiffuseColor, Roughness, NoV, NoL, VoH ) * LobeEnergy[2] + (D2 * Vis2) * F2;
	float3 Fr2 = Diffuse_Lambert(DiffuseColor) * LobeEnergy[2] + (D2 * Vis2) * F2;

	return Fr1 + Fr2 * LayerAttenuation;
#else
	float3 H = normalize(V + L);
	float NoL = saturate(dot(N, L));
	float NoV = saturate(abs(dot(N, V)) + 1e-5);
	float NoH = saturate(dot(N, H));
	float VoH = saturate(dot(V, H));

	// Hard coded IOR of 1.5

	// Generalized microfacet specular
	float D = D_GGX(ClearCoatRoughness, NoH) * LobeEnergy[0];
	float Vis = Vis_Kelemen(VoH);

	// F_Schlick
	float F0 = 0.04;
	float Fc = Pow5(1 - VoH);
	float F = Fc + (1 - Fc) * F0;

	float Fr1 = D * Vis * F;

	// Refract rays
	//float3 L2 = refract( -L, -H, 1 / 1.5 );
	//float3 V2 = refract( -V, -H, 1 / 1.5 );

	// LoH == VoH
	//float RefractBlend = sqrt( 4 * VoH*VoH + 5 ) / 3 + 2.0 / 3 * VoH;
	//float3 L2 = RefractBlend * H - L / 1.5;
	//float3 V2 = RefractBlend * H - V / 1.5;
	//float NoL2 = saturate( dot(N, L2) );
	//float NoV2 = saturate( dot(N, V2) );

	// Approximation
	float RefractBlend = (0.22 * VoH + 0.7) * VoH + 0.745;	// 2 mad
	// Dot products distribute. No need for L2 and V2.
	float RefractNoH = RefractBlend * NoH;					// 1 mul
	float NoL2 = saturate(RefractNoH - (1 / 1.5) * NoL);	// 1 mad
	float NoV2 = saturate(RefractNoH - (1 / 1.5) * NoV);	// 1 mad
	// Should refract H too but unimportant

	NoL2 = max(0.001, NoL2);
	NoV2 = max(0.001, NoV2);

	float  AbsorptionDist = rcp(NoV2) + rcp(NoL2);
	float3 Absorption = pow(AbsorptionColor, 0.5 * AbsorptionDist);

	// Approximation
	//float  AbsorptionDist = ( NoV2 + NoL2 ) / ( NoV2 * NoL2 );
	//float3 Absorption = AbsorptionColor * ( AbsorptionColor * (AbsorptionDist * 0.5 - 1) + (2 - 0.5 * AbsorptionDist) );
	//float3 Absorption = AbsorptionColor + AbsorptionColor * (AbsorptionColor - 1) * (AbsorptionDist * 0.5 - 1);	// use for shared version

	//float F21 = Fresnel( 1 / 1.5, saturate( dot(V2, H) ) );
	//float TotalInternalReflection = 1 - F21 * G_Schlick( Roughness, NoV2, NoL2 );
	//float3 LayerAttenuation = ( (1 - F12) * TotalInternalReflection ) * Absorption;

	// Approximation
	float3 LayerAttenuation = (1 - F) * Absorption;

	// Approximation for IOR == 1.5
	//SpecularColor = ChangeBaseMedium( SpecularColor, 1.5 );
	//SpecularColor = saturate( ( 0.55 * SpecularColor + (0.45 * 1.08) ) * SpecularColor - (0.45 * 0.08) );
	// Treat SpecularColor as relative to IOR. Artist compensates.

	// Generalized microfacet specular
	float D2 = D_GGX(Roughness, NoH) * LobeEnergy[2];
	float Vis2 = Vis_SmithJointApprox(Roughness, NoV2, NoL2);
	float3 F2 = F_Schlick(SpecularColor, VoH);

	float3 Fr2 = Diffuse_Lambert(DiffuseColor) * LobeEnergy[2] + (D2 * Vis2) * F2;

	return Fr1 + Fr2 * LayerAttenuation;
#endif
}


float3 ClothShading(float3 DiffuseColor, float3 SpecularColor,  float Roughness, float3 LobeEnergy, float3 L, float3 V, half3 N, float3 FuzzColor, float  Cloth)
{
	float NoL = dot(N, L);
	float NoV = dot(N, V);
	float LoV = dot(L, V);
	float InvLenH = rsqrt(2 + 2 * LoV);
	float NoH = saturate((NoL + NoV) * InvLenH);
	float VoH = saturate(InvLenH + InvLenH * LoV);
	NoL = saturate(NoL);
	NoV = saturate(abs(NoV) + 1e-5);

	// Diffuse	
	float3 Diffuse = Diffuse_Lambert(DiffuseColor);
	float3 Diff = Diffuse * LobeEnergy[2];

	// Cloth - Asperity Scattering - Inverse Beckmann Layer	
	float3 F1 = F_Schlick(FuzzColor, VoH);
	float  D1 = D_InvGGX(Roughness, NoH);
	float  V1 = Vis_Cloth(NoV, NoL);

	float3 Spec1 = D1 * V1 * F1;

	// Generalized microfacet specular
	float3 F2 = F_Schlick(SpecularColor, VoH);
	float  D2 = D_GGX(Roughness, NoH) * LobeEnergy[1];
	float  V2 = Vis_SmithJointApprox(Roughness, NoV, NoL);

	float3 Spec2 = D2 * V2 * F2;

	float3 Spec = lerp(Spec2, Spec1, Cloth);

	return Diff + Spec;
}

float Hair_g(float B, float Theta)
{
	return exp(-0.5 * Pow2(Theta) / (B*B)) / (sqrt(2 * PI) * B);
}

float Hair_F(float CosTheta)
{
	const float n = 1.55;
	const float F0 = Pow2((1 - n) / (1 + n));
	return F0 + (1 - F0) * Pow5(1 - CosTheta);
}

// Approximation to HairShadingRef using concepts from the following papers:
// [Marschner et al. 2003, "Light Scattering from Human Hair Fibers"]
// [Pekelis et al. 2015, "A Data-Driven Light Scattering Model for Hair"]
float3 HairShading(float3 BaseColor,float3 DiffuseColor, float3 SpecularColor, float Roughness,float Specular,float Metallic, float3 L, float3 V, half3 N, float Shadow, float Backlit, float Area, uint2 Random)
{
	// to prevent NaN with decals
	// OR-18489 HERO: IGGY: RMB on E ability causes blinding hair effect
	// OR-17578 HERO: HAMMER: E causes blinding light on heroes with hair
	float ClampedRoughness = clamp(Roughness, 1 / 255.0f, 1.0f);

	// N is the vector parallel to hair pointing toward root

	const float VoL = dot(V, L);
	const float SinThetaL = dot(N, L);
	const float SinThetaV = dot(N, V);
	float CosThetaD = cos(0.5 * abs(asinFast(SinThetaV) - asinFast(SinThetaL)));

	//CosThetaD = abs( CosThetaD ) < 0.01 ? 0.01 : CosThetaD;

	const float3 Lp = L - SinThetaL * N;
	const float3 Vp = V - SinThetaV * N;
	const float CosPhi = dot(Lp, Vp) * rsqrt(dot(Lp, Lp) * dot(Vp, Vp) + 1e-4);
	const float CosHalfPhi = sqrt(saturate(0.5 + 0.5 * CosPhi));
	//const float Phi = acosFast( CosPhi );

	float n = 1.55;
	//float n_prime = sqrt( n*n - 1 + Pow2( CosThetaD ) ) / CosThetaD;
	float n_prime = 1.19 / CosThetaD + 0.36 * CosThetaD;

	float Shift = 0.035;
	float Alpha[3] =
	{
		-Shift * 2,
		Shift,
		Shift * 4,
	};
	float B[3] =
	{
		Area + Pow2(ClampedRoughness),
		Area + Pow2(ClampedRoughness) / 2,
		Area + Pow2(ClampedRoughness) * 2,
	};

	float3 S = 0;

	// R
	if (1)
	{
		const float sa = sin(Alpha[0]);
		const float ca = cos(Alpha[0]);
		float Shift = 2 * sa* (ca * CosHalfPhi * sqrt(1 - SinThetaV * SinThetaV) + sa * SinThetaV);

		float Mp = Hair_g(B[0] * sqrt(2.0) * CosHalfPhi, SinThetaL + SinThetaV - Shift);
		float Np = 0.25 * CosHalfPhi;
		float Fp = Hair_F(sqrt(saturate(0.5 + 0.5 * VoL)));
		S += Mp * Np * Fp * (Specular * 2) * lerp(1, Backlit, saturate(-VoL));
	}

	// TT
	if (1)
	{
		float Mp = Hair_g(B[1], SinThetaL + SinThetaV - Alpha[1]);

		float a = 1 / n_prime;
		//float h = CosHalfPhi * rsqrt( 1 + a*a - 2*a * sqrt( 0.5 - 0.5 * CosPhi ) );
		//float h = CosHalfPhi * ( ( 1 - Pow2( CosHalfPhi ) ) * a + 1 );
		float h = CosHalfPhi * (1 + a * (0.6 - 0.8 * CosPhi));
		//float h = 0.4;
		//float yi = asinFast(h);
		//float yt = asinFast(h / n_prime);

		float f = Hair_F(CosThetaD * sqrt(saturate(1 - h * h)));
		float Fp = Pow2(1 - f);
		//float3 Tp = pow( BaseColor, 0.5 * ( 1 + cos(2*yt) ) / CosThetaD );
		//float3 Tp = pow( BaseColor, 0.5 * cos(yt) / CosThetaD );
		float3 Tp = pow(BaseColor, 0.5 * sqrt(1 - Pow2(h * a)) / CosThetaD);

		//float t = asin( 1 / n_prime );
		//float d = ( sqrt(2) - t ) / ( 1 - t );
		//float s = -0.5 * PI * (1 - 1 / n_prime) * log( 2*d - 1 - 2 * sqrt( d * (d - 1) ) );
		//float s = 0.35;
		//float Np = exp( (Phi - PI) / s ) / ( s * Pow2( 1 + exp( (Phi - PI) / s ) ) );
		//float Np = 0.71 * exp( -1.65 * Pow2(Phi - PI) );
		float Np = exp(-3.65 * CosPhi - 3.98);

		S += Mp * Np * Fp * Tp * Backlit;
	}

	// TRT
	if (1)
	{
		float Mp = Hair_g(B[2], SinThetaL + SinThetaV - Alpha[2]);

		//float h = 0.75;
		float f = Hair_F(CosThetaD * 0.5);
		float Fp = Pow2(1 - f) * f;
		//float3 Tp = pow( BaseColor, 1.6 / CosThetaD );
		float3 Tp = pow(BaseColor, 0.8 / CosThetaD);

		//float s = 0.15;
		//float Np = 0.75 * exp( Phi / s ) / ( s * Pow2( 1 + exp( Phi / s ) ) );
		float Np = exp(17 * CosPhi - 16.78);

		S += Mp * Np * Fp * Tp;
	}

	if (1)
	{
		float3 FakeNormal = normalize(V - N * dot(V, N));
		//N = normalize( DiffuseN + FakeNormal * 2 );
		N = FakeNormal;

		// Hack approximation for multiple scattering.
		float Wrap = 1;
		float NoL = saturate((dot(N, L) + Wrap) / Square(1 + Wrap));
		float DiffuseScatter = (1 / PI) * NoL * Metallic;
		float Luma = Luminance(BaseColor);
		float3 ScatterTint = pow(BaseColor / Luma, 1 - Shadow);
		S += sqrt(BaseColor) * DiffuseScatter * ScatterTint;
	}

	S = -min(-S, 0.0);

	return S;
}


float3 SubsurfaceShadingSubsurface(float3 SubsurfaceColor,float Opacity,float AO, float3 L, float3 V, half3 N)
{
	SubsurfaceColor = SubsurfaceColor * SubsurfaceColor;
	float3 H = normalize(V + L);

	// to get an effect when you see through the material
	// hard coded pow constant
	float InScatter = pow(saturate(dot(L, -V)), 12) * lerp(3, .1f, Opacity);
	// wrap around lighting, /(PI*2) to be energy consistent (hack do get some view dependnt and light dependent effect)
	// Opacity of 0 gives no normal dependent lighting, Opacity of 1 gives strong normal contribution
	float NormalContribution = saturate(dot(N, H) * Opacity + 1 - Opacity);
	float BackScatter = AO * NormalContribution / (PI * 2);

	// lerp to never exceed 1 (energy conserving)
	return SubsurfaceColor * lerp(BackScatter, 1, InScatter);
}

float3 SubsurfaceShadingTwoSided(float3 SubsurfaceColor, float3 L, float3 V, half3 N)
{
	// http://blog.stevemcauley.com/2011/12/03/energy-conserving-wrapped-diffuse/
	float Wrap = 0.5;
	float NoL = saturate((dot(-N, L) + Wrap) / Square(1 + Wrap));

	// GGX scatter distribution
	float VoL = saturate(dot(V, -L));
	float a = 0.6;
	float a2 = a * a;
	float d = (VoL * a2 - VoL) * VoL + 1;	// 2 mad
	float GGX = (a2 / PI) / (d * d);		// 2 mul, 1 rcp
	return NoL * GGX * SubsurfaceColor;
}

float3 EyeShading(float3 SpecularColor, float3 LobeRoughness, float3 LobeEnergy, float3 L, float3 V, half3 N)
{
	float NoL = dot(N, L);
	float NoV = dot(N, V);
	float LoV = dot(L, V);
	float InvLenH = rsqrt(2 + 2 * LoV);
	float NoH = saturate((NoL + NoV) * InvLenH);
	float VoH = saturate(InvLenH + InvLenH * LoV);
	NoL = saturate(NoL);
	NoV = saturate(abs(NoV) + 1e-5);

	// Generalized microfacet specular
	float D = D_GGX(LobeRoughness[1], NoH) * LobeEnergy[1];
	float Vis = Vis_SmithJointApprox(LobeRoughness[1], NoV, NoL);
	float3 F = F_Schlick(SpecularColor, VoH);

	return D * Vis * F;
}

float3 EyeSubsurfaceShading(float3 DiffuseColor,float Specular,float IrisDistance, float IrisMask,float3 IrisNormal, float3 L, float3 V, half3 N)
{
	float NoL = dot(N, L);
	float LoV = dot(L, V);
	float InvLenH = rsqrt(2 + 2 * LoV);
	float VoH = saturate(InvLenH + InvLenH * LoV);

	// F_Schlick
	float F0 = Specular * 0.08;
	float Fc = Pow5(1 - VoH);
	float F = Fc + (1 - Fc) * F0;

	//float  IrisDistance = GBuffer.CustomData.w;
	//float  IrisMask = GBuffer.CustomData.z;

	//float3 IrisNormal;
	//IrisNormal = OctahedronToUnitVector(GBuffer.CustomData.xy * 2 - 1);

	// Blend in the negative intersection normal to create some concavity
	// Not great as it ties the concavity to the convexity of the cornea surface
	// No good justification for that. On the other hand, if we're just looking to
	// introduce some concavity, this does the job.
	float3 CausticNormal = normalize(lerp(IrisNormal, -N, IrisMask*IrisDistance));

	float IrisNoL = saturate(dot(IrisNormal, L));
	float Power = lerp(12, 1, IrisNoL);
	float Caustic = 0.6 + 0.2 * (Power + 1) * pow(saturate(dot(CausticNormal, L)), Power);
	float Iris = IrisNoL * Caustic;

	// http://blog.stevemcauley.com/2011/12/03/energy-conserving-wrapped-diffuse/
	float Wrap = 0.15;
	float Sclera = saturate((NoL + Wrap) / Square(1 + Wrap));

	return (1 - F) * lerp(Sclera, Iris, IrisMask) * DiffuseColor / PI;
}

sampler2D	_PreIntegratedBRDF;

float3 SubsurfaceShadingPreintegratedSkin(float3 SubsurfaceColor, float Opacity, float3 L, float3 V, half3 N)
{

	float3 PreintegratedBRDF = tex2D(_PreIntegratedBRDF, float2(saturate(dot(N, L) * .5 + .5), 1 - Opacity)).rgb;
	return PreintegratedBRDF * SubsurfaceColor;
}

#endif //__PBS_SHADING_MODELS___

