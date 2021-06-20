fetch('./func_tester.wasm').then(response => response.arrayBuffer()
).then(bytes => WebAssembly.instantiate(bytes)
).then(results => {
    console.log("Loaded wasm module");
    instance = results.instance;
    console.log("instance", instance);

    var white = 2;
    var black = 1;
    var white_crowned = 6;
    var black_crowned = 5;

    console.log("Calling offset");
    var offset = instance.exports.offsetForPosition(3, 4);
    console.log("Offset for 3,4 is ", offset);

    console.debug("White is white?", instance.exports.isWhite(white));
    console.debug("Black is black?", instance.exports.isBlack(black));
    console.debug("Black is white?", instance.exports.isWhite(black));

    console.debug("Uncrowned white?", instance.exports.isWhite(
        instance.exports.withNoCrown(white_crowned)
    ));

    console.debug("Uncrowned black?", instance.exports.isBlack(
        instance.exports.withNoCrown(black_crowned)
    ));

    console.debug("Crowned is crowned", instance.exports.isCrowned(black_crowned));
    console.debug("Crowned is crowned (b)", instance.exports.isCrowned(white_crowned));

})
