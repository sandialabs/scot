'use strict';

var Region           = require('region-align')
var assign           = require('object-assign')
var cloneWithProps   = require('react-clonewithprops')
var getPositionStyle = require('./getSubMenuPositionStyle')

module.exports = function(props, state) {
    var menu = state.menu

    if (menu && this.didMount){

        var style = getPositionStyle.call(this, props, state)

        menu = cloneWithProps(menu, assign({
            ref          : 'subMenu',
            subMenu      : true,
            parentMenu   : this,
            maxHeight    : state.subMenuMaxHeight,
            onActivate   : this.onSubMenuActivate,
            onInactivate : this.onSubMenuInactivate,
            scrollerProps: props.scrollerProps,
            constrainTo  : props.constrainTo,
            expander     : props.expander,
            theme        : props.theme,
            themes       : props.themes || this.constructor.themes
        }, props.itemStyleProps))

        return React.createElement("div", {ref: "subMenuWrap", style: style, 
                onMouseEnter: this.handleSubMenuMouseEnter, 
                onMouseLeave: this.handleSubMenuMouseLeave
            }, menu)
    }
}