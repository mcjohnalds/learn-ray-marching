function ShaderDemo(canvas) {
    this._canvas = canvas;
    var gl = this._gl = this._getWebGLContext();
    var vertexShader = this._createShader("vertex", gl.VERTEX_SHADER);
    var shaderName = canvas.dataset.shader;
    var fragmentShader = this._createShader(shaderName, gl.FRAGMENT_SHADER);
    this._shaderProgram = this._createShaderProgram(vertexShader, fragmentShader);
    this._positionBuffer = this._createPositionBuffer();
    this._initVertexPositionAttribute();
    this._startTime = Date.now() / 1000;
    this._uniforms = this._initUniforms();
    this._drawScene();
}

ShaderDemo.prototype._getWebGLContext = function() {
    var gl;
    try {
        gl = this._canvas.getContext("experimental-webgl");
    } catch (e) {
    }
    if (!gl) {
        console.log("Couldn't initialize WebGL.");
    }
    return gl;
}

ShaderDemo.prototype._createShader = function(shaderScriptName, shaderType) {
    var gl = this._gl;

    var shader = gl.createShader(shaderType);
    gl.shaderSource(shader, shaders[shaderScriptName]);
    gl.compileShader(shader);

    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        console.log(gl.getShaderInfoLog(shader));
        return null;
    }

    return shader;
}

ShaderDemo.prototype._createShaderProgram = function(vertexShader, fragmentShader) {
    var gl = this._gl;

    var shaderProgram = gl.createProgram();
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    gl.linkProgram(shaderProgram);

    if (!gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)) {
        console.log("Could not initialise shaders");
    }

    gl.useProgram(shaderProgram);

    return shaderProgram;
}

ShaderDemo.prototype._initVertexPositionAttribute = function() {
    var gl = this._gl;
    var vertexPositionAttribute =
            gl.getAttribLocation(this._shaderProgram, "vertexPosition");

    // The vertex attribute will stay constant so we only set it once here
    gl.bindBuffer(gl.ARRAY_BUFFER, this._positionBuffer);
    gl.enableVertexAttribArray(vertexPositionAttribute);
    gl.vertexAttribPointer(
            this._vertexPositionAttribute, // Vertex attribute
            this._positionBuffer.itemSize, // Vertex dimensions
            gl.FLOAT,                      // Vertex data type
            false,                         // Don't normalize
            0,                             // Vertices packed tightly
            0);                            // First vertex at index 0
}

ShaderDemo.prototype._initUniforms = function() {
    var gl = this._gl;
    var shaderProgram = this._shaderProgram;
    var uniformNames = ["resolution", "seconds"];
    var uniforms = {};
    uniformNames.forEach(function(name) {
        uniforms[name] = gl.getUniformLocation(shaderProgram, name);
    });
    return uniforms;
}

ShaderDemo.prototype._createPositionBuffer = function() {
    var gl = this._gl;

    var positionBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
    var vertices = [
         1.0,  1.0,
        -1.0,  1.0,
         1.0, -1.0,
        -1.0, -1.0,
    ];
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);
    positionBuffer.itemSize = 2;
    positionBuffer.numItems = 4;
    return positionBuffer;
}

ShaderDemo.prototype._updateUniforms = function() {
    var gl = this._gl;
    var u = this._uniforms;
    gl.uniform2f(u.resolution, this._canvas.width, this._canvas.height);
    gl.uniform1f(u.seconds, Date.now() / 1000 - this._startTime);
}

ShaderDemo.prototype._drawScene = function(shaderProgram, positionBuffer) {
    var gl = this._gl;
    gl.clearColor(0, 0, 0, 1);
    var width = this._canvas.width;
    var height = this._canvas.height;
    gl.viewport(0, 0, width, height);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    this._updateUniforms();
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, this._positionBuffer.numItems);
    window.requestAnimationFrame(this._drawScene.bind(this));
}
