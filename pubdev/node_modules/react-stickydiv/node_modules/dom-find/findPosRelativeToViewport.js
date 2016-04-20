"use strict";
var findPos = require("./findPos");
var getPageScroll = require("./getPageScroll");

// Finds the position of an element relative to the viewport.
module.exports = function (obj) {
    var objPos = findPos(obj);
    var scroll = getPageScroll();
    return [objPos[0] - scroll[0], objPos[1] - scroll[1]];
};

