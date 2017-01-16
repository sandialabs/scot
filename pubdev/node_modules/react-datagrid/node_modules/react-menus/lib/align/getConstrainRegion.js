'use strict';

var _reactDom = require('react-dom');

var Region = require('region-align');
var selectParent = require('select-parent');

module.exports = function (constrainTo) {
    var constrainRegion;

    if (constrainTo === true) {
        constrainRegion = Region.getDocRegion();
    }

    if (!constrainRegion && typeof constrainTo === 'string') {
        var parent = selectParent(constrainTo, (0, _reactDom.findDOMNode)(this));
        constrainRegion = Region.from(parent);
    }

    if (!constrainRegion && typeof constrainTo === 'function') {
        constrainRegion = Region.from(constrainTo());
    }

    return constrainRegion;
};