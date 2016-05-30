precision mediump float;
uniform vec2 resolution;
const float pi = 3.1415926535897932384626433832795;
const float fov = 60.0;
const float drawDistance = 125.0;
const int maxMarches = 200;
const float marchEpsilon = 0.001;
const vec3 eyePos = vec3(0., 0., 1.5);

float sdfSphere(vec3 p, float r) {
    return length(p) - r;
}

float scene(vec3 p) {
    return sdfSphere(p, 0.5);
}

// Direction of the ray we will march on.
vec3 rayDirection() {
    vec2 ndc = gl_FragCoord.xy / resolution;
    vec2 screen = 2.0 * ndc - 1.0;
    float ar = resolution.x / resolution.y;
    float f = tan(fov / 2.0 * pi / 180.0); // FOV factor
    vec3 world = vec3(screen.x * ar * f, screen.y * f, -1);
    return normalize(world);
}

// Compute surface normal using central differences method.
vec3 normal(vec3 p) {
    vec2 eps = vec2(0.001, 0.);
    vec3 n = vec3(
            scene(p + eps.xyy) - scene(p - eps.xyy),
            scene(p + eps.yxy) - scene(p - eps.yxy),
            scene(p + eps.yyx) - scene(p - eps.yyx));
    return normalize(n);
}

float diffuse(vec3 p, vec3 n, vec3 lightPos) {
    vec3 l = normalize(lightPos - p);
    float iDiff = max(dot(n, l), 0.);
    return clamp(iDiff, 0., 1.);
}

float specular(vec3 p, vec3 n, float shininess, vec3 viewPos, vec3 lightPos) {
    vec3 l = normalize(lightPos - p);
    vec3 r = reflect(-l, n);
    vec3 c = normalize(viewPos - p);
    float iSpec = pow(max(dot(r, c), 0.), shininess);
    return clamp(iSpec, 0., 1.);
}

vec3 shading(vec3 p, vec3 n) {
    vec3 lightPos = vec3(0.5, 0.5, 1.5);
    vec3 materialColor = vec3(1., 0.6, 0.7);
    
    float iDiff = diffuse(p, n, lightPos);
    float iAmb = 0.05; // Constant ambient light
    
    vec3 color = materialColor * (iDiff + iAmb); // Diffuse and ambient light
    
    // Specular highlights
    float iSpec = specular(p, n, 5., eyePos, lightPos);
    // Multiplying by 1-color smooths things out
    color += (1. - color) * iSpec;
    
    return color;
}

void main() {
    vec3 ro = eyePos;
    vec3 rd = rayDirection();

    float t = 0.0;
    for (int i = 0; i < maxMarches; i++) {
        vec3 p = ro + rd * t;
        float d = scene(p);
        t += d;

        if (d < marchEpsilon) {
            vec3 n = normal(p);
            vec3 s = shading(p, n);
            gl_FragColor = vec4(s, 1.0);
            break;
        }
        
        if (t > drawDistance) {
            gl_FragColor = vec4(0.);
            break;
        }
    }
}
