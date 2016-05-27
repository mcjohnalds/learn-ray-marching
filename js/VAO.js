class VAO {
    /**************************************************************************
     * Public properties
     *
     * buffer (WebGLBuffer): Associated WebGL buffer object.
     * count (int): Number of vertices.
     * dimensions (int): Number of elements per vertex.
     *************************************************************************/

    constructor(gl, vertices) {
        console.assert(gl instanceof WebGLRenderingContext);
        console.assert(vertices instanceof Array);
        console.assert(vertices.length > 0);

        this.gl = gl;
        this.buffer = gl.createBuffer();
        this.count = vertices.length;
        this.dimensions = vertices[0].length;
        gl.bindBuffer(gl.ARRAY_BUFFER, this.buffer);
        var f32Array = new Float32Array(this.flattenMatrix(vertices));
        gl.bufferData(gl.ARRAY_BUFFER, f32Array, gl.STATIC_DRAW);
    }

    /**************************************************************************
     * Private methods
     *************************************************************************/

    flattenMatrix(vertices) {
        var vs = [];
        for (var i = 0; i < this.count; i++)
            for (var j = 0; j < this.dimensions; j++)
                vs.push(vertices[i][j]);
        return vs;
    }
}
