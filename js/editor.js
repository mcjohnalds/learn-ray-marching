$(window).load(function() {
    $(".ide .resolution-selector option").each((i, e) => $(e).text($(e).val() + "%"));
    IDE.init({
        editor: $(".ide .editor"),
        demo: $(".ide .demo"),
        footer: $(".ide footer"),
        output: $(".ide .output"),
        resolution: $(".ide .resolution-selector"),
        theme: $(".ide .theme-selector"),
        playPause: $(".ide .play-pause-button"),
    });
});
