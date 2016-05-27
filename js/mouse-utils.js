function detectMouseDown(element, onMouseDown) {
    console.assert(element instanceof HTMLElement);
    console.assert(typeof onMouseDown === "function");

    $(element).mousedown((e) => {
        var rect = element.getBoundingClientRect();
        var x = e.clientX - rect.left;
        var y = e.clientY - rect.top;
        onMouseDown(x, y);
    });
}

function detectMouseDrag(element, onMouseDrag) {
    console.assert(element instanceof HTMLElement);
    console.assert(typeof onMouseDrag === "function");

    var isDown = false;

    $(element).mousedown(() => {
        isDown = true;
    });

    $(element).mouseup(() => {
        isDown = false;
    });

    $(element).mousemove((e) => {
        var rect = element.getBoundingClientRect();
        var x = e.clientX - rect.left;
        var y = e.clientY - rect.top;
        if (isDown)
            onMouseDrag(x, y);
    });
}
