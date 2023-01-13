#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED
#endif

#ifndef SHADERGRAPH_PREVIEW

struct EdgeSetup
{
    float diffuseEdge;
    float specularEdge;
    float rimEdge;
    float distanceAttenuationEdge;
    float shadowAttenuationEdge;

};

struct VariablesContainer
{
    float3 normal;
    float3 viewDirection;

    float smoothness;
    float shininess;

    float rimStrength;
    float rimAmount;
    float rimLimit;

    EdgeSetup es;
};

float3 CalculateLight(Light light, VariablesContainer vc)
{
    //Lambert diffuse reflection
    float diffuse = saturate(dot(vc.normal, light.direction));

    //shadow and distance attenuation
    float attenuation = smoothstep(0, vc.es.shadowAttenuationEdge, light.shadowAttenuation) *smoothstep(0, vc.es.distanceAttenuationEdge, light.distanceAttenuation);
    diffuse *= attenuation;                //this is apllied together with diffuse, to consider all shadows on the object
    //Later on, the smoothness factor will be applied. Not now, because this ill but used as a mask for other terms.

    //Blinn-Phong specular reflection
    float3 hwv = SafeNormalize(light.direction + vc.viewDirection);  //half way vector
    float specular = saturate(dot(vc.normal, hwv));
    specular = pow(specular, vc.shininess);
    specular *= diffuse; //Uses the diffuse term as a mask of the specular, to avoid specular reflection on a unlit area

    //Rim lighting
    float rim = 1 - dot(vc.viewDirection, vc.normal);
    rim *= pow(diffuse, vc.rimLimit);

    //Adjust diffuse with smoothness
    diffuse = smoothstep(0, vc.es.diffuseEdge, diffuse);
    specular = vc.smoothness * smoothstep(0.005f, 0.0055f + vc.es.specularEdge * vc.smoothness, specular);
    rim = vc.rimStrength * smoothstep(vc.rimAmount - 0.5f * vc.es.rimEdge, vc.rimAmount + 0.5f * vc.es.rimEdge, rim);


    return light.color * (diffuse + max(specular, rim));
}

#endif



void CustomLightMangaShaded_float(float3 WorldPos, float3 Normal, float3 ViewDirection, float Smoothness, float RimLimit, float RimStrenght, float RimAmount, float DiffuseEdge, float SpecularEdge, float RimEdge, float DistanceAttenuationEdge, float ShadowAttenuationEdge, out float3 Color)
{
    #if SHADERGRAPH_PREVIEW
       Color = 1;
    #else
    
        VariablesContainer vc;
        vc.normal = normalize(Normal);
        vc.viewDirection = SafeNormalize(ViewDirection);
        vc.smoothness = Smoothness;
        vc.rimLimit = RimLimit;
        vc.shininess = exp2(10 * Smoothness + 1);
        vc.rimStrength = RimStrenght;
        vc.rimAmount = RimAmount;
        vc.es.diffuseEdge = DiffuseEdge;
        vc.es.specularEdge = SpecularEdge;
        vc.es.distanceAttenuationEdge = DistanceAttenuationEdge;
        vc.es.shadowAttenuationEdge = ShadowAttenuationEdge;
        vc.es.rimEdge = RimEdge;



        #if SHADOWS_SCREEN
           float4 clipPos = TransformWorldToHClip(WorldPos);
           float4 shadowCoord = ComputeScreenPos(clipPos);
        #else
            float4 shadowCoord = TransformWorldToShadowCoord(WorldPos);
        #endif

        
        Light mainLight = GetMainLight(shadowCoord);
        Color = CalculateLight(mainLight, vc);



    #endif
}