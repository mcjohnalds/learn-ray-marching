---
layout: chapter
title: Terrain Marching
previous: Shading
next: Fractals
---

There is another ray marching algorithm, suitable for rendering terrain. The
basic idea is that rather than a distance function, we have a function `f`
which takes x and z coordinates and spits out the height of the terrain at that
point, i.e, `y=terrain(x,z)`. For example:

```glsl
bool castRay(vec3 ro, vec3 rd, out float resT) {
    const float dt = 0.0001;
    for (float t = 0.; t <= 1000.; t += dt) {
        vec3 p = ro + rd * t;
        float h = terrain(p.x, p.z);
        if (p.y < h) {
            resT = t - 0.5 * dt;
            return true;
        }
    }
    return false;
}

void main() {
    gl_FragColor = (0, 0, 0, 1);

    vec3 PWorld = ...; // Point of pixel in world space
    vec3 rd = normalize(PWorld); // The ray direction
    vec3 ro = vec3(0.);

    float t;
    if (castRay(ro, rd, t)) {
        vec3 p = ro + rd * t;
        gl_FragColor = vec4(computeShadingForPoint(p), 1.);
    } else {
        gl_FragColor = vec4(0.8, 0.85, 9.); // Sky color
    }
}
```

We can improve on our `castRay` function in two ways:

- When setting `resT`, interpolate between the current `h` value and the
  previous `h` value.
- Increment `t` by larger and larger steps each iteration, since the further
  away `p` is from the viewer's eye, the less detail needed.

```glsl
bool castRay(vec3 ro, vec3 rd, out float resT) {
    float dt = 0.0001;
    float lastH = terrain(ro.x, ro.z);
    float lastY = ro.y;

    for (float t = 0.; t <= 1000.; t += dt) {
        vec3 p = ro + rd * t;
        float h = terrain(p.x, p.z);
        if (p.y < h) {
            // Interpolate between lastH and h
            resT = t - dt + dt * (lastH - lastY) / (p.y - lastY - h + lastH); 
            return true;
        }
        lastH = h;
        lastY = p.y;
        // Make dt proportional to t
        dt = 0.01 * t;
    }

    return false;
}
```

### Making interesting terrain

We can use Perlin noise to create a cloud like grayscale texture, I won't
explain the algorithm but here's an implementation:

```glsl
// Fractional browniam motion gives a cloud-like texture. p is the position on
// the texture (like a seed to a RNG). A higher octaves value gives a rough and
// more interesting texture.
float fbm(vec2 p, int octaves) {
    // Pre-computed rotation matrix. Helps avoid many parallel lines and 90 deg
    // intersections that would otherwise occur.
    mat2 m = mat2(0.80,  0.60, -0.60,  0.80);
    float f = 0.0;
    float c = 0.5;
    float sum = 0.0;
    // WebGL doesn't support non-constants in a for loop statement so this is
    // a workaround.
    for (int i = 1; i >= 1; i++) { 
        f += c * noise(p);
        sum += c;
        c /= 2.0;
        p = m * p * 2.0;
        if (i == octaves) {
            break;
        }
    }
    return f / sum;
}
```

Then our `terrain` function can be something like

```glsl
float terrain(float x, float z) {
    return fbm(vec2(x, z), 2);
}
```

### Texturing

To texture our terrain, we can vary the color depending on its height and
flatness (y component of normal). We can even use Perlin noise to add some
realism when blending between colors. For example:

```glsl
vec3 material(vec3 p, vec3 n) {
    // Blend between rock and snow. Higher up, more snow. Flatter land, more
    // snow.
    
    float flatness = n.y;
    vec3 snowColor = vec3(2.8);
    vec3 rockColor = vec3(0.6);
    float randMixing = fbm(vec2(p.x, p.z), 2);
    float rockSnowMix = snowPresenceAtHeight(p.y) * flatness + randMixing;
    vec3 rockAndSnow = mix(rockColor, snowColor, rockSnowMix);

    // Blend grass and dirt to make 'girt'
    
    vec3 grassColor = vec3(0.70, 0.85, 0.40);
    vec3 dirtColor = vec3(0.7, 0.7, 0.4);
    float grassDirtMix = fbm(vec2(p.x, p.z), 2);
    vec3 girt = mix(grassColor, dirtColor, grassDirtMix);
        
    // Blend between girt and rock. Higher up, more rock. Steeper cliff, more
    // rock.
    
    // You see rock at a height of -100
    float rockGradientStart = -100.;
    // You stop seeing rock and just see snow at a height of -60
    float rockGradientEnd = -60.;
    float rockPresenceAtHeight = smoothstep(rockGradientStart, rockGradientEnd, p.y);
    vec3 girtAndRock = mix(girt, rockAndSnow,
                           rockPresenceAtHeight * (1. - flatness));
    
    return girtAndRock;
}
```

### Fog

We can transform our resulting pixel color with the formula

$$
    \text{newColor} = (1 - f) \cdot \text{skyColor} + f \cdot \text{originalColor}
$$

where $f$ is called the fog factor. There are many ways to choose $f$, but
a simple one is called exponential squared fog,

$$
    f = \exp\left(-(\text{dist} \cdot \text{density})^\text{falloff}\right)
$$

where $\text{dist}$ is the distance from the viewer to the point of the surface
we are coloring, $\text{density}$ is the chosen fog density, and
$\text{falloff}$ determines how quickly the fog starts to obscure things.

### Sun

Putting a sun in the sky adds a nice extra detail. If the ray we marched on
didn't hit anything (but the sky itself), we color it depending on the distance
of `gl_FragCoord.xy` to the sun's chosen position. For example:

```glsl
// We run this code in the case where the ray missed any scenery. The sun will
// be drawn at (1.2,1), where (0,0) is the bottom-left of the screen and (1,1)
// is the top-right.

vec3 sunColor = vec3(0.8, 0.75, 0.6);
vec3 skyColor = vec3(0.7, 0.75, 0.85);

float ar = resolution.x / resolution.y;
vec2 p = gl_FragCoord.xy / resolution;
p.x *= ar; // Without this, the sun would look squished

// Distance of p from sun
float gradient = length(p - vec2(1.2, 1.0));

// This makes it so if the distance is less than 0.1, then the pixel is
// yellow (sunColor), otherwise, it is blue (skyColor)
float mixing = smoothstep(0., 0.1, gradient);

gl_FragColor = vec4(mix(sunColor, skyColor, mixing), 1.0);
```

### Putting it all together
