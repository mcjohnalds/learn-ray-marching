class WebGLContextError {
    constructor() {
        this.message = "Couldn't get WebGL context, make sure you're using " +
                       "Firefox or Chrome";
    }
}

class ShaderCompileError {
    constructor(m) {this.message = m;}
}

class ShaderLinkError {
    constructor(m) {this.message = m;}
}

var ShaderToy = (function() {
    function O(canvas) {
        gl = getWebGLContext(canvas);
        width = canvas.width;
        height = canvas.height;
        startTime = Date.now() / 1000;
        positionBuffer = createPositionBuffer();
        drawLoop();
    }

    var gl;
    var width;
    var height;
    var startTime;
    var positionBuffer;
    var uniforms;
    var program;
    var playing = false;
    var ready = false;

    function getWebGLContext(canvas) {
        try {
            return canvas.getContext("experimental-webgl");
        } catch (e) {
            throw new WebGLContextError("Couldn't get WebGL context");
        }
    }

    function createPositionBuffer() {
        var buffer = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
        var vertices = [
             1.0,  1.0,
            -1.0,  1.0,
             1.0, -1.0,
            -1.0, -1.0,
        ];
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);
        return buffer;
    }

    function createShader(type, source) {
        console.assert(type === gl.VERTEX_SHADER || type === gl.FRAGMENT_SHADER);
        console.assert(typeof source === "string");
        var shader = gl.createShader(type);
        gl.shaderSource(shader, source);
        gl.compileShader(shader);
        if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
            throw new ShaderCompileError(gl.getShaderInfoLog(shader));
        }
        return shader;
    }

    function createProgram(vShader, fShader) {
        var p = gl.createProgram();
        gl.attachShader(p, vShader);
        gl.attachShader(p, fShader);
        gl.linkProgram(p);
        if (!gl.getProgramParameter(p, gl.LINK_STATUS)) {
            throw new ShaderLinkError();
        }
        gl.useProgram(p);
        return p;
    }

    function updatePosAttribute() {
        var pos = gl.getAttribLocation(program, "pos");
        gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
        gl.enableVertexAttribArray(pos);
        gl.vertexAttribPointer(pos, 2, gl.FLOAT, false, 0, 0);
    }

    function getUniforms() {
        var names = ["resolution", "time"];
        var uniforms = {};
        names.forEach(function(name) {
            uniforms[name] = gl.getUniformLocation(program, name);
        });
        return uniforms;
    }

    function updateUniforms() {
        gl.uniform2f(uniforms.resolution, width, height);
        gl.uniform1f(uniforms.time, Date.now() / 1000 - startTime);
    }

    function drawLoop() {
        window.requestAnimationFrame(drawLoop.bind(this));
        if (ready && playing)
            draw();
    }

    function draw() {
        gl.clear(gl.COLOR_BUFFER_BIT);
        gl.viewport(0, 0, width, height);
        updateUniforms();
        gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
    }

    O.prototype.pause = function() {
        playing = false;
    };

    O.prototype.play = function() {
        playing = true;
    };

    O.prototype.setResolution = function(w, h) {
        width = w;
        height = h;
        if (!playing && ready)
            draw();
    };

    O.prototype.load = function(vertexShaderSource, fragmentShaderSource) {
        if (program) gl.deleteProgram(program);
        var vShader = createShader(gl.VERTEX_SHADER, vertexShaderSource);
        var fShader = createShader(gl.FRAGMENT_SHADER, fragmentShaderSource);
        program = createProgram(vShader, fShader);
        gl.detachShader(program, vShader);
        gl.detachShader(program, fShader);
        updatePosAttribute();
        uniforms = getUniforms();
        ready = true;
        if (!playing)
            draw();
    }

    return O;
})();
