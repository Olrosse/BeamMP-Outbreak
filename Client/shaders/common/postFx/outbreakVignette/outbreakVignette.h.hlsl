#ifndef _OUTBREAKVIGNETTE_H_HLSL_
#define _OUTBREAKVIGNETTE_H_HLSL_

#include "../postFx.h.hlsl"

cbuffer perDraw
{
    float innerRadius;
    float outerRadius;
    float2 center;
    float4 color;

    POSTFX_UNIFORMS
};

uniform_sampler2D( backBuffer, 0 );

#include "../postFx.hlsl"

#endif //_OUTBREAKVIGNETTE_H_HLSL_
