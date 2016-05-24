precision mediump float;
uniform vec2 resolution;

void main(void) {
    vec2 c = gl_FragCoord.xy / resolution; // 0 <= c <= 1
    c.x = c.x * 3.5 - 2.5; // -2.5 <= c.x <= 1
    c.y = c.y * 2. - 1.; // -1 <= c.y <= 1
    c.y = abs(c.y); // Mirror around x-axis
    vec2 z = vec2(0.);
    const int maxI = 10000;
    for (int i = 0; i < maxI; i++) {
        if (dot(z, z) >= 4.)
            break;
        z = vec2(z.x * z.x - z.y * z.y + c.x, 2. * z.x * z.y + c.y);
        gl_FragColor = vec4(z.x / 3., length(z) / 5., z.y / 4., 1.);
    }
}
