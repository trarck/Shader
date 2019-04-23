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


#endif //__PBS_SHADING_MODELS___

