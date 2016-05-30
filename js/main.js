$(() => {
    MathJax.Hub.Config({
        tex2jax: {
            inlineMath: [["$", "$"]],
            displayMath: [["$$", "$$"]],
            skipTags: ['script', 'noscript', 'style', 'textarea', 'pre'],
        },
    });

    $("canvas[data-shader]").each((i, canvas) => {
        var toy = new ShaderToy(canvas);
        var shader = $(canvas).attr("data-shader");
        $.ajax({
            url: "shaders/" + shader,
            success: (code) => toy.load(code),
            cache: false
        });
    });
});
