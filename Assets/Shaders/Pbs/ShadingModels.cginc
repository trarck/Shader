/*=============================================================================
	ShadingModels.cginc: Shader models
=============================================================================*/
#ifndef __PBS_SHADING_MODELS___
#define __PBS_SHADING_MODELS___

#include "BRDF.cginc"

float3 StandardShading( float3 DiffuseColor, float3 SpecularColor, float3 LobeRoughness, float3 LobeEnergy, float3 L, float3 V, half3 N )
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
	float D = D_GGX( LobeRoughness[1], NoH ) * LobeEnergy[1];
	float Vis = Vis_SmithJointApprox( LobeRoughness[1], NoV, NoL );
	float3 F = F_Schlick( SpecularColor, VoH );

	float3 Diffuse = Diffuse_Lambert( DiffuseColor );
	//float3 Diffuse = Diffuse_Burley( DiffuseColor, LobeRoughness[1], NoV, NoL, VoH );
	//float3 Diffuse = Diffuse_OrenNayar( DiffuseColor, LobeRoughness[1], NoV, NoL, VoH );

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
float3 ClearCoatShading(float3 DiffuseColor, float3 SpecularColor, float3 LobeRoughness, float3 LobeEnergy, float3 L, float3 V, half3 N, float ClearCoat,float ClearCoatRoughness,float2 ClearCoatOctahedron)
{
#if 1
	float3 H = normalize(V + L);
	float NoL = saturate(dot(N, L));
	float NoV = saturate(abs(dot(N, V)) + 1e-5);
	float NoH = saturate(dot(N, H));
	float VoH = saturate(dot(V, H));

	// Generalized microfacet specular
	float D = D_GGX(LobeRoughness[0], NoH) * LobeEnergy[0];
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

		float D2 = D_GGX(LobeRoughness[1], CNoH) * LobeEnergy[1];
		float Vis2 = Vis_SmithJointApprox(LobeRoughness[1], NoV, NoL);
		//float3 F2 = F_Schlick( SpecularColor, VoH );
		float3 F2 = saturate(50.0 * SpecularColor.g) * Fc + (1 - Fc) * SpecularColor;

		//Optional term taking into account Basic NdotL response of bottom normal. Not important for metallic which is the most common clearcoat case. Not energy conserving.
		//float3 Fr2 = Diffuse_Lambert( GBuffer.DiffuseColor ) * CNoL + (D2 * Vis2) * F2;

		float3 Fr2 = Diffuse_Lambert(GBuffer.DiffuseColor) + (D2 * Vis2) * F2;

		return Fr1 + Fr2 * LayerAttenuation;
		//return float3(2,0,0);
		//return ClearCoatUnderNormal;
	}
#endif

	// Generalized microfacet specular
	float D2 = D_GGX(LobeRoughness[1], NoH) * LobeEnergy[1];
	float Vis2 = Vis_SmithJointApprox(LobeRoughness[1], NoV, NoL);
	//float3 F2 = F_Schlick( GBuffer.SpecularColor, VoH );
	float3 F2 = saturate(50.0 * GBuffer.SpecularColor.g) * Fc + (1 - Fc) * GBuffer.SpecularColor;

	//float3 Fr2 = Diffuse_Burley( GBuffer.DiffuseColor, LobeRoughness[1], NoV, NoL, VoH ) * LobeEnergy[2] + (D2 * Vis2) * F2;
	float3 Fr2 = Diffuse_Lambert(GBuffer.DiffuseColor) * LobeEnergy[2] + (D2 * Vis2) * F2;

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
	float3 F2 = F_Schlick(GBuffer.SpecularColor, VoH);

	float3 Fr2 = Diffuse_Lambert(GBuffer.DiffuseColor) * LobeEnergy[2] + (D2 * Vis2) * F2;

	return Fr1 + Fr2 * LayerAttenuation;
#endif
}


#endif //__PBS_SHADING_MODELS___

