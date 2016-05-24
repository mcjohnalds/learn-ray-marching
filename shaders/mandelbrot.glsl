precision mediump float;
uniform vec2 resolution;

void main(void) {
    gl_FragColor = vec4(1.);
    vec2 c = gl_FragCoord.xy / resolution; // 0 <= c <= 1
    c.x = c.x * 3.5 - 2.5; // -2.5 <= c.x <= 1
    vec2 z = vec2(0.);
    for (int i = 0; i < 1000; i++) {
        if (dot(z, z) >= 4)
            gl_FragColor = vec4(vec3(0.), 1.);
        vec2 z = vec2(
                z.x * z.x - z.y * z.y + c.x,
                2 * z.x * z.y + c.y);
    }
}
