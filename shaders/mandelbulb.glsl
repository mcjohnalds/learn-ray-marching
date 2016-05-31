precision mediump float;
uniform vec2 resolution;
uniform float time;
uniform vec2 cursor;
const float pi = 3.1415926535897932384626433832795;
const vec3 camPos = vec3(0., 0., 2.3);
const int maxMarches = 300;
const float drawDistance = 10.;
const float marchEpsilon = 0.001;

// 0 <= fudgeFactor <= 1. Lower values irons out artifacts
const float fudgeFactor = 0.9;

mat3 rotateXYZ(float x, float y, float z) {
    float sx = sin(x), cx = cos(x);
    float sy = sin(y), cy = cos(y);
    float sz = sin(z), cz = cos(z);
    return mat3(
        cy * cz, cy * sz, -sy,
        cz * sx * sy - cx * sz, cx * cz + sx * sy * sz, cy * sx,
        cx * cz * sy + sx * sz, -cz * sx + cx * sy * sz, cx * cy);
}

// Distance of pos to boundary of shape where shape is defined for all c
// where z(n+1)=z^k+c diverges.
float distFunc(vec3 pos) {
    const float k = 8.;
    const float bailout = 5.;
    const int iterations = 50;

    // Cursor rotation
    float pitch = cursor.y * 2. - 1.;
    float yaw = cursor.x * 2. - 1.;
    pos = rotateXYZ(pitch, -yaw, 0.) * pos;
    
    // Constant rotation
    pos = rotateXYZ(0.98, 0.5, 0.) * pos;

	vec3 z = pos;
	float r;
	float dr = 1.0;
    for (int i = 0; i < iterations; i++) {
		r = length(z);
        if (r > bailout) break;

        // Convert (z.x,z.y,z.z) to polar coords
        float theta = acos(z.z / r);
        float phi = atan(z.y, z.x);

        dr = k * pow(r, k - 1.) * dr + 1.;

        // Find the spherical coords of z for z=z^k
        float zr = pow(r, k);
        theta = theta * k;
        phi = phi * k;

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

vec3 rayDirection(float fov) {
    vec2 ndc = gl_FragCoord.xy / resolution; // 0 <= ndc <= 1
    vec2 screen = 2. * ndc - 1.; // -1 <= screen <= 1
    float ar = resolution.x / resolution.y; // aspect ratio
    float f = tan(fov / 2. * pi / 180.); // field of view factor
    vec3 world = vec3(screen.x * ar * f, screen.y * f, -1);
    return normalize(world);
}

// Compute surface normal using central differences method.
vec3 normal(vec3 p) {
    vec2 eps = vec2(0.0001, 0.);
    vec3 n = vec3(
            distFunc(p + eps.xyy) - distFunc(p - eps.xyy),
            distFunc(p + eps.yxy) - distFunc(p - eps.yxy),
            distFunc(p + eps.yyx) - distFunc(p - eps.yyx));
    return normalize(n);
}

void main(void) {
    gl_FragColor = vec4(0.);

    float scale = 1. / (pow(time, 1.5) * 0.1 + 1.);
    float fov = 60. * scale;
    float minT = marchEpsilon * scale;

    vec3 ro = camPos;
    vec3 rd = rayDirection(fov);

    float t = 0.;
    for (int i = 0; i < maxMarches; i++) {
        vec3 p = ro + rd * t;
        float d = distFunc(p);
        t += fudgeFactor * d;

        if (d < minT) {
            // 0 = no shadow, 1 = complete shadow
            float occlusion = clamp(float(i) * 0.008, 0., 1.);
            vec3 color = vec3(1.0, 0.7, 0.8) * (1. - occlusion);
            gl_FragColor = vec4(color, 1.);
            break;
        }

        if (t > drawDistance)
            break;
    }
}
