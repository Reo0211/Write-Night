#include <metal_stdlib>
using namespace metal;

// ── Shared structs ────────────────────────────────────────────────────────────

struct MetalStar {
    float2 position;   // 8 bytes
    float  radius;     // 4 bytes
    float  brightness; // 4 bytes
    float4 color;      // 16 bytes (aligned)
    uint   type;       // 4 bytes
    uint   hasSparkle; // 4 bytes
};

struct QuadVertexIn {
    float2 position;
    float2 uv;
};

struct QuadVertexOut {
    float4 position [[position]];
    float2 uv;
};

// ── Noise / FBM helpers ───────────────────────────────────────────────────────

static float hash2(float2 p) {
    p = fract(p * float2(127.1, 311.7));
    p += dot(p, p + 17.5);
    return fract(p.x * p.y);
}

static float smoothNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash2(i + float2(0,0)), hash2(i + float2(1,0)), u.x),
        mix(hash2(i + float2(0,1)), hash2(i + float2(1,1)), u.x),
        u.y
    );
}

static float fbm5(float2 p) {
    float v = 0.0, a = 0.5;
    float2x2 rot = float2x2(0.8, 0.6, -0.6, 0.8);
    for (int i = 0; i < 5; i++) {
        v += a * smoothNoise(p);
        p  = rot * p * 2.1;
        a *= 0.5;
    }
    return v;
}

static float fbm3(float2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 3; i++) {
        v += a * smoothNoise(p);
        p *= 2.1; a *= 0.5;
    }
    return v;
}

// ── Background pass ───────────────────────────────────────────────────────────

vertex QuadVertexOut gradient_vertex(
    uint vid [[vertex_id]],
    const device QuadVertexIn *vertices [[buffer(0)]]
) {
    QuadVertexOut out;
    QuadVertexIn v = vertices[vid];
    out.position = float4(v.position, 0.0, 1.0);
    out.uv = v.uv;
    return out;
}

struct NebulaParams {
    float4 color;
    float2 center;
    float  radius;
    float  elongX;
    float  elongY;
    float  rotation;
    float  seed;
    float  _pad;
};

