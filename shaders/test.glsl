precision mediump float;
uniform vec2 resolution;
uniform float time;
uniform vec2 cursor;
const float pi = 3.1415926535897932384626433832795;
const float fov = 80.0;
const float drawDistance = 500.0;
const int maxMarches = 5000;
const float marchEpsilon = 0.0001;
const vec3 camPos = vec3(0.0, 25., 40.);

int groundMat = 0;
int buildingMat = 10;

struct Obj {
    float d;
    int mat;
};

mat3 rotateXYZ(float x, float y, float z) {
    float sx = sin(x), cx = cos(x);
    float sy = sin(y), cy = cos(y);
    float sz = sin(z), cz = cos(z);
    return mat3(
        cy * cz, cy * sz, -sy,
        cz * sx * sy - cx * sz, cx * cz + sx * sy * sz, cy * sx,
        cx * cz * sy + sx * sz, -cz * sx + cx * sy * sz, cx * cy);
}

float opU(float d1, float d2) {
    return min(d1, d2);
}

Obj opUObj(Obj o1, Obj o2) {
    float d = min(o1.d, o2.d);
    int mat = d == o1.d ? o1.mat : o2.mat;
    return Obj(d, mat);
}

float opS(float d1, float d2) {
    return max(d1, -d2);
}

float opI(float d1, float d2) {
    return max(d1, d2);
}

float sdfSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdfCube(vec3 p, float s) {
    vec3 d = abs(p) - s;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

// n must be normalized
float sdfPlane(vec3 p, vec4 n) {
    return dot(p, n.xyz) + n.w;
}

float sdfBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdfCylinderX(vec3 p, vec2 h) {
  vec2 d = abs(vec2(length(p.yz), p.x)) - h;
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdfCylinderY(vec3 p, vec2 h) {
  vec2 d = abs(vec2(length(p.xz), p.y)) - h;
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdfCylinderZ(vec3 p, vec2 h) {
  vec2 d = abs(vec2(length(p.xy), p.z)) - h;
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

vec3 opRepX(vec3 p, float c) {
    p.x = mod(p.x, c) - c * 0.5;
    return p;
}

// Repeat around the origin by a fixed angle.
// For easier use, num of repetitions is use to specify the angle.
float pModPolar(inout vec2 p, float repetitions) {
	float angle = 2. * pi / repetitions;
	float a = atan(p.y, p.x) + angle/2.;
	float r = length(p);
	float c = floor(a / angle);
	a = mod(a, angle) - angle / 2.;
	p = vec2(cos(a), sin(a)) * r;
	// For an odd number of repetitions, fix cell index of the cell in -x direction
	// (cell index would be e.g. -5 and 5 in the two halves of the cell):
	if (abs(c) >= (repetitions / 2.)) c = abs(c);
	return c;
}

Obj ground(vec3 p) {
    float d = sdfPlane(p, vec4(0., 1., 0., 1.));
    return Obj(d, groundMat);
}

Obj test(vec3 p) {
    pModPolar(p.xz, 5.);
    p.x -= 10.;
    pModPolar(p.xy, 5.);
    p.y -= 1.;
    float d = sdfBox(p, vec3(5.));
    return Obj(d, buildingMat);
}

Obj sdfScene(vec3 p) {
    // return opUObj(ground(p), test(p));
    return test(p);
}

vec3 rayDirection() {
    vec2 ndc = gl_FragCoord.xy / resolution;
    vec2 screen = 2.0 * ndc - 1.0;
    float ar = resolution.x / resolution.y;
    float f = tan(fov / 2.0 * pi / 180.0);
    vec3 world = vec3(screen.x * ar * f, screen.y * f, -1);
    return normalize(world);
}

vec3 normal(vec3 p) {
    float e = 0.0001;
    vec3 n = vec3(
        sdfScene(vec3(p.x + e, p.y, p.z)).d - sdfScene(vec3(p.x - e, p.y, p.z)).d,
        sdfScene(vec3(p.x, p.y + e, p.z)).d - sdfScene(vec3(p.x, p.y - e, p.z)).d,
        sdfScene(vec3(p.x, p.y, p.z + e)).d - sdfScene(vec3(p.x, p.y, p.z - e)).d
    );
    return normalize(n);
}

float diffuse(vec3 p, vec3 n, vec3 lightPos) {
    vec3 l = normalize(lightPos - p);
    float iDiff = max(dot(n, l), 0.0);
    return clamp(iDiff, 0.0, 1.0);
}

float specular(vec3 p, vec3 n, float shininess, vec3 viewPos, vec3 lightPos) {
    vec3 l = normalize(lightPos - p);
    vec3 r = reflect(-l, n);
    vec3 c = normalize(viewPos - p);
    float iSpec = pow(max(dot(r, c), 0.0), shininess);
    return clamp(iSpec, 0.0, 1.0);
}

vec3 shading(vec3 p, vec3 n, int mat) {
    vec3 materialDiff;
    vec3 materialSpec;
    float shininess;
    
    if (mat == groundMat) {
        materialDiff = vec3(0.5, 0.5, 0.5);
        materialSpec = vec3(0.05);
        shininess = 1.0;
    } else if (mat == buildingMat) {
        materialDiff = vec3(0.8, 0.7, 0.5);
        materialSpec = vec3(0.05);
        shininess = 1.;
    }
    
    vec3 diff = vec3(0.);
    vec3 spec = vec3(0.);
    
    // The sky light emits straight downwards everywhere equally
    vec3 skyLightPos = vec3(0., 1e5, 0.);
    vec3 skyLightColor = vec3(0.75, 0.75, 0.8) * 0.5;
    diff += skyLightColor * diffuse(p, n, skyLightPos);
    
    // Sun point light
    const vec3 sunLightPos = vec3(100.0, 120.0, 1000.0);
    const vec3 sunLightColor = vec3(0.3);
    diff += sunLightColor * diffuse(p, n, sunLightPos);
    spec += sunLightColor * specular(p, n, shininess, camPos, sunLightPos);
    
    // Camera light
    vec3 camLightColor = vec3(1.);
    diff += camLightColor * diffuse(p, n, camPos);
    spec += camLightColor * specular(p, n, shininess, camPos, camPos);

    return materialDiff * diff + materialSpec * spec + vec3(0.05);
}

void main(void) {
    vec3 ro = camPos;
    vec3 rd = rotateXYZ(-0.24, 0.0, 0.0) * rayDirection();
    float sceneYaw = ((resolution.x - cursor.x) / resolution.x * 2. - 1.) * pi;
    float scenePitch = min((cursor.y / resolution.y * 2. - 1.), 0.4);

    float t = 0.0;
    for (int i = 0; i < maxMarches; i++) {
        vec3 p = rotateXYZ(scenePitch, sceneYaw, 0.) * (ro + rd * t);
        Obj o = sdfScene(p);
        t += o.d;

        if (o.d < marchEpsilon) {
            vec3 n = normal(p);
            vec3 s = shading(p, n, o.mat);
            gl_FragColor = vec4(s, 1.0);
            break;
        }
        
        if (t > drawDistance) {
            gl_FragColor = vec4(0.0);
            break;
        }
    }
}
