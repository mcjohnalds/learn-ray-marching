class IDE {
    constructor(elems) {
        this.defaultFSource = "precision mediump float;\nuniform vec2 resolution;\n\nvoid main(void) {\n    vec2 uv = gl_FragCoord.xy / resolution.xy;\n    gl_FragColor = vec4(uv, 0.0, 1.0);\n}";
        this.elems = elems;
        this.editor = this.createEditor();
        this.toy = this.createShaderToy();
        this.compileShader();
        this.updateResolutionRatio();

        elems.reloadFile.click(() => {
            this.setFile("shaders/" + elems.file.val() + ".glsl")
        });

        elems.file.change(() => {
            this.setFile("shaders/" + elems.file.val() + ".glsl")
        });

        elems.resolution.change(() => this.updateResolutionRatio());

        elems.theme.change(() => this.setTheme());

        elems.playPause.change((e) => {
            if (e.target.checked)
                this.toy.play();
            else
                this.toy.pause();
        });

        elems.reset.click(() => {
            this.toy.reset();
            this.toy.draw();
        });
    }

    /*************************************************************************
     * Public methods
     *************************************************************************/

    setFile(file) {
        $.ajax({
            url: file,
            success: (code) => {
                this.editor.setValue(code, -1);
                this.compileShader();
            },
            cache: false,
        });
    }

    /*************************************************************************
     * Private methods
     *************************************************************************/

    updateResolutionRatio() {
            var val = this.elems.resolution.val();
            var ratio = parseFloat(val) / 100.0;
            this.toy.setResolutionRatio(ratio)
    }

    setTheme() {
        var val = this.elems.theme.val();
        this.editor.setTheme(val);
    }

    createEditor() {
        var editor = ace.edit(this.elems.editor[0]);
        editor.setTheme("ace/theme/github");
        editor.$blockScrolling = Infinity;
        editor.session.setMode("ace/mode/glsl");
        editor.setOptions({
            fontFamily: "Computer Modern Typewriter",
            fontSize: "12pt"
        });
        editor.setValue(this.defaultFSource, -1);
        editor.commands.addCommand({
            name: "compile",
            bindKey: {
                win: "Alt-Enter",
                mac: "Alt-Enter",
            },
            exec: () => this.compileShader()
        });
        return editor;
    }

    compileShader() {
        try {
            this.toy.load(this.editor.getValue());
            this.elems.output.text("Shader compiled successfully");
            this.elems.footer.removeClass("fail");
            this.elems.footer.addClass("success");
        } catch (e) {
            if (e instanceof ShaderCompileError) {
                this.elems.output.text(e.message);
                this.elems.footer.removeClass("success");
                this.elems.footer.addClass("fail");
            }
            else
                throw e;
        }
    }

    createShaderToy() {
        var toy = new ShaderToy(this.elems.toy[0]);
        return toy;
    }
}
