---
layout: chapter
title: Building Interesting Shapes
previous: RayMarchingOverview
next: Shading
---

### Different shapes

We have already seen the sphere distance function:

```glsl
float sdfSphere(vec3 p, float r) {
    return length(p) - r;
}
```

But with some intuition we can create other distance functions like a box:

```glsl
float dfBox(vec3 p, vec3 b) {
    return length(max(abs(p) - b, 0.));
}
```

You'll notice an inconsistency with the two above functions, `sdfSphere` is a
*signed* distance function, it returns negative values when you're inside of
it, while `dfBox` always returns positive values. The difference is important
as we will see later.

Cylinder:

```glsl
float sdfCylinder(vec3 p, vec3 c) {
    return length(p.xz - c.xy) - c.z;
}
```

Plane:

```glsl
// n must be normalized
float sdfPlane(vec3 p, vec4 n) {
    return dot(p, n.xyz) + n.w;
}
```

These distance functions and more are available from [Modeling with distance
functions][distfunctions]

### Translation, rotation, scaling

We can translate a shape by shifting the `p` value:

```glsl
// A sphere of radius 2 at (-1,1,0).
float sdfScene(vec3 p) {
    p -= vec3(-1., 1., 0.);
    return sdfSphere(p, 2.);
}
````

A shape can be rotated by transforming `p` with some simple trigonometry:

```glsl
// Rotate around the x axis (pitch).
vec3 rotateX(vec3 p, float a) {
    float c = cos(a);
    float s = sin(a);
    float y = c * p.y - s * p.z;
    float z = s * p.y + c * p.z;
    return vec3(p.x, y, z);
}

// Rotate around the y axis (yaw).
vec3 rotateY(vec3 p, float a) {
    float c = cos(a);
    float s = sin(a);
    float x = c * p.x + s * p.z;
    float z = -s * p.x + c * p.z;
    return vec3(x, p.y, z);
}

// Rotate around the z axis (roll).
vec3 rotateZ(vec3 p, float a) {
    float c = cos(a);
    float s = sin(a);
    float x = c * p.x - s * p.y;
    float y = s * p.x + c * p.y;
    return vec3(x, y, p.z);
}

// A box with dimensions (2,1,1) rotated 90 degrees.
float sdfScene(vec3 p) {
    p = rotateY(p, pi / 2.);
    return sdfBox(p, vec3(2., 1., 1.));
}
```

Finally, we can scale a shape:

```glsl
// A sphere with radius 2 at (0,0,0).
float sdfScene(vec3 p) {
    float scale = 2.;
    return sdfSphere(p / scale, 1.) * scale;
}
```

### Boolean operations

We can combine primitives into more interesting shapes by finding the union,
difference, or intersection of them. The most important operation is the union
operation, which lets you draw two shapes at once.

```glsl
// A box plus a sphere
float sdfScene(vec3 p) {
    float sphere = sdfSphere(p, 1.3);
    float box = sdfBox(p, vec3(1.));
    return min(sphere, box);
}
```

Subtraction and intersection operations can create more interesting shapes.

```glsl
// Subtract shape with distance d2 from the shape with distance d1.
float opS(float d1, float d2) {
    return max(d1, -d2);
}

// The shape that is the intersection of two shapes.
float opI(float d1, float d2) {
    return max(d1, d2);
}

float sdfScene(vec3 p) {
    vec3 p1 = p - vec3(-2., 0., 0.);
    float sphere = sdfSphere(p1, 1.3);
    float box = sdfBox(p1, vec3(1.));
    // A box with a hole in it
    float shape1 = opS(box, sphere);

    vec3 p1 = p - vec3(2., 0., 0.);
    float sphere = sdfSphere(p1, 1.3);
    float box = sdfBox(p1, vec3(1.));
    // A box with very smoothed edges
    float shape2 = opI(box, sphere);

    // Draw both shapes
    return min(shape1, shape2);
}
```

### Repetition

A neat feature of distance functions is that they can be infinitely replicated
with a [modulo operation][modulo], without adding much additional processing
cost.

```glsl
// A neverending plane of spheres.
float sdfScene(vec3 p) {
    float spacing = 2.;
    vec3 p.xy = mod(p.xy, spacing) - 0.5 * spacing;
    return sdfSphere(p, 1.);
}
```

### Weird stuff

TODO

[distfunctions]: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm "Modeling with distance functions"
[modulo]: https://en.wikipedia.org/wiki/Modulo_operation "Modulo operation"