fragment float4 gradient_fragment(
    QuadVertexOut           in             [[stage_in]],
    constant float         &time           [[buffer(0)]],
    constant float2        &uvOffset       [[buffer(1)]],
    constant float3        &selectionState [[buffer(2)]],
    constant NebulaParams  *nebulae        [[buffer(3)]]
) {
    float2 uv = in.uv + uvOffset;

    // ── 1. Deep-space base gradient ───────────────────────────────

    float3 zenith  = float3(0.004, 0.006, 0.016);
    float3 midSky  = float3(0.003, 0.005, 0.012);
    float3 horizon = float3(0.003, 0.007, 0.022);


    float3 base = mix(horizon, midSky, smoothstep(0.0, 0.30, uv.y));
    base        = mix(base,   zenith,  smoothstep(0.30, 1.0, uv.y));

    // ── 2. Milky Way diagonal band ────────────────────────────────
    float bandT = uv.x;

    float centerWarp = fbm3(float2(uv.x * 3.2 + 1.1, uv.y * 2.5)) * 0.06 - 0.03;
    float bandCenter = 0.17 + bandT * 0.70 + centerWarp;
    float bandDist   = uv.y - bandCenter;

    float mwCore  = exp(-pow(bandDist / 0.110, 2.0));
    float mwHalo  = exp(-pow(bandDist / 0.380, 2.0));

    float mwBreak = fbm3(float2(uv.x * 4.5, uv.y * 6.5 + 2.3));
    mwCore *= 0.40 + 0.60 * mwBreak;
    mwHalo *= 0.60 + 0.40 * mwBreak;

    float3 coreColor = float3(0.08, 0.11, 0.22);
    float3 haloColor = float3(0.02, 0.03, 0.08);
    float3 mwColor   = mix(haloColor, coreColor, smoothstep(0.0, 0.6, mwCore));

    float edgeFade   = smoothstep(0.0, 0.12, uv.x) * smoothstep(1.0, 0.88, uv.x);
    float mwStrength = (mwCore * 0.28 + mwHalo * 0.12) * edgeFade;

    // ── 3. Random Nebulae ────────────────────────────────────────
    float3 nebulaAccum = float3(0.0);
    for (int ni = 0; ni < 3; ni++) {
        NebulaParams neb = nebulae[ni];

        // ── ドリフト（この辺処理重くなるかな、、、）
        float driftSpeed = 0.0018;
        float phase = neb.seed * 6.28;
        float2 drift = float2(
            sin(time * driftSpeed       + phase)       * 0.025,
            cos(time * driftSpeed * 0.7 + phase + 1.1) * 0.020
        );
        float2 d = uv - (neb.center + drift);

        // ── 回転
        float rot = neb.rotation + time * (3.14159 / 300.0) * (ni == 0 ? 1.0 : -0.7);
        float cosR = cos(rot), sinR = sin(rot);
        float2 dr  = float2(d.x * cosR - d.y * sinR,
                            d.x * sinR + d.y * cosR);
        
        float2 scaled = dr / float2(neb.elongX, neb.elongY);
        float  dist   = length(scaled) / neb.radius;

        // ── 形が変わるFBMワープ
        float2 warpUV = uv * 3.5 + neb.seed;
        float  morphT = time * 0.004;
        float2 warp   = float2(
            fbm3(warpUV + float2(1.3 + morphT, 8.7)),
            fbm3(warpUV + float2(7.1, 2.4 + morphT * 0.8))
        ) * 0.35;

        // ── 楕円比もゆっくり動かしたいだけ
        float breathe = sin(time * 0.008 + phase) * 0.12 + 1.0;
        float2 elongBreath = float2(neb.elongX * breathe, neb.elongY / breathe);
        float warpedDist = length((scaled + warp) / elongBreath) / neb.radius;

        // コアとハロー
        float core  = exp(-pow(warpedDist * 2.8, 1.8));
        float halo  = exp(-pow(warpedDist * 1.2, 2.2)) * 0.4;
        float shape = (core + halo) * neb.color.w;

        // 輝度も
        float flicker = fbm3(uv * 6.0 + float2(neb.seed + morphT * 0.5, neb.seed * 0.7)) * 0.5 + 0.5;
        float pulse   = sin(time * 0.012 + phase) * 0.15 + 0.85;
        shape *= (0.6 + 0.4 * flicker) * pulse;

        nebulaAccum += neb.color.xyz * shape;
    }
    base += nebulaAccum;
    
    //以下、かなり細かい動作群

    // ── 10. Domain-warped FBM nebulosity ───────────────────────────
    float2 nebBase = float2(uv.x * 4.2 + time * 0.004,
                            uv.y * 6.5 + time * 0.002);
    float2 warp = float2(
        fbm3(nebBase + float2(1.70, 9.20)),
        fbm3(nebBase + float2(8.30, 2.80))
    );
    float nebula = fbm5(float2(uv.x * 3.8, uv.y * 6.0) + warp * 0.40);
    nebula = pow(max(nebula - 0.25, 0.0) / 0.75, 1.8);

    float3 nebColorA = float3(0.10, 0.14, 0.28);
    float3 nebColorB = float3(0.22, 0.10, 0.18);
    float3 nebColor  = mix(nebColorA, nebColorB, smoothNoise(uv * 2.3));

    float nebulaStrength = nebula * mwHalo * edgeFade * 0.75;

    // ── 10. Dust lanes ─────────────────────────────────────────────
    float2 dustSeed = float2(uv.x * 5.5 + 3.1, uv.y * 8.0 + 1.7);
    float dust     = fbm3(dustSeed);
    float dustMask = exp(-pow(bandDist / 0.028, 2.0)) * dust * edgeFade * 0.60;

    // ── 10. Sagittarius-like warm patch ────────────────────────────
    float2 sagCenter = float2(0.72, bandCenter + 0.03);
    float  sagDist   = length((uv - sagCenter) * float2(1.0, 2.2));
    float  sagGlow   = exp(-sagDist * sagDist * 20.0) * 0.45;
    float3 sagColor  = float3(0.25, 0.14, 0.06) * sagGlow;

    // ── 10. Compose ────────────────────────────────────────────────
    float3 col = base;
    col += mwColor * mwStrength;
    col += nebColor * nebulaStrength;
    col -= float3(0.05, 0.07, 0.10) * dustMask;
    col += sagColor;

    // ── 10. Horizon glow ───────────────────────────────────────────
    float atm = exp(-uv.y * 9.0) * 0.035;
    col += float3(0.05, 0.07, 0.14) * atm;

    // ── 10. Breathing pulse ────────────────────────────────────────
    float pulse = 0.5 + 0.5 * sin(time * 0.07);
    col += float3(0.002, 0.003, 0.007) * pulse;

    // ── 10. Vignette ───────────────────────────────────────────────
    float2 vc  = uv - float2(0.50, 0.46);
    float vDst = length(vc * float2(1.0, 1.2));
    float vig  = smoothstep(0.80, 0.20, vDst);
    col *= 0.65 + 0.35 * vig;

    // ── 10. Filmic tone map ───────────────────────────────────────
    col = col / (col + float3(0.22)) * 1.05;
    col = mix(col, col * float3(0.96, 0.98, 1.02), 0.20);

    // 選択時の背景減光
    float selProgress = selectionState.z;
    if (selProgress > 1.0) {
        float dimAmt = clamp((selProgress - 1.0), 0.0, 1.0) * 0.40;
        col *= (1.0 - dimAmt);
    }

    return float4(saturate(col), 1.0);
}

