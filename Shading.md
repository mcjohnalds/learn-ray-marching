---
layout: chapter
title: Shading
previous: BuildingInterestingShapes
next: TerrainMarching
---

### Phong shading

As we have already seen, the illumination at a point on a surface can be
computed using

$$
    I_{\text{p}} = k_{\text{a}}i_{\text{a}} +
        \sum_{m\;\in \;{\text{lights}}}
            (k_{\text{d}}({\hat {L}}_{m}\cdot {\hat {N}})i_{m,{\text{d}}} +
            k_{\text{s}}({\hat {R}}_{m}\cdot {\hat {V}})^{\alpha }i_{m,{\text{s}}}).
$$

with parameters

- $\alpha$: Shininess, how shiny the surface is (lower value means shinier)
- $k_d$: Diffuse reflection constant, how bright light hitting the surface is
- $k_s$: Specular reflection constant, how bright the shiny bits are
- $k_a$: How much ambient light is there (light bouncing around everywhere)
- $\text{lights}$: The set of all lights
- $\hat{L}_m$: Direction from point on surface to light source $m$
- $\hat{N}$: Normal at the point on the surface (from the `getNormal` function)
- $\hat{R}_m$: Direction a ray of light would take if it came from light source
  $m$ and bounced off the surface. This can be computed in GLSL with
  $\text{reflect}(-\hat{L}_m,\hat{N})$
- $\hat{V}$: Direction from the surface to the viewer

### Ambient occlusion

In real life, light bounces around everywhere in a scene, not just on the parts
directly visible to a light source. To make a scene look accurate, we should be
darkening parts of each shape that wouldn't recieve as much light. Normally
this would be very expensive to compute, but we can get a convincing
approximation for free by simply lighting each point on a surface by how many
steps it took the ray marcher to reach it. The more steps it takes to reach a
surface, the darker it should be. We can write a ray marching algorithm that
has this feature.

```glsl
void main() {
    gl_FragColor = (0, 0, 0, 1); // Start with a background color

    vec3 PWorld = ...; // Point of pixel in world space
    vec3 rd = normalize(PWorld); // The ray direction
    float t = 0; // How far we've travelled along the ray

    for (int i = 0; i < 1000; i++) {
        vec3 p = rd * t; // The point along the ray we are at
        float d = sdfScene(p); // The distance from p to a sphere
        t += d; // Move forward along the ray

        if (d < 0.001) { // If p is very close the boundary of the sphere
            // Occlusion factor, 0 = completely exposed to incoming light,
            // 1 = totally obscured from incoming light. Here we scale by an
            // arbitrary factor of 0.005.
            float occlusion = clamp(float(i) * 0.005, 0., 1.);
            // Compute the lighting, shadows, etc
            gl_FragColor = computeShadingForPoint(p) * (1. - occlusion);
            break;
        }

        if (t > 100) // If the ray missed the shape and went off to infinity
            break;
    }
}
```

### Shadows

Shadows can be implemented in the light shading part of your code by using our
ray marching algorithm to march from the point on the surface being shaded in
the direction of the light source. If ray marcher collided with another surface
at any point, that light source doesn't contribute any light. For example:

```glsl
// Return 1 if the surface is in view of the light source, otherwise return 0.
// ro: Ray origin
// rd: Ray direction
// distFromLight: How far the surface is (ro) from the light source
float shadow(vec3 ro, vec3 rd, float distFromLight) {
    float t = 0.0001; // How far we've travelled along the ray
    // We start a little bit in front of the surface so the algorithm doesn't
    // think we're colliding with it

    for (int i = 0; i < 1000; i++) {
        vec3 p = ro + rd * t;
        float d = sdfScene(p);
        t += d;

        if (d < 0.001) // If the shadow ray hit a surface
            return 0.;
    }
    return 1.; // The shadow made a line straight to the light source
}

vec3 computeShadingForPoint(vec3 p) {
    // For simplicity we assume there is only one light source located at
    // (1,1,0)
    vec3 lightPosition = vec(1., 1., 0.);
    float diff = ... // Compute diffuse lighting
    float spec = ... // Compute specular lighting
    vec3 vecFromPToLight = lightPosition - p;
    float sh = shadow(p, normalize(vecFromPToLight), length(vecFromPToLight);
    return vec3(0.7, 0.2, 0.2) * diff * spec * sh;
}
```

Unfortunately, this gives our shadows a hard edge. We can fix this in our
`shadow` function by making the shadow lighter or darker depending on how close
our shadow ray came to hitting a surface.

```glsl
// k: Penumbra factor. Lower values = smoother shadows.
float shadow(vec3 ro, vec3 rd, float distFromLight, float k) {
    float t = 0.0001; // How far we've travelled along the ray
    // We start a little bit in front of the surface so the algorithm doesn't
    // think we're colliding with it

    // Start by assume our shadow ray didn't even come close to hitting another
    // surface
    float res = 1.; 

    for (int i = 0; i < 1000; i++) {
        vec3 p = ro + rd * t;
        float d = sdfScene(p);
        t += d;

        if (d < 0.001) // If the shadow ray hit a surface
            return 0.;

        // Shadow factor, d tells us how close we can to hitting a surface
        float sh = k * d / t;
        // res will be the minimal value sh takes
        res = min(res, sh);
    }

    // We reach this point if the shadow ray didn't hit any surface on the way
    // to the light source, but it may still have gotten very close to doing so
    return res;
}
```

### Putting it all together
