// Sphere signed distance function
float sphereSDF(vec3 p, float r) {
    return length(p) - r;
}

// Matrix that rotates a point around the x, y, and z axes in that order.
mat4 rotateXYZ(float x, float y, float z) {
    float sx = sin(x), cx = cos(x);
    float sy = sin(y), cy = cos(y);
    float sz = sin(z), cz = cos(z);
    return mat4(
        cy * cz, cy * sz, -sy, 0.0,
        cz * sx * sy - cx * sz, cx * cz + sx * sy * sz, cy * sx, 0.0,
        cx * cz * sy + sx * sz, -cz * sx + cx * sy * sz, cx * cy, 0.0,
        0.0, 0.0, 0.0, 1.0);
}
