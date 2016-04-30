# COSC3000 Proposal: "Learn Ray Marching"

John Owen, student ID: 43591617.

## What

The project will be a website that teaches the theory of the rendering
technique known as ray marching. **In addition to explanatory text and
diagrams, it will include real-time interactive 3D demos embedded in the pages
that implement the ideas discussed.** Ideally, I would like to let the user
edit the code for the demos to help understand out how they work (similar to
Shadertoy).

Ray marching is a rendering technique similar to ray tracing where rays are
cast and "marched" through to find their intersection with a shape. It presents
advantages such as being able to render "pathological" surfaces like fractals
or other implicitly defined geometry. Though possibly the nicest thing about
it, is that it's appropriate to implement it entirely in a single fragment
shader.

My project will specifically focus on the sphere tracing variant of ray
marching algorithms, but I may include other methods such as volumetric ray
casting if time permits.

## Why

When I was first learning about ray marching, most websites gave terse
implementations without explanations and left me wanting more depth, but
research level papers are just too hard to digest for a beginner. I would like
if there was a resource for learning about ray marching that presented both the
theory and implementation in a clear manner.  I will try and assume as little
background knowledge as possible, but the target audience will have to be
someone who has some familiarity with computer graphics.

## How

HTML, CSS, and some external javascript libraries will be used for the
presentation of the website. For the interactive 3D demos, javascript in
conjunction with WebGL will be used. **There will be no external libraries like
three.js used for the demos, everything will be done from scratch.**

WebGL is a javascript API based on OpenGL ES, which works with all modern
web browsers.
