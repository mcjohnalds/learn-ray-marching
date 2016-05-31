precision mediump float;
uniform vec2 resolution;

// Multiply two complex numbers
vec2 complexMul(vec2 a, vec2 b) {
	return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

void main(void) {
    gl_FragColor = vec4(0., 0., 0., 1.);
    
    // We will find the values of c for which
    //     z(n+1) = z(n)^2 + c
    // converge, where z and c are complex numbers.

    vec2 c = gl_FragCoord.xy / resolution; // 0 <= c <= 1
    c.x = c.x * 3.5 - 2.5; // -2.5 <= c.x <= 1
    c.y = c.y * 2. - 1.; // -1 <= c.y <= 1

    vec2 z = vec2(0.);

    for (int i = 0; i < 1000; i++) {
        if (dot(z, z) >= 4.) // z is diverging
            gl_FragColor = vec4(0.);

        z = complexMul(z, z) + c;
    }
}
