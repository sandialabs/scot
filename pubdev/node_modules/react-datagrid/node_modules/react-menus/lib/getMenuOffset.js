'use strict';

var Region       = require('region-align')
var selectParent = require('select-parent')

module.exports = function(domNode){

    var menuRegion = Region.from(selectParent('.z-menu', domNode))
    var thisRegion = Region.from(domNode)

    return {
        // pageX : thisRegion.left,
        // pageY : thisRegion.top,

        left  : thisRegion.left - menuRegion.left,
        top   : thisRegion.top  - menuRegion.top,
        width : thisRegion.width,
        height: thisRegion.height
    }
}