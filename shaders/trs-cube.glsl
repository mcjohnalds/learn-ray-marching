precision mediump float;
uniform vec2 resolution;
uniform float time;
const float pi = 3.1415926535897932384626433832795;
const float fov = 90.0;
const float drawDistance = 125.0;
const int maxMarches = 200;
const float marchEpsilon = 0.001;
const vec3 camPos = vec3(0.0, 0.0, 1.5);
const vec3 lightPos = vec3(1.0, 1.0, 1.0);
const vec3 lightDiffuse = vec3(1.4);
const vec3 lightSpecular = vec3(0.9);
const vec3 ambientLight = vec3(0.05);
const vec3 shapeDiffuse = vec3(0.95, 0.2, 0.2);
const vec3 shapeSpecular = vec3(0.7);
const float shapeShininess = 16.0;

mat3 rotateXYZ(float x, float y, float z) {
    float sx = sin(x), cx = cos(x);
    float sy = sin(y), cy = cos(y);
    float sz = sin(z), cz = cos(z);
    return mat3(
        cy * cz, cy * sz, -sy,
        cz * sx * sy - cx * sz, cx * cz + sx * sy * sz, cy * sx,
        cx * cz * sy + sx * sz, -cz * sx + cx * sy * sz, cx * cy);
}

// Cube signed distance function. Explained later.
float cubeSDF(vec3 p, float s) {
    vec3 d = abs(p) - s;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float scene(vec3 p) {
    // Translate
    p -= vec3(1.0 * sin(time), 0.0, 0.0);

    // Rotate
    float r = time;
    p = rotateXYZ(r, 0.0, 0.0) * p;

    // Scale factor
    float s = 1.0 + 0.5 * sin(time);

    return cubeSDF(p / s, 0.2) * s;
}

vec3 rayDirection() {
    vec2 ndc = gl_FragCoord.xy / resolution;
    vec2 screen = 2.0 * ndc - 1.0;
    float ar = resolution.x / resolution.y;
    float f = tan(fov / 2.0 * pi / 180.0);
    vec3 world = vec3(screen.x * ar * f, screen.y * f, -1);
    return normalize(world);
}

vec3 getNormal(vec3 p) {
    float e = 0.001;
    vec3 n = vec3(
        scene(vec3(p.x + e, p.y, p.z)) - scene(vec3(p.x - e, p.y, p.z)),
        scene(vec3(p.x, p.y + e, p.z)) - scene(vec3(p.x, p.y - e, p.z)),
        scene(vec3(p.x, p.y, p.z + e)) - scene(vec3(p.x, p.y, p.z - e))
    );
    return normalize(n);
}

vec3 getShading(vec3 p) {
    vec3 n = getNormal(p);
    vec3 l = normalize(lightPos - p);
    float iDiff = max(dot(n, l), 0.0);
    iDiff = clamp(iDiff, 0.0, 1.0);

    vec3 r = reflect(-l, n);
    vec3 c = normalize(camPos - p);
    float iSpec = pow(max(dot(r, c), 0.0), shapeShininess);
    iSpec = clamp(iSpec, 0.0, 1.0);

    return shapeDiffuse * lightDiffuse * iDiff
        + shapeSpecular * lightSpecular * iSpec
        + ambientLight;
}

void main(void) {
    vec3 ro = camPos;
    vec3 rd = rayDirection();

    float t = 0.0;
    for (int i = 0; i < maxMarches; i++) {
        vec3 p = ro + rd * t;
        float d = scene(p);
        t += d;

        if (d < marchEpsilon) {
            vec3 s = getShading(p);
            gl_FragColor = vec4(s, 1.0);
            break;
        }
        
        if (t > drawDistance) {
            gl_FragColor = vec4(0.0);
            break;
        }
    }
}
