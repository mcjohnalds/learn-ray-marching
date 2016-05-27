var IDE = (function() {
    var defaultVSource = "attribute vec2 pos;\n\nvoid main(void) {\n    gl_Position = vec4(pos, 0.0, 1.0);\n}";
    var defaultFSource = "precision mediump float;\nuniform vec2 resolution;\n\nvoid main(void) {\n    vec2 uv = gl_FragCoord.xy / resolution.xy;\n    gl_FragColor = vec4(uv, 0.0, 1.0);\n}";

    function init(elems) {
        var editor = createEditor(elems.editor[0]);
        var demo = createShaderDemo(elems);
        editor.commands.addCommand({
            name: "compile",
            bindKey: {
                win: "Alt-Enter",
                mac: "Alt-Enter",
            },
            exec: () => compileShader(elems, demo, defaultVSource,
                                      editor.getValue())
        });
        compileShader(elems, demo, defaultVSource, defaultFSource);
        elems.reloadFile.click(() => {
            setFile(elems, demo, editor, "shaders/" + elems.file.val() + ".glsl")
        });
        elems.file.change(() => {
            setFile(elems, demo, editor, "shaders/" + elems.file.val() + ".glsl")
        });
        elems.resolution.change(() => setResolution(elems, demo));
        elems.theme.change(() => setTheme(elems, editor));
        elems.playPause.change(function() {
            if (this.checked)
                demo.play();
            else
                demo.pause();
        });
        elems.reset.click(() => {
            demo.reset();
            demo.draw();
        });
    }

    function setResolution(elems, demo) {
        var val = elems.resolution.val();
        var ratio = parseFloat(val) / 100.0;
        elems.demo[0].width = elems.demo.width() * ratio;
        elems.demo[0].height = elems.demo.height() * ratio;
        demo.setResolution(elems.demo[0].width, elems.demo[0].height);
    }

    function setFile(elems, demo, editor, file) {
        $.ajax({
            url: file,
            success: (code) => {
                editor.setValue(code, -1);
                compileShader(elems, demo, defaultVSource, editor.getValue());
            },
            cache: false,
        });
    }

    function setTheme(elems, editor) {
        var val = elems.theme.val();
        editor.setTheme(val);
    }

    function createEditor(element) {
        var editor = ace.edit(element);
        editor.setTheme("ace/theme/github");
        editor.$blockScrolling = Infinity;
        editor.session.setMode("ace/mode/glsl");
        editor.setOptions({
            fontFamily: "Computer Modern Typewriter",
            fontSize: "12pt"
        });
        editor.setValue(defaultFSource, -1);
        return editor;
    }

    function compileShader(elems, demo, vSource, fSource) {
        try {
            demo.load(vSource, fSource);
            elems.output.text("Shader compiled successfuly");
            elems.footer.removeClass("fail");
            elems.footer.addClass("success");
        } catch (e) {
            if (e instanceof ShaderCompileError) {
                elems.output.text(e.message);
                elems.footer.removeClass("success");
                elems.footer.addClass("fail");
            }
            else
                throw e;
        }
    }

    function createShaderDemo(elems) {
        var demo = new ShaderToy(elems.demo[0]);
        setResolution(elems, demo);
        demo.play();
        return demo;
    }

    return {init: init};
})();
