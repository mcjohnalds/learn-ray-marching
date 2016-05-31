precision highp float;
uniform vec2 resolution;
uniform float time;
const float pi = 3.1415926535897932384626433832795;
const float fov = 80.0;
const float marchDist = 2.0;
const float initialMarchDist = 1.0;
const float marchTolerance = 0.02;
const float minDist = 1.0;
const float maxDist = 700.0;
const vec3 camPos = vec3(0.0, -40.0, 0.0);

// The sky light emits straight downwards everywhere equally
const vec3 skyLightColor = vec3(0.75, 0.75, 0.8) * 0.9;

// Sun point light
const vec3 sunLightPos = vec3(100.0, 120.0, -1000.0);
const vec3 sunLightColor = vec3(1.4);

// Primitive hashing function. At least works ok with numbers on the order of
// 10^-5 up to numbers on the order of 10^5. Outputs values between -1 and 1.
float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

// Static noise texture. Looks like the output of an analouge TV with no siganl.
float noise(in vec2 x) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f * f * (3.0-2.0 * f);
    float n = p.x + p.y * 57.0;
    float res = mix(
        mix(hash(n + 0.0), hash(n + 1.0), f.x),
        mix(hash(n + 57.0), hash(n + 58.0), f.x),
        f.y);
    return res;
}

// Fractional browniam motion gives a cloud-like texture. p is the position on
// the texture. A higher octaves value gives a rough and more interesting
// texture.
float fbm(vec2 p, int octaves) {
    // Pre-computed rotation matrix. Helps avoid many parallel lines and 90 deg
    // intersections that would otherwise occur.
    mat2 m = mat2(0.80,  0.60, -0.60,  0.80);
    float f = 0.0;
    float c = 0.5;
    float sum = 0.0;
    // WebGL doesn't support non-constants in a for loop statement so this is
    // a workaround.
    for (int i = 1; i >= 1; i++) { 
        f += c * noise(p);
        sum += c;
        c /= 2.0;
        p = m * p * 2.0;
        if (i == octaves) {
            break;
        }
    }
    return f / sum;
}

mat3 rotateXYZ(float x, float y, float z) {
    float sx = sin(x), cx = cos(x);
    float sy = sin(y), cy = cos(y);
    float sz = sin(z), cz = cos(z);
    return mat3(
        cy * cz, cy * sz, -sy,
        cz * sx * sy - cx * sz, cx * cz + sx * sy * sz, cy * sx,
        cx * cz * sy + sx * sz, -cz * sx + cx * sy * sz, cx * cy);
}

float terrain(float x, float z) {
    return pow(fbm(vec2(x + -3000., z) * 0.006, 1) * 30.0, 1.4) - 100. +
            fbm(vec2(x + 1000., z) * 0.02, 1) * 15.0 +
            fbm(vec2(x + 1000., z) * 0.1, 5) * 0.5;
}

vec3 getNormal(vec3 p) {
    float e = 0.1;
    vec3 n = vec3(
        terrain(p.x - e, p.z) - terrain(p.x + e, p.z),
        2.0 * e,
        terrain(p.x, p.z - e) - terrain(p.x, p.z + e)
    );
    return normalize(n);
}

float diffuse(vec3 p, vec3 n, vec3 lightPos) {
    vec3 l = normalize(lightPos - p);
    float iDiff = max(dot(n, l), 0.0);
    return clamp(iDiff, 0.0, 1.0);
}

float shadow(vec3 ro, vec3 rd) {
    float k = 20.0;
    float res = 1.0;
    for (float t = minDist; t <= maxDist; t += marchDist) {
        vec3 p = ro + rd * t;
        float h = terrain(p.x, p.z);
        if (p.y < h) {
            return 0.0;
        }
        res = min(res, k * abs(p.y - h) / t);
    }
    return res;
}

vec3 getShading(vec3 p, vec3 n) {
    float iSky = diffuse(p, n, p + vec3(0.0, 1.0, 0.0));
    float sh = shadow(p, normalize(sunLightPos - p));
    float iSun = diffuse(p, n, sunLightPos) * sh;

    return (skyLightColor * iSky + sunLightColor * iSun);
}

vec3 rayDirection() {
    vec2 ndc = gl_FragCoord.xy / resolution;
    vec2 screen = 2.0 * ndc - 1.0;
    float ar = resolution.x / resolution.y;
    float f = tan(fov / 2.0 * pi / 180.0);
    vec3 world = vec3(screen.x * ar * f, screen.y * f, -1);
    return normalize(world);
}

