class ShaderCompileError {
    constructor(m) {this.message = m;}
}

class ShaderLinkError {
    constructor(m) {this.message = m;}
}

class ShaderProgram {
    /* new ShaderProgram({
     *     vertexShaderSource: "void main(void) {}",
     *     fragmentShaderSource: "void main(void) {}",
     *     uniforms: ["time", "resolution"],
     *     attributes: ["vertexPosition"],
     * });
     */
    constructor(settings) {
        this.gl = settings.gl;
        var gl = this.gl;
        this.attribCount = null;

        this.program = this.createProgram(settings.vertexShaderSource,
                                          settings.fragmentShaderSource);
        this.uniformLocations = this.getUniformLocations(settings.uniforms);
        this.attribLocations = this.getAttribLocations(settings.attributes);
    }

    /**************************************************************************
     * Public methods
     *************************************************************************/

    setAttrib(name, vao) {
        var gl = this.gl;
        var attrib = this.attribLocations[name];
        gl.bindBuffer(gl.ARRAY_BUFFER, vao.buffer);
        gl.vertexAttribPointer(attrib, vao.dimensions, gl.FLOAT, false, 0, 0);
        this.attribCount = vao.count;
    }

    setUniformFloat(name, value) {
        this.gl.uniform1f(this.uniformLocations[name], value);
    }

    setUniformVec2(name, x, y) {
        this.gl.uniform2f(this.uniformLocations[name], x, y);
    }

    setUniformInt(name, value) {
        this.gl.uniform1i(this.uniformLocations[name], value);
    }

    drawTriangleStrip() {
        console.assert(typeof this.attribCount === "number");
        this.gl.drawArrays(this.gl.TRIANGLE_STRIP, 0, this.attribCount);
    }

    /**************************************************************************
     * Private methods
     *************************************************************************/

    getUniformLocations(uniformNames) {
        var uls = {};
        uniformNames.forEach((name) => {
            uls[name] = this.gl.getUniformLocation(this.program, name);
        });
        return uls;
    }

    getAttribLocations(attribNames) {
        var als = {};
        attribNames.forEach((name) => {
            als[name] = this.gl.getAttribLocation(this.program, name);
            this.gl.enableVertexAttribArray(als[name]);
        });
        return als;
    }

    createShader(type, source) {
        var gl = this.gl;
        console.assert(
            type === gl.VERTEX_SHADER || type === gl.FRAGMENT_SHADER);
        console.assert(typeof source === "string");
        var shader = gl.createShader(type);
        gl.shaderSource(shader, source);
        gl.compileShader(shader);
        if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS))
            throw new ShaderCompileError(gl.getShaderInfoLog(shader));
        return shader;
    }

    createProgram(vShaderSource, fShaderSource) {
        var gl = this.gl;
        var vShader = this.createShader(gl.VERTEX_SHADER, vShaderSource);
        var fShader = this.createShader(gl.FRAGMENT_SHADER, fShaderSource);
        var p = gl.createProgram();
        gl.attachShader(p, vShader);
        gl.attachShader(p, fShader);
        gl.linkProgram(p);
        if (!gl.getProgramParameter(p, gl.LINK_STATUS))
            throw new ShaderLinkError();
        gl.detachShader(p, vShader);
        gl.detachShader(p, fShader);
        gl.useProgram(p);
        return p;
    }

    delete() {
        this.gl.deleteProgram(this.program);
    }
}
