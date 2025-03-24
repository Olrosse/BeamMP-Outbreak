#include "outbreakVignette.h.hlsl"

#ifdef SHADER_STAGE_VS
    #define mainV main
#else 
    #define mainP main 
#endif

#define NOISE_FACTOR 0.03
#define NOISE_MAX 0.005

float random(float2 uv) {
    return frac(sin(dot(uv, float2(12.9898,78.233))) * 43758.5453);
}

float4 mainP( PFXVertToPix IN ) : SV_Target
{
    // vignette factor
    float vig = smoothstep(innerRadius, outerRadius, distance(IN.uv0.xy, center)*1.4142) * color.a;

    // return backbuffer mixed with vignette color and some noise
    return lerp(tex2D(backBuffer, IN.uv0.xy), color, vig + clamp(vig/NOISE_MAX, -1, 1)*random(IN.uv0.xy)*NOISE_FACTOR);
}

PFXVertToPix mainV( PFXVert IN )
{
    return processPostFxVert(IN);
}
