shaders.minimalSphere = `
precision mediump float;
uniform vec2 resolution;
const float pi = 3.1415926535897932384626433832795;
const float fov = 90.0; // Field of view
const float drawDistance = 125.0; // Maximum distance to march per ray
const int maxMarches = 200; // Maximum marches to make per ray
const float marchEpsilon = 0.001; // Stop marching when we're this close
const vec3 camPos = vec3(0.0, 0.0, 1.0); // Camera position
const vec3 skyColor = vec3(0.8, 0.85, 0.95);
const vec3 sphereColor = vec3(0.95, 0.2, 0.2);

// Sphere signed distance function.
float sphereSDF(vec3 p, float radius) {
    return length(p) - radius;
}

// Compute world coordinates of the fragment on the image plane.
vec3 rayDirection() {
    // For simplicity, we won't bother transforming the camera direction, so
    // camera space is the same as world space
    vec2 ndc = gl_FragCoord.xy / resolution; // NDC space coords of fragment
    vec2 screen = 2.0 * ndc - 1.0; // Screen space
    float ar = resolution.x / resolution.y; // Aspect ratio
    float f = tan(fov / 2.0 * pi / 180.0);
    vec3 world = vec3(screen.x * ar * f, screen.y * f, -1); // World space
    return normalize(world);
}

void main(void) {
    vec3 ro = camPos; // Ray origin
    vec3 rd = rayDirection(); // Ray direction

    // Final fragment color
    vec3 color = skyColor;

    float t = 0.0;
    for (int i = 0; i < maxMarches; i++) {
        vec3 p = ro + rd * t;
        float d = sphereSDF(p, 0.5);
        if (d < marchEpsilon || t > drawDistance)
            break;
        t += d;
    }

    if (t < drawDistance)
        color = sphereColor;

    gl_FragColor = vec4(color, 1.0);
}
`;
