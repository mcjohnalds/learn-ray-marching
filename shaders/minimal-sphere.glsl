precision mediump float;
uniform vec2 resolution;
const float pi = 3.1415926535897932384626433832795;
const float fov = 80.0; // Field of view
const float drawDistance = 125.0; // Maximum distance to march per ray
const int maxMarches = 200; // Maximum marches to make per ray
const float marchEpsilon = 0.001; // Stop marching when we're this close
const vec3 camPos = vec3(0.0, 0.0, 1.0); // Camera position

// Sphere signed distance function.
float sphereSDF(vec3 p, float radius) {
    return length(p) - radius;
}

// Compute direction of our ray.
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

    // March along the ray
    float t = 0.0;
    for (int i = 0; i < maxMarches; i++) {
        vec3 p = ro + rd * t; // Our current position along the ray
        float d = sphereSDF(p, 0.5);
        t += d;

        if (d < marchEpsilon) {
            // The ray hit the sphere
            gl_FragColor = vec4(0.95, 0.2, 0.2, 1.0);
            break;
        }
        
        if (t > drawDistance) {
            // The ray didn't hit the sphere
            gl_FragColor = vec4(0.0);
            break;
        }
    }
}
