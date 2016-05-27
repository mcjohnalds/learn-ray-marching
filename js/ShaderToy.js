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

class ShaderToy {
    constructor(canvas) {
        this.imagePaths = ["/img/perlin.png"];
        this.uniformNames = ["resolution", "time", "cursor", "perlin"];
        this.playing = false;
        this.ready = false;
        this.cursorX = 0.0;
        this.cursorY = 0.0;
        this.canvas = canvas;
        this.gl = this.getWebGLContext();
        this.width = canvas.width;
        this.height = canvas.height;
        this.startTime = Date.now() / 1000;
        this.positionBuffer = this.createPositionBuffer();
        this.program = null;

        loadImages(this.imagePaths).done((images) => {
            this.textures = this.createTextures(images);
            this.drawLoop();
        });

        detectMouseDown(canvas, this.updateCursorXY.bind(this));
        detectMouseDrag(canvas, this.updateCursorXY.bind(this));
    }

    /*************************************************************************
     * Public methods
     *************************************************************************/

    pause() {
        this.playing = false;
    }

    play() {
        this.playing = true;
    }

    setResolution(w, h) {
        this.width = w;
        this.height = h;
        if (!this.playing && this.ready)
            this.draw();
    }

    load(vertexShaderSource, fragmentShaderSource) {
        var gl = this.gl;
        if (this.program) gl.deleteProgram(this.program);
        var vShader = this.createShader(gl.VERTEX_SHADER, vertexShaderSource);
        var fShader = this.createShader(gl.FRAGMENT_SHADER, fragmentShaderSource);
        this.program = this.createProgram(vShader, fShader);
        gl.detachShader(this.program, vShader);
        gl.detachShader(this.program, fShader);
        this.updatePosAttribute();
        this.uniforms = this.getUniforms();
        this.ready = true;
        if (!this.playing)
            this.draw();
    }

    /*************************************************************************
     * Private methods
     *************************************************************************/

    updateCursorXY(x, y) {
        var zoom = this.width / $(this.canvas).width();
        this.cursorX = zoom * x / this.width;
        this.cursorY = 1 - zoom * y / this.height;
        this.draw();
    }

    getWebGLContext() {
        try {
            return this.canvas.getContext("experimental-webgl");
        } catch (e) {
            throw new WebGLContextError("Couldn't get WebGL context");
        }
    }

    createPositionBuffer() {
        var gl = this.gl;
        var buffer = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
        var vertices = [
             1.0,  1.0,
            -1.0,  1.0,
             1.0, -1.0,
            -1.0, -1.0,
        ];
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices),
                      gl.STATIC_DRAW);
        return buffer;
    }

    createTexture(image) {
        var gl = this.gl;
        var tex = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, tex);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE,
                      image);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER,
                         gl.LINEAR_MIPMAP_NEAREST);
        gl.generateMipmap(gl.TEXTURE_2D);
        return tex;
    }

    createTextures(images) {
        var texs = {};
        for (var i = 0; i < this.imagePaths.length; i++) {
            var path = this.imagePaths[i];
            var name = path.split(/[\\/]/).pop(); // /img/a.png -> a.png
            texs[name] = this.createTexture(images[i]);
        }
        return texs;
    }

    createShader(type, source) {
        var gl = this.gl;
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

    createProgram(vShader, fShader) {
        var gl = this.gl;
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

    updatePosAttribute() {
        var gl = this.gl;
        var pos = gl.getAttribLocation(this.program, "pos");
        gl.bindBuffer(gl.ARRAY_BUFFER, this.positionBuffer);
        gl.enableVertexAttribArray(pos);
        gl.vertexAttribPointer(pos, 2, gl.FLOAT, false, 0, 0);
    }

    getUniforms() {
        var gl = this.gl;
        var uniforms = {};
        this.uniformNames.forEach((name) => {
            uniforms[name] = gl.getUniformLocation(this.program, name);
        });
        return uniforms;
    }

    updateUniforms() {
        var gl = this.gl;
        gl.uniform2f(this.uniforms.resolution, this.width, this.height);
        gl.uniform1f(this.uniforms.time, Date.now() / 1000 - this.startTime);
        gl.uniform2f(this.uniforms.cursor, this.cursorX, this.cursorY);

        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, this.textures["perlin.png"]);
        gl.uniform1i(this.uniforms.perlin, 0);
    }

    drawLoop() {
        window.requestAnimationFrame(this.drawLoop.bind(this));
        if (this.ready && this.playing)
            this.draw();
    }

    draw() {
        var gl = this.gl;
        gl.clear(gl.COLOR_BUFFER_BIT);
        gl.viewport(0, 0, this.width, this.height);
        this.updateUniforms();
        gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
    }
}