// ── Star pass ─────────────────────────────────────────────────────────────────

struct StarVertexOut {
    float4 position  [[position]];
    float  radiusPx;
    float  brightness;
    float3 color;
    uint   type;
    uint   hasSparkle;
    float  seed;
    float  selProgress;
    float  currentTime;
    float  pointSize [[point_size]];
};

vertex StarVertexOut star_vertex(
    uint vid [[vertex_id]],
    const device MetalStar *stars   [[buffer(0)]],
    constant float2 &viewportSize   [[buffer(1)]],
    constant float  &time           [[buffer(2)]],
    constant float2 &uvOffset       [[buffer(3)]],
    constant float3 &selectionState [[buffer(4)]],
    constant float  &zoomProgress   [[buffer(5)]]
) {
    MetalStar s = stars[vid];

    float seed = fract(float(vid) * 0.6180339887 + float(vid / 7) * 0.3819660113);

    // ── Scintillation ──────────────────────────────────────────────
    float scintillation;
    float colorShift = 0.0;

    if (s.type == 0u) {
        // 背景の星
        float f1 = sin(time * (1.8 + seed * 3.5) + seed * 6.28);
        float f2 = sin(time * (3.1 + seed * 2.0) + seed * 12.57) * 0.4;
        scintillation = 0.72 + 0.28 * clamp((f1 + f2) * 0.5 + 0.5, 0.0, 1.0);
    } else {
        
        // ここからがメモ星
        
        // 低
        float slow  = sin(time * (0.15 + seed * 0.3)  + seed * 6.28);
        // 中
        float mid1  = sin(time * (0.55 + seed * 0.8)  + seed * 9.42);
        float mid2  = sin(time * (0.85 + seed * 0.6)  + seed * 3.14) * 0.6;
        // 高
        float fast1 = sin(time * (1.8 + seed * 1.2)   + seed * 15.7) * 0.35;
        float fast2 = sin(time * (2.6 + seed * 0.9)   + seed * 21.9) * 0.20;
        // スパイク
        float spike = pow(max(sin(time * (0.35 + seed * 0.5) + seed * 4.71), 0.0), 6.0) * 0.5;

        float raw = slow * 0.25 + mid1 * 0.30 + mid2 * 0.20 + fast1 + fast2 + spike;
        scintillation = 0.62 + 0.38 * clamp(raw * 0.5 + 0.5, 0.0, 1.0);

        colorShift = clamp(fast1 + fast2, -0.15, 0.15);
    }

    float2 pos01 = s.position + uvOffset;

    // ── ズームイン

    float distFromCenter = length(pos01 - float2(0.5, 0.5));
    float delay  = distFromCenter * 0.3;
    float localT = saturate((zoomProgress - delay) / max(1.0 - delay, 0.001));
    float eased  = 1.0 - pow(1.0 - localT, 3.0);  // easeOutCubic
    pos01 = mix(float2(0.5, 0.5), pos01, eased);

    float2 posClip = float2(pos01.x * 2.0 - 1.0, pos01.y * 2.0 - 1.0);

    StarVertexOut out;
    out.position  = float4(posClip, 0.0, 1.0);
    out.seed      = seed;

    float scale    = (s.type == 0u) ? 1.6 : 2.6;
    float radiusPx = s.radius * scale * scintillation;
    out.radiusPx   = radiusPx;
    float zoomScale = mix(4.0, 1.0, saturate(zoomProgress * 1.3));
    out.pointSize  = max(radiusPx * 3.8, 1.5) * zoomScale;

    // ── 選択エフェクト
    float selProg = selectionState.z;
    float finalBrightness = s.brightness * scintillation;

    if (selProg >= 0.0 && s.type == 1u) {
        float2 selPos = selectionState.xy;
        float dist = length(s.position - selPos);

        if (dist < 0.04) {

            if (selProg <= 1.0) {
                float spike = sin(selProg * 3.14159) ;
                finalBrightness *= (1.0 + spike * 10.0);
            }
        }
    }


    if (selProg > 1.0 && s.type == 1u) {
        float2 selPos = selectionState.xy;
        float dist = length(s.position - selPos);
        if (dist >= 0.04) {
            float dimAmt = clamp((selProg - 1.0), 0.0, 1.0) * 0.50;
            finalBrightness *= (1.0 - dimAmt);
        }
    }
    // 背景星も減光
    if (selProg > 1.0 && s.type == 0u) {
        float dimAmt = clamp((selProg - 1.0), 0.0, 1.0) * 0.45;
        finalBrightness *= (1.0 - dimAmt);
    }

    out.brightness = finalBrightness;

    float3 baseCol = s.color.xyz;
    if (s.type == 1u) {
        baseCol.x = clamp(baseCol.x - colorShift * 0.4, 0.0, 1.0);  // R減
        baseCol.z = clamp(baseCol.z + colorShift * 0.5, 0.0, 1.0);  // B増
    }
    out.color      = baseCol;
    out.type       = s.type;
    out.hasSparkle = s.hasSparkle;

    // 選択された星にのみ進行度を渡す
    float2 selPos2 = selectionState.xy;
    float  selDist = length(s.position - selPos2);
    out.selProgress = (s.type == 1u && selProg >= 0.0 && selDist < 0.04) ? selProg : -1.0;
    out.currentTime = time;

    return out;
}

