$(window).load(function() {
    $(".ide .resolution-selector option").each((i, e) => $(e).text($(e).val() + "%"));
    IDE.init({
        editor: $(".ide .editor"),
        demo: $(".ide .demo"),
        footer: $(".ide footer"),
        output: $(".ide .output"),
        playPause: $(".ide .play-pause-button"),
        resolution: $(".ide .resolution-selector"),
    });
});
