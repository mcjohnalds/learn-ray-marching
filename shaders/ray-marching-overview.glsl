precision mediump float;
uniform float time;

void main() {
    gl_FragColor = vec4(2. * sin(time) - 1., 0.6, 0.6, 1.);
}