fragment float4 star_fragment(
    StarVertexOut in [[stage_in]],
    float2 pointCoord [[point_coord]]
) {
    float2 c = pointCoord * 2.0 - 1.0;
    float  r = length(c);
    if (r > 1.0) { discard_fragment(); }

    float brightness = in.brightness;
    float3 baseColor = in.color.xyz;

    // ── Airy-disk PSF ─────────────────────────────────────────────
    float core   = exp(-pow(r * 3.8, 2.2));
    float inner  = exp(-pow(r * 1.6, 2.0)) * 0.30;
    float outer  = 1.0 / (1.0 + pow(r * 4.5, 3.0)) * 0.18;
    float profile = core + inner + outer;

    // ── Diffraction spikes ─────────────────────────────────────────
    float spikes    = 0.0;
    float3 spikeCol = baseColor;

    if (in.type == 1u && in.hasSparkle == 1u) {
        float sx  = exp(-abs(c.x) * 9.5)  * exp(-abs(c.y) * 1.8);
        float sy  = exp(-abs(c.y) * 9.5)  * exp(-abs(c.x) * 1.8);
        float2 d45 = float2(c.x + c.y, c.x - c.y) * 0.7071;
        float sd1  = exp(-abs(d45.x) * 13.0) * exp(-abs(d45.y) * 2.2);
        float sd2  = exp(-abs(d45.y) * 13.0) * exp(-abs(d45.x) * 2.2);
        spikes   = (sx + sy) * 0.50 + (sd1 + sd2) * 0.18;
        spikeCol = mix(baseColor, float3(0.75, 0.88, 1.0), spikes * 0.5);
    }

    if (in.type == 0u && brightness > 0.55) {
        float sx = exp(-abs(c.x) * 18.0) * exp(-abs(c.y) * 4.0);
        float sy = exp(-abs(c.y) * 18.0) * exp(-abs(c.x) * 4.0);
        spikes += (sx + sy) * brightness * 0.18;
    }

    // ── 選択次の十字光線 ─────────────────────────────────────────────
    float crossBeam = 0.0;
    if (in.selProgress >= 0.0) {
        float prog;
        if (in.selProgress <= 1.0) {

            prog = smoothstep(0.0, 0.7, in.selProgress);
        } else {

            prog = 1.0;
        }

        float width = 0.055;

        // ゆっくり回転（1周 = 40秒）
        float angle = in.currentTime * (3.14159 * 2.0 / 40.0);
        float cosA = cos(angle), sinA = sin(angle);
        float2 cr = float2(c.x * cosA - c.y * sinA,
                           c.x * sinA + c.y * cosA);

        float bx = exp(-pow(abs(cr.x) / width, 2.0)) * exp(-pow(abs(cr.y) * 1.2, 0.8));
        float by = exp(-pow(abs(cr.y) / width, 2.0)) * exp(-pow(abs(cr.x) * 1.2, 0.8));
        crossBeam = clamp((bx + by) * prog * 1.8, 0.0, 1.0);
    }

    float totalIntensity = profile + spikes + crossBeam;

    // ── Chromatic aberration ───────────────────────────────────────
    float rProf = exp(-pow(r * 4.2, 2.2));
    float bProf = exp(-pow(r * 3.2, 2.2));
    float chromaStrength = clamp((brightness - 0.4) * 0.5, 0.0, 0.35);
    float3 chromaColor   = float3(rProf, profile, bProf) * baseColor;
    float3 col = mix(baseColor * profile, chromaColor, chromaStrength);
    col = mix(col, spikeCol * profile, clamp(spikes * 0.6, 0.0, 1.0));

    float typeScale = (in.type == 0u) ? 0.72 : 1.45;
    brightness = clamp(brightness * typeScale, 0.0, 2.0);
    // 十字光線は白〜水色
    if (in.selProgress >= 0.0 && crossBeam > 0.0) {
        float3 beamCol = mix(float3(0.8, 0.9, 1.0), float3(1.0, 1.0, 1.0), crossBeam);
        col = mix(col, beamCol, clamp(crossBeam * 0.85, 0.0, 1.0));
    }
    col *= brightness;
    col *= 1.0 - r * r * 0.15;

    float alpha = clamp(totalIntensity * min(brightness, 1.3), 0.0, 1.0);
    return float4(col, alpha);
}

