class WebGLContextError {
    constructor() {
        this.message = "Couldn't get WebGL context, make sure you're using " +
                       "Firefox or Chrome";
    }
}

class ShaderToy {
    constructor(canvas) {
        this.vertexShaderSource = "attribute vec2 pos;void main(void){gl_Position=vec4(pos,0.,1.);}";
        this.imagePaths = ["img/perlin.png"];
        this.playing = false;
        this.ready = false;
        this.cursorX = 0.5;
        this.cursorY = 0.5;
        this.program = null;

        this.canvas = canvas;
        this.gl = this.getWebGLContext();
        this.width = canvas.width;
        this.height = canvas.height;

        this.reset();
        this.setResolutionRatio(1);

        this.imagesFinishedLoading = false;
        this.imagesLoading = loadImages(this.imagePaths).done((images) => {
            this.textures = this.createTextures(images);
            this.drawLoop();
            this.imagesFinishedLoading = true;
        });

        this.positionVAO = new VAO(this.gl, [
            [ 1.0,  1.0],
            [-1.0,  1.0],
            [ 1.0, -1.0],
            [-1.0, -1.0],
        ]);

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

    reset() {
        this.cursorX = 0.5;
        this.cursorY = 0.5;
        this.startTime = Date.now() / 1000;
    }

    setResolutionRatio(ratio) {
        var width = $(this.canvas).width() * ratio;
        var height = $(this.canvas).height() * ratio;
        this.canvas.width = width;
        this.canvas.height = height;
        this.width = width;
        this.height = height;
        if (!this.playing && this.ready)
            this.draw();
    }

    load(fragmentShaderSource) {
        var loadShader = () => {
            var gl = this.gl;
            this.reset();
            if (this.program !== null) this.program.delete();
            this.program = new ShaderProgram({
                gl: gl,
                vertexShaderSource: this.vertexShaderSource,
                fragmentShaderSource: fragmentShaderSource,
                uniforms: ["resolution", "time", "cursor", "perlin"],
                attributes: ["pos"],
            });
            this.program.setAttrib("pos", this.positionVAO);
            this.ready = true;
            if (!this.playing)
                this.draw();
        };

        if (this.imagesFinishedLoading)
            loadShader();
        else
            this.imagesLoading.done(loadShader);
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

    updateUniforms() {
        var gl = this.gl;
        var p = this.program;
        p.setUniformVec2("resolution", this.width, this.height);
        p.setUniformFloat("time", Date.now() / 1000 - this.startTime);
        p.setUniformVec2("cursor", this.cursorX, this.cursorY);

        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, this.textures["perlin.png"]);
        p.setUniformInt("perlin", 0);
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
        this.program.drawTriangleStrip();
    }
}
