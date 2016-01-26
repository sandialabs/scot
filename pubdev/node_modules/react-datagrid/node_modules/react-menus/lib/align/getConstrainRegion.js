'use strict';

var Region = require('region-align')
var selectParent = require('select-parent')

module.exports = function(constrainTo){
    var constrainRegion

    if (constrainTo === true){
        constrainRegion = Region.getDocRegion()
    }

    if (!constrainRegion && typeof constrainTo === 'string'){
        var parent = selectParent(constrainTo, this.getDOMNode())
        constrainRegion = Region.from(parent)
    }

    if (!constrainRegion && typeof constrainTo === 'function'){
        constrainRegion = Region.from(constrainTo())
    }

    return constrainRegion
}