// MARK: - Moon

struct MoonVertexOut {
    float4 position  [[position]];
    float  pointSize [[point_size]];
};

vertex MoonVertexOut moon_vertex(
    constant float2& pos  [[buffer(0)]],
    constant float&  size [[buffer(1)]])
{
    float2 ndc = float2(pos.x * 2.0 - 1.0, 1.0 - pos.y * 2.0);
    MoonVertexOut out;
    out.position  = float4(ndc, 0.0, 1.0);
    out.pointSize = size;
    return out;
}


fragment float4 moon_fragment(
    MoonVertexOut   in         [[stage_in]],
    float2          pointCoord [[point_coord]],
    constant float& phase      [[buffer(0)]])
{
    float2 p    = pointCoord * 2.0 - 1.0;
    float  dist = length(p);
    
    if (dist > 1.0) { discard_fragment(); }
    
    float bodyRadius = 0.35;
    float bodyMask = smoothstep(bodyRadius + 0.02, bodyRadius - 0.02, dist);
    
    float2 bp = p / bodyRadius;
    
    // 月っぽくなる模様（なるわけない）
    float n = fbm5(bp * 1.8 + float2(3.1, 4.2));
    float3 highlandCol = float3(0.95, 0.95, 0.90);
    float3 mareCol     = float3(0.78, 0.78, 0.75);
    float3 moonCol = mix(mareCol, highlandCol, smoothstep(0.40, 0.55, n));
    
    float detail = fbm3(bp * 6.0);
    moonCol *= 0.95 + 0.1 * detail;
    
    float z = sqrt(max(0.0, 1.0 - dot(bp, bp)));
    moonCol *= mix(0.85, 1.0, z);

    float3 shadowCol = float3(0.04, 0.05, 0.13);

    // 満ち欠け
    float inShadow = 0.0;
    if (phase >= 0.5) {
        float xr = (phase - 0.5) * 2.0;
        bool litEllipse = (xr > 0.001) ? ((bp.x*bp.x/(xr*xr) + bp.y*bp.y) <= 1.0) : false;
        bool litLeft    = bp.x <= 0.0;
        inShadow = (litEllipse || litLeft) ? 0.0 : 1.0;
    } else {
        float xr = (0.5 - phase) * 2.0;
        bool shadowRight   = bp.x >= 0.0;
        bool shadowEllipse = (xr > 0.001) ? ((bp.x*bp.x/(xr*xr) + bp.y*bp.y) <= 1.0) : false;
        inShadow = (shadowRight || shadowEllipse) ? 1.0 : 0.0;
    }

    float3 bodyColor = mix(moonCol, shadowCol, inShadow);
    bodyColor += float3(0.55, 0.75, 1.0) * 0.12 * (1.0 - (dist / bodyRadius)) * (1.0 - inShadow);
    
    //  外側グロー（なしでもいいかも）
    float3 glowColor = float3(1.0, 0.95, 0.75);
    

    float glowIntensity = 0.25 * phase;
    
    float glowFactor = smoothstep(1.0, bodyRadius, dist);
    float3 outerGlow = glowColor * glowFactor * glowIntensity * (1.0 - bodyMask);
    
    // 合成
    float3 finalColor = (bodyColor * bodyMask) + outerGlow;
    float alpha = bodyMask * 0.85 + glowFactor * glowIntensity * (1.0 - bodyMask);
    
    return float4(finalColor, alpha);
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Memory Planets　記憶の惑星
// ─────────────────────────────────────────────────────────────────────────────

struct PlanetVertexIn {
    packed_float2 position;
    float         pointSize;
    uint          planetType;
};

struct PlanetVertexOut {
    float4 position  [[position]];
    float  pointSize [[point_size]];
    uint   ptype     [[flat]];
};

vertex PlanetVertexOut planet_vertex(
    uint vid [[vertex_id]],
    constant PlanetVertexIn* planets [[buffer(0)]],
    constant float2& uvOffset [[buffer(1)]]
) {
    PlanetVertexIn p = planets[vid];
    // parallax 適用（月と同じ符号規則）
    float2 pos = float2(p.position.x + uvOffset.x,
                        p.position.y - uvOffset.y);
    // screen→NDC
    float2 ndc = float2(pos.x * 2.0 - 1.0, 1.0 - pos.y * 2.0);

    PlanetVertexOut out;
    out.position  = float4(ndc, 0.0, 1.0);
    out.pointSize = p.pointSize;
    out.ptype     = p.planetType;
    return out;
}

fragment float4 planet_fragment(
    PlanetVertexOut in [[stage_in]],
    float2 pc [[point_coord]]
) {
    uint   t  = in.ptype;
    float2 uv = pc * 2.0 - 1.0;
    float  r  = length(uv);

    // ── ベースカラー（宣言時に初期化）
    float3 base = float3(0.72, 0.70, 0.68);
    if      (t == 1u) base = float3(0.92, 0.82, 0.60);
    else if (t == 2u) base = float3(0.80, 0.40, 0.25);
    else if (t == 3u) base = float3(0.78, 0.65, 0.50);
    else if (t == 4u) base = float3(0.88, 0.80, 0.62);
    else if (t == 5u) base = float3(0.55, 0.85, 0.88);
    else if (t == 6u) base = float3(0.35, 0.50, 0.90);

    // ── グローカラー（宣言時に初期化）
    float3 glowTint = float3(0.85, 0.90, 1.00);
    if      (t == 0u) glowTint = float3(0.70, 0.80, 1.00);
    else if (t == 1u) glowTint = float3(1.00, 0.90, 0.40);
    else if (t == 2u) glowTint = float3(1.00, 0.55, 0.50);
    else if (t == 3u) glowTint = float3(1.00, 0.96, 0.90);
    else if (t == 4u) glowTint = float3(1.00, 0.98, 0.88);
    else if (t == 5u) glowTint = float3(0.88, 0.98, 1.00);
    else if (t == 6u) glowTint = float3(0.85, 0.90, 1.00);

    float  coreR = 0.35;

    // ── Airy-disk PSF グロー
    float rn  = r / coreR;
    float g0  = exp(-rn * rn * 4.84) * 0.80;
    float g1  = exp(-rn * rn * 0.40) * 0.70;
    float g2  = 1.0 / (1.0 + rn * rn * rn * 5.0) * 0.55;
    float psf = g0 + g1 + g2;

    float  blend   = min(1.0, max(0.0, (rn - 0.5) / 1.5));
    float3 glowCol = mix(base, glowTint, blend * 0.7);
    float3 outCol  = glowCol * psf;
    float  outA    = psf * 0.85;

    // ── コア球体
    if (r < coreR) {
        float2 uvN   = uv / coreR;
        float  d2    = dot(uvN, uvN);
        float3 nrm   = normalize(float3(uvN, sqrt(max(0.001, 1.0 - d2))));
        float3 light = normalize(float3(0.55, 0.75, 1.0));
        float  diff  = max(0.0, dot(nrm, light));
        float3 cCol  = base * (0.30 + 0.70 * diff);

        if (t == 3u) {
            float band = sin(uvN.y * 18.0) * 0.5 + 0.5;
            cCol += float3(0.10, 0.05, 0.0) * band * 0.20;
        }
        if (t == 5u) {
            cCol = mix(cCol, float3(0.6, 0.95, 0.95), 0.18 * (1.0 - diff));
        }

        float edge = 1.0 - smoothstep(coreR * 0.80, coreR, r);
        float cA   = edge * 0.92;
        outCol = mix(outCol, cCol, cA);
        outA   = max(outA, cA);
    }

    // ── 土星リング
    if (t == 4u) {
        float2 ruv = float2(uv.x / 0.70, uv.y / 0.22);
        float  rR  = length(ruv);
        if (rR > 0.80 && rR < 1.25) {
            float rEdge = max(0.0, 1.0 - abs(rR - 1.02) / 0.22);
            float rA    = rEdge * 0.40;
            if (r > coreR * 0.95) {
                outCol += float3(0.88, 0.80, 0.60) * rA * (1.0 - outA);
                outA   += rA * (1.0 - outA);
            }
        }
    }

    // ── 円形マスク
    float mask = 1.0 - smoothstep(0.40, 1.0, r);
    outCol *= mask;
    outA   *= mask;

    if (outA < 0.01) { discard_fragment(); }
    return float4(outCol, outA);
}
