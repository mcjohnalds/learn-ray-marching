precision mediump float;
uniform vec2 resolution;
const float pi = 3.1415926535897932384626433832795;
const float fov = 80.0;
const float drawDistance = 125.0;
const int maxMarches = 200;
const float marchEpsilon = 0.001;
const vec3 camPos = vec3(0.0, 0.0, 1.0); // Position of camera
const vec3 lightPos = vec3(1.0, 1.0, 1.0); // Position of light
const vec3 lightColor = vec3(1.0); // Light color and intensity
const vec3 sphereDiffuse = vec3(0.95, 0.2, 0.2); // Diffuse color of sphere

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
    vec3 l = normalize(lightPos - p); // Vector from p to light
    float iDiff = max(dot(n, l), 0.0); // Intensity of diffuse light
    iDiff = clamp(iDiff, 0.0, 1.0);
    return lightColor * sphereDiffuse * iDiff;
}

void main(void) {
    vec3 ro = camPos;
    vec3 rd = rayDirection();

    float t = 0.0;
    for (int i = 0; i < maxMarches; i++) {
        vec3 p = ro + rd * t;
        float d = sceneSDF(p);
        t += d;

        if (d < marchEpsilon) {
            vec3 n = getNormal(p);
            gl_FragColor = vec4(getShading(p, n), 1.0);
            break;
        }
        
        if (t > drawDistance) {
            gl_FragColor = vec4(0.0);
            break;
        }
    }
}

