$(window).load(function() {
    var editorOutputDiv = $(".editor-output");
    var output = $(".editor-output .output");

    function compileShader() {
        try {
            toy.load(vSource, editor.getValue());
            output.text("Shader compiled successfuly");
            editorOutputDiv.removeClass("output-fail");
            editorOutputDiv.addClass("output-success");
        } catch (e) {
            if (e instanceof ShaderCompileError) {
                output.text(e.message);
                editorOutputDiv.removeClass("output-success");
                editorOutputDiv.addClass("output-fail");
            }
            else
                throw e;
        }
    }

    var editor = ace.edit($(".editor")[0]);
    editor.setTheme("ace/theme/github");
    editor.commands.addCommand({
        name: "compile",
        bindKey: {
            win: "Alt-Enter",
            mac: "Alt-Enter",
        },
        exec: () => compileShader()
    });
    editor.$blockScrolling = Infinity;
    editor.session.setMode("ace/mode/glsl");
    editor.setOptions({
        fontFamily: "Computer Modern Typewriter",
        fontSize: "12pt"
    });
    editor.setValue(`precision mediump float;
uniform vec2 resolution;

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    gl_FragColor = vec4(uv, 0.0, 1.0);
}`, -1);

    var vSource =`attribute vec2 pos;
                  void main(void) {
                      gl_Position = vec4(pos, 0.0, 1.0);
                  }`;

    var toy = new ShaderToy($(".editor-demo")[0]);
    compileShader();
});
