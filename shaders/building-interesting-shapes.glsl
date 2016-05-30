precision mediump float;
uniform vec2 resolution;
const float pi = 3.1415926535897932384626433832795;
const float fov = 60.0;
const float drawDistance = 100.0;
const int maxMarches = 2000;
const float marchEpsilon = 0.0001;
const vec3 eyePos = vec3(0., 10., 11.);
const float fudgeFactor = 5.; // Divide the step distance by this much

float sdfSphere(vec3 p, float r) {
    return length(p) - r;
}

float dfBox(vec3 p, vec3 size) {
    return length(max(abs(p) - size / 2., 0.));
}

float sdfCylinder(vec3 p, float radius, float height) {
    vec2 h = vec2(radius, height / 2.);
    vec2 d = abs(vec2(length(p.yz), p.x)) - h;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// n must be normalized
float sdfPlane(vec3 p, vec4 n) {
    return dot(p, n.xyz) + n.w;
}

// Rotate around the x axis (pitch).
vec3 rotateX(vec3 p, float a) {
    float c = cos(a);
    float s = sin(a);
    float y = c * p.y - s * p.z;
    float z = s * p.y + c * p.z;
    return vec3(p.x, y, z);
}

// Rotate around the y axis (yaw).
vec3 rotateY(vec3 p, float a) {
    float c = cos(a);
    float s = sin(a);
    float x = c * p.x + s * p.z;
    float z = -s * p.x + c * p.z;
    return vec3(x, p.y, z);
}

// Rotate around the z axis (roll).
vec3 rotateZ(vec3 p, float a) {
    float c = cos(a);
    float s = sin(a);
    float x = c * p.x - s * p.y;
    float y = s * p.x + c * p.y;
    return vec3(x, y, p.z);
}

// Subtract shape with distance d2 from the shape with distance d1.
float opS(float d1, float d2) {
    return max(d1, -d2);
}

// The shape that is the intersection of two shapes.
float opI(float d1, float d2) {
    return max(d1, d2);
}

float ground(vec3 p) {
    return sdfPlane(p, vec4(0., 1., 0., 0.));
}

float cubePlusSphere(vec3 p) {
    float d = dfBox(p, vec3(4.0));
    d = min(d, sdfSphere(p, 2.5));
    return d;
}

float cubeInsideCarved(vec3 p) {
    float d = dfBox(p, vec3(4.0));
    d = opS(d, sdfSphere(p, 2.5));
    return d;
}

float cubeOutsideCarved(vec3 p) {
    float d = dfBox(p, vec3(4.));
    d = opI(d, sdfSphere(p, 2.5));
    return d;
}

float cylinder(vec3 p) {
    p = rotateZ(p, pi / 2.);
    float d = sdfCylinder(p, 2., 3.);
    d += 0.2 * sin(p.x * 3.) * sin(p.y * 3.) * sin(p.z * 3.);
    return d;
}

float parallelogram(vec3 p) {
    p.x -= p.y * 0.4;
    return dfBox(p, vec3(3.));
}

vec3 twist(vec3 p) {
    float c = cos(2. * p.y);
    float s = sin(2. * p.y);
    mat2 m = mat2(c, -s, s, c);
    return vec3(m * p.xz, p.y);
}

float twistie(vec3 p) {
    p = rotateZ(p, pi / 2.);
    p.xz *= 2.4; // Shrink
    p = rotateY(p, pi / 2.);
    p = twist(p);
    float d = sdfCylinder(p, 3., 0.3);
    return d;
}

float repeating(vec3 p) {
    float c = 7.;
    p.xy = mod(p.xy, c) - 0.5 * c;
    return sdfSphere(p, 7.);
}

float scene(vec3 p) {
    float d = ground(p);
    d = min(d, cubePlusSphere(p - vec3(-7., 2., -7.)));
    d = min(d, cubeInsideCarved(p - vec3(0., 2., -7.)));
    d = min(d, cubeOutsideCarved(p - vec3(7, 2., -7.)));
    d = min(d, cylinder(p - vec3(-7., 1.5, 0.)));
    d = min(d, parallelogram(p - vec3(0., 1.5, 0.)));
    d = min(d, twistie(p - vec3(7., 1.5, 0.)));
    d = min(d, repeating(p - vec3(0., 0., -45.)));
    return d;
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
    vec2 eps = vec2(0.0001, 0.);
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
    vec3 sunLightPos = eyePos + 1.; // Spot light
    vec3 sunLightColor = vec3(0.5);
    vec3 skyLightPos = p + vec3(0., 1., 0.); // Light coming from atmosphere
    vec3 skyLightColor = vec3(0.75, 0.75, 0.8);
    
    float shininess = 5.;
    vec3 materialColor = vec3(0.8, 0.6, 0.7); // #CB99CC
    if (p.y < marchEpsilon) // Give the ground a different color
        materialColor = vec3(0.8, 0.7, 0.6); // #CCB299
    else if (p.z < -10.) // Give the wall a different color
        materialColor = vec3(0.6, 0.7, 0.8);
    
    vec3 iDiff = sunLightColor * diffuse(p, n, sunLightPos); 
    iDiff += skyLightColor * diffuse(p, n, skyLightPos); 
    float iAmb = 0.05; // Constant ambient light
    vec3 color = materialColor * (iDiff + iAmb); // Diffuse and ambient light
    
    // Specular highlights
    
    if (p.y >= marchEpsilon) { // Don't give the ground a specular highlight
        vec3 iSpec = sunLightColor * specular(p, n, shininess, eyePos, sunLightPos);
        iSpec += skyLightColor * specular(p, n, shininess, eyePos, skyLightPos);
        // Multiplying by 1-color smooths things out
        color += (1. - color) * iSpec;
    }
    
    return color;
}

void main() {
    vec3 ro = eyePos;
    vec3 rd = rotateX(rayDirection(), -0.5);

    float t = 0.0;
    for (int i = 0; i < maxMarches; i++) {
        vec3 p = ro + rd * t;
        float d = scene(p);
        t += d / fudgeFactor;

        if (d < marchEpsilon) {
            vec3 n = normal(p);
            vec3 s = shading(p, n);
            gl_FragColor = vec4(s, 1.0);
            break;
        }
        
        if (t > drawDistance) {
            gl_FragColor = vec4(0.7, 0.85, 0.9, 1.);
            break;
        }
    }
}
