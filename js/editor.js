$(window).load(function() {
    $(".ide .resolution-selector option")
        .each((i, e) => $(e).text($(e).val() + "%"));
    var ide = new IDE({
        editor: $(".ide .editor"),
        toy: $(".ide .toy"),
        footer: $(".ide footer"),
        output: $(".ide .output"),
        compile: $(".ide .compile-button"),
        file: $(".ide .file-selector"),
        resolution: $(".ide .resolution-selector"),
        theme: $(".ide .theme-selector"),
        playPause: $(".ide .play-pause-button"),
        reset: $(".ide .reset"),
    });
    var shader = window.location.search.substring(1);
    if (shader !== "")
        ide.setFile("shaders/" + shader);
});
