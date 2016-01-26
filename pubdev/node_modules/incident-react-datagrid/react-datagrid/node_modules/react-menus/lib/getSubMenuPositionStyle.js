'use strict';

var Region = require('region-align')
var assign = require('object-assign')
var align  = require('./align')

module.exports = function getPositionStyle(props, state){
    if (!state.menu || !this.didMount){
        this.prevMenuIndex = -1
        return
    }

    var offset = state.menuOffset
    var left   = offset.left + offset.width
    var top    = offset.top

    var menuIndex = state.itemProps.index
    var sameMenu = this.prevMenuIndex == menuIndex

    if (this.aligning && !sameMenu){
        this.aligning = false
    }

    this.prevMenuIndex = menuIndex

    var style = {
        position     : 'absolute',
        visibility   : 'hidden',
        overflow     : 'hidden',
        pointerEvents: 'none',
        left         : left,
        top          : top,
        zIndex       : 1
    }

    if (!this.aligning && !sameMenu){
        setTimeout(function(){

            if (!this.didMount){
                return
            }

            var thisRegion = Region.from(this.getDOMNode())
            var menuItemRegion = Region.from({
                left  : thisRegion.left,
                top   : thisRegion.top + offset.top,
                width : offset.width,
                height: offset.height
            })

            var subMenuMounted = this.refs.subMenu && this.refs.subMenu.isMounted()
            if (!subMenuMounted){
                return
            }

            var subMenuRegion = Region.from(this.refs.subMenu.refs.scrollContainer.getCurrentSizeDOM())

            var initialHeight = subMenuRegion.height

            var alignPos = align(props, subMenuRegion, /* alignTo */ menuItemRegion, props.constrainTo)

            var newHeight = subMenuRegion.height
            var maxHeight

            if (newHeight < initialHeight){
                maxHeight = newHeight - props.subMenuConstrainMargin
            }

            if (maxHeight && alignPos == -1 /* upwards*/){
                subMenuRegion.top = subMenuRegion.bottom - maxHeight
            }

            var newLeft = subMenuRegion.left - thisRegion.left
            var newTop  = subMenuRegion.top  - thisRegion.top

            if (Math.abs(newLeft - left) < 5){
                newLeft = left
            }

            if (Math.abs(newTop - top) < 5){
                newTop = top
            }

            this.subMenuPosition = newLeft < 0? 'left': 'right'

            this.alignOffset = {
                left: newLeft,
                top : newTop
            }
            this.aligning = true

            this.setState({
                subMenuMaxHeight: maxHeight
            })

        }.bind(this), 0)
    }

    if (sameMenu || (this.aligning && this.alignOffset)){
        assign(style, this.alignOffset)
        style.visibility = 'visible'
        delete style.pointerEvents
        delete style.overflow
    }

    this.aligning = false

    return style
}