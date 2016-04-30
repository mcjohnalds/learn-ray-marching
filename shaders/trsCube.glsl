shaders.trsCube = `
precision mediump float;
uniform vec2 resolution;
uniform float seconds;

float boxSDF(vec3 p) {
    float boxSize = 0.5;
    vec3 d = abs(p) - boxSize;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

vec3 rotateX(vec3 p, float a) {
    float c = cos(a);
    float s = sin(a);
    float y = c * p.y - s * p.z;
    float z = s * p.y + c * p.z;
    return vec3(p.x, y, z);
}

vec3 rotateY(vec3 p, float a) {
    float c = cos(a);
    float s = sin(a);
    float x = c * p.x + s * p.z;
    float z = -s * p.x + c * p.z;
    return vec3(x, p.y, z);
}

vec3 rotateZ(vec3 p, float a) {
    float c = cos(a);
    float s = sin(a);
    float x = c * p.x - s * p.y;
    float y = s * p.x + c * p.y;
    return vec3(x, y, p.z);
}

float trsBoxSDF(vec3 p) {
    // Translate
    p -= vec3(cos(seconds * 0.3) * 0.3, sin(seconds * 0.3) * 0.3, 0.0);

    // Rotate
    p = rotateY(p, seconds * 0.3);
    p = rotateX(p, seconds * 0.3);

    // Scale factor
    float s = 0.5;

    return boxSDF(p / s) * s;
}

// Returns the normal of the surface at the point on the box closest to p
vec3 normal(vec3 p) {
    vec3 eps = vec3(0.002, 0.0, 0.0);
    return normalize(vec3(
       trsBoxSDF(p + eps.xyy) - trsBoxSDF(p - eps.xyy),
       trsBoxSDF(p + eps.yxy) - trsBoxSDF(p - eps.yxy),
       trsBoxSDF(p + eps.yyx) - trsBoxSDF(p - eps.yyx)));
}

// Computes pixel color given sphere surface normal, direction from surface to
// light, and direction to camera.
vec3 shade(in vec3 normal, in vec3 light, in vec3 camera) {
    // Ambient light (e.g sun) color
    vec3 ambientColor = vec3(0.0, 0.0, 0.0);

    // Sphere surface properties
    vec3 diffuseColor = vec3(0.95, 0.2, 0.2);
    vec3 specularColor = vec3(1.0, 1.0, 1.0);
    const float shininess = 20.0;

    // Intensity of diffuse reflection from sphere
    float lambertian = max(dot(normal, light), 0.0);

    // Compute the intensity of specular reflection from sphere, but don't
    // bother if we know the surface isn't receiving any light
    float specular = 0.0;
    if (lambertian > 0.0) {
        // Phong
        vec3 reflection = normalize(2.0*(dot(normal, light)) * normal - light);
        float k = dot(reflection, camera); 
    	specular = pow(k, shininess);
    }
    return ambientColor + lambertian * diffuseColor + specular * specularColor;
}

void main(void) {
    vec3 lightPos = vec3(1.0, 1.0, 1.0);

    vec2 ndc = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 ro = vec3(0.0, 0.0, 1.0);
    vec3 rd = normalize(vec3(ndc, -1.0));
    vec3 color = vec3(0.8, 0.85, 0.95);

    float tmax = 125.0;
    float t = 0.0;

    for (int i = 0; i < 200; i++) {
        vec3 pos = ro + rd * t;
        float d = trsBoxSDF(pos);
        if (d < 0.001 || t > tmax)
            break;
        t += d;
    }

    if (t < tmax) {
        vec3 pos = ro + rd * t;
        vec3 normal = normal(pos);
        color = shade(normal, normalize(lightPos), ro);
    }

    gl_FragColor = vec4(color, 1.0);
}
`;
