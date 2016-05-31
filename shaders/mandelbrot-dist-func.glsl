precision mediump float;
uniform vec2 resolution;

// Multiply two complex numbers
vec2 complexMul(vec2 a, vec2 b) {
	return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

void main(void) {
    // We will find the values of c for which
    //     z(n+1) = z(n)^2 + c
    // converge, where z and c like complex numbers but with three dimensions.

    vec2 c = gl_FragCoord.xy / resolution; // 0 <= c <= 1
    c.x = c.x * 3.5 - 2.5; // -2.5 <= c.x <= 1
    c.y = c.y * 2. - 1.; // -1 <= c.y <= 1

    vec2 z = vec2(0.);

    vec2 dz = vec2(0.); // z'

    for (int i = 0; i < 300; i++) {
        // dz = 2*z*z'+1
        dz = 2. * complexMul(z, dz) + vec2(1., 0.);
        // z = z^2 + c
        z = complexMul(z, z) + c;

        if (dot(z, z) > 4.)
            break; // z diverged
    }
    // Now either z converged to its limit or it diverged

    // d is the distance of c from mandelbrot boundary
    //     d = 0.5 * |z| / |z'| * log|z|
    // where |z| is the complex modulus
    float d = 0.5 * sqrt(dot(z, z) / dot(dz, dz)) * log(length(z));

    float color = clamp(d * 600., 0., 1.);
    color = pow(color, 0.3); // Smooth edges

    gl_FragColor = vec4(0., 0., 0., 1. - color);
}
