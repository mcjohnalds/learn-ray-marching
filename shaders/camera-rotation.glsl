precision mediump float;
uniform vec2 resolution;
uniform float time;
const float pi = 3.1415926535897932384626433832795;
const float fov = 80.0;
const float drawDistance = 125.0;
const int maxMarches = 200;
const float marchEpsilon = 0.001;
const vec3 camPos = vec3(0.0, 0.0, 1.5);
const vec3 lightPos = vec3(1.0, 1.0, 1.0);
const vec3 lightColor = vec3(1.4);
const vec3 ambientLight = vec3(0.05);
const vec3 materialDiffuse = vec3(0.95, 0.2, 0.2);
const vec3 materialSpecular = vec3(0.7);
const float materialShininess = 16.0;

// Matrix that rotates a point around the x, y, and z axes in that order.
mat3 rotateXYZ(float x, float y, float z) {
    float sx = sin(x), cx = cos(x);
    float sy = sin(y), cy = cos(y);
    float sz = sin(z), cz = cos(z);
    return mat3(
        cy * cz, cy * sz, -sy,
        cz * sx * sy - cx * sz, cx * cz + sx * sy * sz, cy * sx,
        cx * cz * sy + sx * sz, -cz * sx + cx * sy * sz, cx * cy);
}

float sphereSDF(vec3 p, float radius) {
    return length(p) - radius;
}

float sceneSDF(vec3 p) {
    return sphereSDF(p, 0.5);
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
        sceneSDF(vec3(p.x + e, p.y, p.z)) - sceneSDF(vec3(p.x - e, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + e, p.z)) - sceneSDF(vec3(p.x, p.y - e, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z + e)) - sceneSDF(vec3(p.x, p.y, p.z - e))
    );
    return normalize(n);
}

vec3 getShading(vec3 p, vec3 n) {
    vec3 l = normalize(lightPos - p);
    float iDiff = max(dot(n, l), 0.0);
    iDiff = clamp(iDiff, 0.0, 1.0);

    vec3 r = reflect(-l, n);
    vec3 c = normalize(camPos - p);
    float iSpec = pow(max(dot(r, c), 0.0), materialShininess);
    iSpec = clamp(iSpec, 0.0, 1.0);

    return lightColor * (materialDiffuse * iDiff + materialSpecular * iSpec) +
        ambientLight;
}

void main(void) {
    mat3 cameraRot = rotateXYZ(0.0, 0.5 * sin(time), 0.0);
    vec3 ro = camPos;
    vec3 rd = cameraRot * rayDirection();

    float t = 0.0;
    for (int i = 0; i < maxMarches; i++) {
        vec3 p = ro + rd * t;
        float d = sceneSDF(p);
        t += d;

        if (d < marchEpsilon) {
            vec3 n = getNormal(p);
            vec3 s = getShading(p, n);
            gl_FragColor = vec4(s, 1.0);
            break;
        }
        
        if (t > drawDistance) {
            gl_FragColor = vec4(0.0);
            break;
        }
    }
}

