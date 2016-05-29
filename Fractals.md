---
layout: chapter
title: Fractals
previous: TerrainMarching
---

### Mandelbrot fractal

We'll take a quick detour from ray marching for a second to discuss the
Mandelbrot fractal. The Mandelbrot set is all values of $c$ where the
sequence

$$
    z_{n+1} = z_n^2 + c
$$

diverges, for $z$ and $c$ as complex numbers. We can visualize this sequence in
two dimensions by mapping $c$'s real part to `gl_FragCoord.x` and the imaginary
part to `gl_FragCoor.y`. If we color a pixel white when the series converges
and black when it diverges, then we get the Mandelbrot fractal.

(insert pic)

One algorithm to draw this is as follows:

For each pixel, we first set $c$ to the range $(-2.5,-1) \leq c \leq (1, 1)$.
The entire interesting portion of the Mandelbrot set is contained within this
range\*, although we can zoom in anywhere on the edge of the fractal as far
as we want, and we'll keep seeing more cool fractal things.

```glsl
vec2 c = gl_FragCoord.xy / resolution; // 0 <= c <= 1
c.x = c.x * 3.5 - 2.5; // -2.5 <= c.x <= 1
c.y = c.y * 2. - 1.; // -1 <= c.y <= 1
```

Then, we compute $z_n$ for higher and higher values of $n$ until it diverges
or we are confident it has converged.

```glsl
// Multiply two complex numbers.
vec2 complexMul(vec2 a, vec2 b) {
	return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

for (int i = 0; i < 500; i++) {
    // If the length of z ever exceeds 2, then we know it has diverged
    // Remember that dot(z, z) = length(z) ^ 2
    if (dot(z, z) >= 4.) {
        gl_FragColor = vec4(vec3(0.), 1.);
        return;
    }

    // z(i) = z(i-1)^2 + c
    // Complex numbers have a special way of being multiplied together
    z = complexMul(z, z) + c;
}
// We reach this point only if z converged (i.e outside the Mandelbrot set)
gl_FragColor = vec4(1.);
```

This is the escape time algorithm, it's dumb and it produces rather ugly
pictures like this:

(insert pic)

We can do better then that, in fact we can again use distance functions! The
distance from $c$ to the boundary of the Mandelbrot set is

$$
d = \lim_{n\to\infty}
    \frac{ \left|z_{n}\right| }{ \left|z'_{n}\right| }
    \frac{ \ln \left|z_{n}\right| }{ 2 }
$$

where $z'_{n}$ is the rate of change of $z$ at $n$. We can
differentiate $z_n$ using the chain rule to get

$$
    z'_{n+1} = 2z_{n}\cdot z'_{n} + 1.
$$

Now we can use the distance $d$ to darken the points close to the edge of the
Mandelbrot set. The algorithm now becomes:

```glsl
vec2 dz = vec2(0.); // z'

for (int i = 0; i < 300; i++) {
    // dz = 2*z*z'+1
    dz = 2. * complexMul(z, dz) + vec2(1., 0.);
    // z = z^2 + c
    z = complexMul(z, z) + c;

    if (dot(z, z) > 4.)
        break; // z diverged
}
// Now either z converged to its limit or it diverged

// d is the distance of c from mandelbrot boundary
//     d = 0.5 * |z| / |z'| * log|z|
// where |z| is the complex modulus
float d = 0.5 * sqrt(dot(z, z) / dot(dz, dz)) * log(length(z));

// 0 <= lightness <= 1. Will be 0 when c is far from the boundary and 1 when it
// is on the boundary or inside the set.
float lightness = clamp(d * 700., 0., 1.);
gl_FragColor = vec4(vec3(lightness), 1.);
```

This has the effect of antialiasing the edges.

\* Maybe $z$ has interesting features outside of this range, I'm not really
sure.

### Mandelbulb fractal

We can forget about two-dimensional complex numbers and extend our fractal to
some sort of three-dimensional complex number system. First, we will consider
$z$ for an arbitrary power,

$$
    z_{n+1} = z_{n}^k + c.
$$

And for simplicity we'll define the escape radius $r$ with

\begin{gather\*}
    r_n = |z_n|,\\
    r'_n = |z'_n|.
\end{gather\*}

so our distance formula becomes

$$
    d = \lim_{n\to\infty} \frac{ r_n }{ r'_n } \frac{ \ln r_n }{ 2 }.
$$

But how do we define $z^k$ for our three-dimensional numbers? Well to square
a two-dimensional complex number, one method is:

1. Convert $z=x+yi$ from Cartesian coordinates $x$ (real part) and $y$
   (imaginary part) to polar coordinates with magnitude $r=\sqrt{x^2+y^2}$ and
   rotation $\phi=\text{atan2}(y,x)$.
2. Take $r$ to the $k$-th power and multiply $\phi$ by $k$.
3. Convert it back into Cartesian coordinates $x=r\cos(\phi)$ and
   $y=r\sin(\phi)$ so that $z=r(\cos(\phi)+i\sin(\theta))$.

So for a three-dimensional number $z$ we can do:

1. Convert $z=(z_x,z_y,z_z)$ from Cartesian coordinates to polar coordinates
   with magnitude $r=\sqrt{z_x^2+z_y^2+z_z^2}$, angle
   $\phi=\text{atan}(z_y,z_x)$, and angle
   $\theta=\text{acos}\left(\frac{z_z}{r}\right)$.
2. Take $r$ to the $k$-th power and multiply both $\theta$ and $\phi$ by $k$.
3. Convert it back into Cartesian coordinates with
   $z_x = r\sin(\theta)\cos(\phi)$, $z_y=r\sin(\phi)\sin(\theta)$, and
   $z_z=r\cos(\theta)$.

Now we can compute $z_n$, but what about $z'_n$? As it turns out, using the
chain rule and differentaiting as you would with any other number works
perfectly, so

$$
    z'_{n+1} = k z_n^{k-1} z'_n + 1
$$

With this, we can write our distance function for the Mandelbubl fractal as

```glsl
float distFunc(vec3 pos) {
    const float k = 8.; // A power of 8 looks pretty good
    const float bailout = 5.; // If r exceeds this, we assume it diverged
    const int iterations = 50;

	vec3 z = pos;
	float r;
	float dr = 1.0; // r'
    for (int i = 0; i < iterations; i++) {
		r = length(z);
        if (r > bailout) break;

        // Convert (z.x,z.y,z.z) to polar coords
        float theta = acos(z.z / r);
        float phi = atan(z.y, z.x);

        // Our new r' is k*r^(k-1)*r'+1
        dr = k * pow(r, k - 1.) * dr + 1.;

        // Find the spherical coords of z for z=z^power
        float zr = pow(r, k); // New r value
        theta = theta * k;
        phi = phi * k;

        // Convert (zr,theta,phi) to Cartesian coords
        z = zr * vec3(
                sin(theta) * cos(phi),
                sin(phi) * sin(theta),
                cos(theta));

        // This is the c value in z(n+1)=z(n)^k+c
        z += pos;
    }

    // d value
    return 0.5 * log(r) * r / dr;
}
```

(insert pic)

This concludes our exploration into ray marching.
