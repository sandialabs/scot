'use strict';

var Region = require('region-align')
var getConstrainRegion = require('./getConstrainRegion')

module.exports = function(props, subMenuRegion, targetAlignRegion, constrainTo){
    var constrainRegion = getConstrainRegion.call(this, constrainTo)

    if (!constrainRegion){
        return
    }



    if (typeof props.alignSubMenu === 'function'){
        props.alignSubMenu(subMenuRegion, targetAlignRegion, constrainRegion)
    } else {
        var pos = subMenuRegion.alignTo(targetAlignRegion, [
            //align to right
            'tl-tr','bl-br',

            //align to left
            'tr-tl', 'br-bl'
        ], { constrain: constrainRegion })

        return (pos == 'tl-tr' || pos == 'tr-tl')?
                    //align downwards
                    1:

                    //align upwards
                    -1
    }
}