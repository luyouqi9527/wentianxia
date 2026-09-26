#include <flutter/runtime_effect.glsl>

// ============================================================================
// 液态玻璃 · 边缘折射（true backdrop refraction）
// ============================================================================
//
// 这是 ImageFilter.shader 的输入着色器：引擎会把**背景纹理**绑到第 0 个
// sampler2D，把该纹理的尺寸写进第 0 个 float uniform（vec2，占索引 0/1）。
// 因此这里能直接对**真实背景像素**做重采样 —— 这才是"液态玻璃"的定义性特征
// （边缘折射透镜），而不是只有 blur() 的毛玻璃。
//
// 算法链（严格对齐《液态玻璃实现技术文档》第 1 章 / Kyant0 AGSL 实现）：
//   圆角矩形 SDF → 归一化深度 t = -sd / refractHeight → 位移剖面
//   circleMap(x) = 1 - sqrt(1 - x²)（圆形倒角 + Snell 近似）
//   → 法线 normalize(∇SDF) → sampleCoord = coord + d × grad × amount
//   → 按 R/G/B 略微不同的位移采样 → 色散（chromatic dispersion）
//
// ⚠️ 约定（写错就没反应 / 报错）：
//   * uniform 索引按**声明顺序**，vec2/vec3/vec4 每个分量各占一个索引；
//   * 第 0 个 uniform **必须是 vec2**，且**不要**从 Dart 侧 set；
//   * 第 1 个 sampler2D 是引擎绑定的背景，也**不要**从 Dart 侧 set；
//   * 本文件里 FlutterFragCoord 与背景纹理坐标同处一个像素空间（已实测），
//     故 uSize 仅用于算归一化 UV，不做 y 翻转。
// ============================================================================

// ---- 引擎自动填充（不要从 Dart 设置） ----
uniform vec2 uSize;          // 索引 0,1：被绑定纹理的尺寸
uniform sampler2D uBackdrop; // 索引 0（sampler 空间）：背景纹理

// ---- 由 Dart 设置的参数（从索引 2 开始） ----
uniform float uRadius;       // 2：圆角半径（px）
uniform float uRefractHeight; // 3：折射带宽度（px），= bezel / refractionAmount
uniform float uRefractAmount; // 4：位移强度（px）
uniform float uSpecular;     // 5：边缘高光强度 0..1
uniform float uLightAngle;   // 6：光源角度（弧度，默认 45°）
uniform float uDispersion;   // 7：色散强度 0..1
uniform float uInnerShadow;  // 8：内阴影强度 0..1
uniform float uSaturation;   // 9：饱和度（1.3~1.6，低了会发灰）
uniform float uTintAlpha;    // 10：中心区域额外压暗（保证玻璃上文字可读）

out vec4 fragColor;

// 圆角矩形 SDF：< 0 在内部、= 0 在边界、> 0 在外部
float sdRoundRect(vec2 p, vec2 halfSize, float radius) {
    vec2 q = abs(p) - (halfSize - vec2(radius));
    float outside = length(max(q, 0.0)) - radius;
    float inside = min(max(q.x, q.y), 0.0);
    return outside + inside;
}

// 法线 = normalize(∇SDF)，解析梯度
vec2 gradRoundRect(vec2 p, vec2 halfSize, float radius) {
    vec2 q = abs(p) - (halfSize - vec2(radius));
    if (q.x > 0.0 || q.y > 0.0) {
        vec2 g = normalize(max(q, vec2(0.0)));
        return vec2(g.x * (p.x < 0.0 ? -1.0 : 1.0), g.y * (p.y < 0.0 ? -1.0 : 1.0));
    }
    // 边中点区域：法线沿坐标轴指向最近的边
    return q.x > q.y
        ? vec2(p.x < 0.0 ? -1.0 : 1.0, 0.0)
        : vec2(0.0, p.y < 0.0 ? -1.0 : 1.0);
}

// 圆形倒角剖面：中心位移 0 → 边缘位移最大
float circleMap(float x) {
    float t = clamp(x, 0.0, 1.0);
    return 1.0 - sqrt(1.0 - t * t);
}

void main() {
    vec2 coord = FlutterFragCoord().xy;
    vec2 uv = coord / uSize;
    vec2 halfSize = uSize * 0.5;

    // 支持超出一半点尺寸的圆角（胶囊）
    float radius = clamp(uRadius, 0.0, min(halfSize.x, halfSize.y));

    vec2 centered = coord - halfSize;
    float sd = sdRoundRect(centered, halfSize, radius);
    float depth = -sd;                       // 内部为正

    vec4 color;

    if (depth <= 0.0 || uRefractHeight <= 0.5 || uRefractAmount <= 0.0) {
        // 玻璃外沿 或 未启用折射 → 原样采样（中心保持不变）
        color = texture(uBackdrop, uv);
    } else {
        // 归一化深度：0 = 折射带内边界（不动），1 = 边缘（位移最大）
        float t = clamp(depth / uRefractHeight, 0.0, 1.0);
        float profile = circleMap(t);
        float d = profile * uRefractAmount;

        // 文档坑位 4：梯度半径必须用 min(r × 1.5, min(halfW, halfH))，
        // 否则圆角处会出现放射状折痕
        float gradRadius = min(radius * 1.5, min(halfSize.x, halfSize.y) * 0.5);
        vec2 grad = gradRoundRect(centered, halfSize, gradRadius);

        // 折射：把背景像素沿法线方向"吸"向边缘 → 边缘放大（凸透镜）
        vec2 sampleCoord = coord + grad * d;

        // 色散：R/B 通道相对 G 通道多/少偏移一点，边缘出现冷暖色边
        float dispersion = uDispersion * clamp(profile, 0.0, 1.0);
        float dispPx = d * 0.12 * dispersion;
        vec3 warped = vec3(
            texture(uBackdrop, (sampleCoord + grad * dispPx) / uSize).r,
            texture(uBackdrop, sampleCoord / uSize).g,
            texture(uBackdrop, (sampleCoord - grad * dispPx) / uSize).b
        );

        // 边缘高光：SDF 法线与 45° 光源点积（abs → 两侧都亮，双面反光）
        vec2 lightDir = vec2(cos(uLightAngle), sin(uLightAngle));
        float spec = abs(dot(grad, lightDir));
        spec = pow(spec, 2.5) * uSpecular * clamp(profile, 0.0, 1.0);
        warped += vec3(spec);

        // 内阴影：玻璃厚度感（上暗下亮）
        float v = centered.y / max(halfSize.y, 1.0);
        float inner = uInnerShadow * clamp(profile, 0.0, 1.0);
        warped += vec3(-inner * 0.5 * (0.5 - v * 0.5) + inner * 0.25 * (v * 0.5 + 0.5));

        // 玻璃质感：轻微提饱和（文档：saturation 1.3~1.6）
        float luma = dot(warped, vec3(0.2126, 0.7152, 0.0722));
        warped = mix(vec3(luma), warped, uSaturation);

        // 中心区域压一点暗，保证玻璃上的文字有对比度
        float centerMask = 1.0 - clamp(profile, 0.0, 1.0);
        warped *= (1.0 - uTintAlpha * centerMask);

        color = vec4(clamp(warped, 0.0, 1.0), 1.0);
    }

    fragColor = color;
}
