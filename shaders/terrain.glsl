precision highp float;
uniform vec2 resolution;
uniform float time;
const float pi = 3.1415926535897932384626433832795;
const float fov = 80.0;
const float marchDist = 1.0;
const float minDist = 0.1;
const float maxDist = 700.0;
const vec3 camPos = vec3(0.0, 40.0, 0.0);

// The sky light emits straight downwards everywhere equally
const vec3 skyLightColor = vec3(0.57, 0.87, 0.88) * 0.7;

// Sun point light
const vec3 sunLightPos = vec3(0.0, 10.0, 10.0);
const vec3 sunLightColor = vec3(0.98, 0.87, 0.57) * 0.6;

const vec3 materialColor = vec3(0.70, 0.95, 0.40);

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
            fbm(vec2(x + 1000., z) * 0.02, 1) * 10.0 +
            fbm(vec2(x + 1000., z) * 0.09, 3) * 0.5;
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

vec3 getShading(vec3 p, vec3 n) {
    float iSky = diffuse(p, n, p + vec3(0.0, 1.0, 0.0));
    float iSun = diffuse(p, n, sunLightPos);

    return materialColor * (skyLightColor * iSky + sunLightColor * iSun);
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
    for (float t = minDist; t < maxDist; t += marchDist) {
        vec3 p = ro + rd * t;
        if (p.y < terrain(p.x, p.z)) {
            resT = t - 0.5 * marchDist;
            return true;
        }
    }
    return false;
}

void main(void) {
    vec3 ro = camPos;
    vec3 rd = rotateXYZ(-0.6, 0.0, 0.0) * rayDirection();
    
    float t;
    if (castRay(ro, rd, t)) {
        vec3 p = ro + rd * t;
        vec3 n = getNormal(p);
        vec3 s = getShading(p, n);
        gl_FragColor = vec4(s, 1.0);
    } else {
        gl_FragColor = vec4(0.0);
    }
}
