'use strict';

var React = require('react')
var MenuItemCell = require('./MenuItemCell')

var cloneWithProps = require('react-clonewithprops')
var assign         = require('object-assign')

function emptyFn(){}

module.exports = function(props, state) {

    var expandedIndex  = state.itemProps?
                            state.itemProps.index:
                            -1

    var children     = props.children
    var maxCellCount = 1
    var menuItems    = []

    React.Children.map(children, function(item){
        var itemProps = item.props

        menuItems.push(item)

        if (!itemProps || !itemProps.isMenuItem){
            return
        }

        var count = React.Children.count(itemProps.children)

        maxCellCount = Math.max(maxCellCount, count)
    })

    var itemStyleProps = props.itemStyleProps
    var i = -1
    var result = menuItems.map(function(item, index){
        var itemProps = item.props

        if (itemProps && itemProps.isMenuItem){
            i++

            itemProps.onMenuItemMouseOver = this.onMenuItemMouseOver
            itemProps.onMenuItemMouseOut  = this.onMenuItemMouseOut
        }

        var children = React.Children.map(itemProps.children, function(c){ return c })
        var count    = React.Children.count(children)

        if (count < maxCellCount){
            children = children? [children]: []
        }

        while (count < maxCellCount){
            count++
            children.push(<MenuItemCell />)
        }

        var onClick = itemProps.onClick || emptyFn

        var cloned = cloneWithProps(item, assign({
            interactionStyles: props.interactionStyles,
            itemIndex: i,
            itemCount: menuItems.length,
            key      : index,
            index    : index,
            expanded : expandedIndex == index,
            children : children,
            expander : props.expander,
            applyDefaultTheme: props.applyDefaultTheme,
            theme    : props.theme,
            themes   : props.themes || this.constructor.themes,
            onExpanderClick: this.onMenuItemExpanderClick,
            onClick  : function(event, props, index){
                onClick.apply(null, arguments)
                this.onMenuItemClick(event, props, index)
            }.bind(this)
        }, {
            style        : itemStyleProps.itemStyle,
            overStyle    : itemStyleProps.itemOverStyle,
            activeStyle  : itemStyleProps.itemActiveStyle,
            disabledStyle: itemStyleProps.itemDisabledStyle,
            expandedStyle: itemStyleProps.itemExpandedStyle,
            cellStyle    : itemStyleProps.cellStyle
        }))

        return cloned

    }, this)

    return result
}