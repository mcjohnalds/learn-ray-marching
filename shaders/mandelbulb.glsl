precision mediump float;
uniform vec2 resolution;
const float pi = 3.1415926535897932384626433832795;
const vec3 camPos = vec3(0., 0., 2.);
const float fov = 60.;
const int maxMarches = 100000;
const float marchEpsilon = 0.0001;
const float drawDistance = 10.;

float distFunc(vec3 pos) {
    const float power = 8.;
    const float bailout = 5.;
    const int iterations = 50;

	vec3 z = pos;
	float r;
	float dr = 1.0;
    for (int i = 0; i < iterations; i++) {
		r = length(z);
        if (r > bailout) break;

        // Convert (z.x,z.y,z.z) to polar coords
        float theta = acos(z.z / r);
        float phi = atan(z.y, z.x);

        dr =  pow(r, power - 1.) * power * dr + 1.;

        // Find the spherical coords of z for z=z^power
        float zr = pow(r, power);
        theta = theta * power;
        phi = phi * power;

        // Convert (zr,theta,phi) to Cartesian coords
        z = zr * vec3(
                sin(theta) * cos(phi),
                sin(phi) * sin(theta),
                cos(theta));

        // This is the c value in z=z^p+c
        z += pos;
    }

    // Magic distance estimation formula
    return 0.5 * log(r) * r / dr;
}

vec3 rayDirection() {
    vec2 ndc = gl_FragCoord.xy / resolution; // 0 <= ndc <= 1
    vec2 screen = 2. * ndc - 1.; // -1 <= screen <= 1
    float ar = resolution.x / resolution.y; // aspect ratio
    float f = tan(fov / 2. * pi / 180.); // field of view factor
    vec3 world = vec3(screen.x * ar * f, screen.y * f, -1);
    return normalize(world);
}

vec3 normal(vec3 p) {
    vec2 eps = vec2(0.0001, 0.);
    vec3 n = vec3(
            distFunc(p + eps.xyy) - distFunc(p - eps.xyy),
            distFunc(p + eps.yxy) - distFunc(p - eps.yxy),
            distFunc(p + eps.yyx) - distFunc(p - eps.yyx));
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
    float diff = diffuse(p, n, camPos);
    float spec = specular(p, n, 100., camPos, camPos);
    return vec3(diff * 0.9 + spec * 0.9 + 0.1);
}

void main(void) {
    gl_FragColor = vec4(0.2, 0.2, 0.7, 1.);

    vec3 ro = camPos;
    vec3 rd = rayDirection();

    float t = 0.;
    for (int i = 0; i < maxMarches; i++) {
        vec3 p = ro + rd * t;
        float d = distFunc(p);
        t += d;

        if (d < marchEpsilon) {
            vec3 n = normal(p);
            vec3 s = shading(p, n);
            gl_FragColor = vec4(s, 1.);
            break;
        }

        if (t > drawDistance)
            break;
    }
}
