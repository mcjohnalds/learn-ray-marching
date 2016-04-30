var shaders = {}

// Load shaders for all shader-demos
$(window).load(function() {
    MathJax.Hub.Config({
        tex2jax: {inlineMath: [['$','$'], ['\\(','\\)']]}
    });

    var canvases = $("canvas[data-shader]").each(function() {
        $(this).attr({width:400,height:300}).css({width:'400px',height:'300px'})
        var canvas = $(this)[0];
        new ShaderDemo(canvas);
    });

    var editors = $(".read-only").each(function() {
        var el = $(this)

        // Remove empty lines at start and end
        el.text(el.text().trim())

        var editor = ace.edit(el[0]);
        editor.setOptions({
            readOnly: true,
            highlightActiveLine: false,
            highlightGutterLine: false
        });
        
        // Hide cursor
        editor.renderer.$cursorLayer.element.style.opacity = 0;

        // Hide gutter
        editor.renderer.setShowGutter(false);

        // Default to GLSL language
        editor.session.setMode("ace/mode/glsl");

        // Show scrollbar past 30 LOC
        editor.setOption("maxLines", 20);

        // Disable all shortcuts
        editor.commands.commmandKeyBinding = {};

        editor.setShowPrintMargin(false);

        editor.setOptions({
            fontFamily: "Computer Modern Typewriter",
            fontSize: "12pt"
        });
    });
});
