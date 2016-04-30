shaders.shadedSphere = `
precision mediump float;
uniform vec2 resolution;

float sphereSDF(vec3 p, float radius) {
    return length(p) - radius;
}

// Returns the normal at the point on the sphere closest to p
vec3 sphereNormal(vec3 p, float radius) {
    vec3 eps = vec3(0.002, 0.0, 0.0);
    return normalize(vec3(
       sphereSDF(p + eps.xyy, radius) - sphereSDF(p - eps.xyy, radius),
       sphereSDF(p + eps.yxy, radius) - sphereSDF(p - eps.yxy, radius),
       sphereSDF(p + eps.yyx, radius) - sphereSDF(p - eps.yyx, radius)));
}

// Computes pixel color given sphere surface normal, direction from surface to
// light, and direction to camera.
vec3 shade(in vec3 normal, in vec3 light, in vec3 camera) {
    // Ambient light (e.g sun) color
    vec3 ambientColor = vec3(0.0, 0.0, 0.0);

    // Sphere surface properties
    vec3 diffuseColor = vec3(0.95, 0.2, 0.2);
    vec3 specularColor = vec3(1.0, 1.0, 1.0);
    const float shininess = 30.0;

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
    float radius = 0.5;

    vec2 ndc = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 ro = vec3(0.0, 0.0, 1.0);
    vec3 rd = normalize(vec3(ndc, -1.0));
    vec3 color = vec3(0.8, 0.85, 0.95);

    float tmax = 125.0;
    float t = 0.0;

    for (int i = 0; i < 200; i++) {
        vec3 pos = ro + rd * t;
        float d = sphereSDF(pos, radius);
        if (d < 0.001 || t > tmax)
            break;
        t += d;
    }

    if (t < tmax) {
        vec3 pos = ro + rd * t;
        vec3 normal = sphereNormal(pos, radius);
        color = shade(normal, normalize(lightPos), ro);
    }

    gl_FragColor = vec4(color, 1.0);
}
`;
