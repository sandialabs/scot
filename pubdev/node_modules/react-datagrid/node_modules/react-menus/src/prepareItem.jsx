'use strict';

var React  = require('react')
var assign = require('object-assign')

var renderCells     = require('./MenuItem/renderCells')
var MenuItem        = require('./MenuItem')
var MenuItemFactory = React.createFactory(MenuItem)
var MenuSeparator   = require('./MenuSeparator')

module.exports = function(props, state, item, index) {

    var expandedIndex = state.itemProps?
                            state.itemProps.index:
                            -1

    if (item === '-'){
        return <MenuSeparator key={index}/>
    }

    var className   = [props.itemClassName, item.cls, item.className]
                        .filter(x => !!x)
                        .join(' ')

    var itemProps = assign({
        className  : className,
        key        : index,
        data       : item,
        columns    : props.columns,
        expanded   : index === expandedIndex,
        disabled   : item.disabled,
        onClick    : item.onClick || item.fn
    }, props.itemStyleProps)

    itemProps.children = renderCells(itemProps)

    if (item.items){
        var Menu = require('./Menu')
        itemProps.children.push(<Menu items={item.items}/>)
    }

    return (props.itemFactory || MenuItemFactory)(itemProps)
}