bool castRay(vec3 ro, vec3 rd, out float resT) {
    float dt = initialMarchDist;
    float lastH = terrain(ro.x, ro.z);
    float lastY = ro.y;
    // for (float t = minDist; t < maxDist; t += 0.) {
    float t = minDist;
    for (int i = 0; i >= 0; i++) { // Infinite loop
        if (t >= maxDist) break;
        vec3 p = ro + rd * t;
        float h = terrain(p.x, p.z);
        if (p.y < h) {
            // resT = t - 0.5 * dt;
            // Interp between lastH and h
            resT = t - dt + dt * (lastH - lastY) / (p.y - lastY - h + lastH); 
            return true;
        }
        dt = marchTolerance * t;
        t += dt;
        lastH = h;
        lastY = p.y;
    }
    return false;
}

float snowPresenceAtHeight(float y) {
    // Height we start to see snow
    float snowGradientStart = -90.;
    // Height after which everything becomes snow
    float snowGradientEnd = 43.;
    return smoothstep(snowGradientStart, snowGradientEnd, y);
}

vec3 material(vec3 p, vec3 n) {
    // Blend between rock and snow. Higher up, more snow. Flatter land, more
    // snow.
    
    float flatness = pow(n.y, 5.0);
    vec3 snowColor = vec3(2.8);
    vec3 rockColor = vec3(0.6);
    float randMixing = fbm(vec2(p.x, p.z) * 0.01, 2) - 0.5;
    randMixing += fbm(vec2(p.x * 1.5, p.z) * 0.05, 5) - 0.5;
    randMixing *= 0.1;
    float rockSnowMix = snowPresenceAtHeight(p.y) * flatness + randMixing;
    vec3 rockAndSnow = mix(rockColor, snowColor, rockSnowMix);

    // Blend grass and dirt to make 'girt'
    
    vec3 grassColor = vec3(0.70, 0.85, 0.40) * 0.8;
    vec3 dirtColor = vec3(0.7, 0.7, 0.4) * 0.7;
    float grassDirtMix = fbm(vec2(p.x + 5000., p.z) * 0.02, 2) * 0.6 +
                         fbm(vec2(p.x, p.z) * 1.0, 3) * 0.4;
    vec3 girt = mix(grassColor, dirtColor, grassDirtMix);
        
    // Blend between girt and rock. Higher up, more rock. Steeper cliff, more
    // rock.
    
    float rockGradientStart = -100.;
    float rockGradientEnd = -60.;
    float rockPresenceAtHeight = smoothstep(rockGradientStart, rockGradientEnd, p.y);
    float cliffness = pow(n.y, 30.0);
    vec3 girtAndRock = mix(girt, rockAndSnow,
                           rockPresenceAtHeight * (1. - cliffness));
    
    return girtAndRock;
}

vec3 skyColor() {
    vec3 blue = vec3(0.7, 0.75, 0.85) * 1.2;
    vec3 red = vec3(0.8, 0.65, 0.7) * 1.5;
    float y = gl_FragCoord.y / resolution.y;
    return mix(red, blue, clamp(y - 0.2, 0., 1.));
}

vec3 applyFog(vec3 original, float dist) {
    float density = 0.002;
    float falloff = 4.;
    float f = exp(-pow(dist * density, falloff));
    f = clamp(f, 0.0, 1.);
    return (1. - f) * skyColor() + f * original; 
}

void main(void) {
    vec3 ro = camPos;
    vec3 rd = rotateXYZ(-0.4, 0.0, 0.0) * rayDirection();
    
    float t;
    if (castRay(ro, rd, t)) {
        vec3 p = ro + rd * t;
        vec3 n = getNormal(p);
        vec3 s = getShading(p, n);
        vec3 m = material(p, n);
        gl_FragColor = vec4(applyFog(m * s, t), 1.0);
    } else {
        vec3 sunColor = vec3(0.8, 0.75, 0.6) * 1.5;
        float ar = resolution.x / resolution.y;
        vec2 p = gl_FragCoord.xy / resolution;
        p.x *= ar;
        float gradient = length(p - vec2(1.2, 1.0));
        float mixing = smoothstep(0., 0.1, gradient);
        gl_FragColor = vec4(mix(sunColor, skyColor(), mixing), 1.0);
    }
}
