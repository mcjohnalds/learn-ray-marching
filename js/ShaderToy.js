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
        images = loadImages(imagePaths).done((images) => {
            textures = createTextures(imagePaths, images);
            drawLoop();
        });
    }

    var imagePaths = ["/img/perlin.png"];
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

    function createTexture(image) {
        var tex = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, tex);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_NEAREST);
        gl.generateMipmap(gl.TEXTURE_2D);
        return tex;
    }

    function createTextures(imagePaths, images) {
        var texs = {};
        for (var i = 0; i < imagePaths.length; i++) {
            var path = imagePaths[i];
            var name = path.split(/[\\/]/).pop(); // /img/a.png -> a.png
            texs[name] = createTexture(images[i]);
        }
        return texs;
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
        var names = ["resolution", "time", "perlin"];
        var uniforms = {};
        names.forEach(function(name) {
            uniforms[name] = gl.getUniformLocation(program, name);
        });
        return uniforms;
    }

    function updateUniforms() {
        gl.uniform2f(uniforms.resolution, width, height);
        gl.uniform1f(uniforms.time, Date.now() / 1000 - startTime);

        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, textures["perlin.png"]);
        gl.uniform1i(uniforms.perlin, 0);
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
