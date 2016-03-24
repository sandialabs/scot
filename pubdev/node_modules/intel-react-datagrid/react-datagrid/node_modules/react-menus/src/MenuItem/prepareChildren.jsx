'use strict';

var React        = require('react')
var Menu         = require('../Menu')
var MenuItemCell = require('../MenuItemCell')
var renderCell   = require('./renderCell')
var cloneWithProps = require('react-clonewithprops')

module.exports = function(props) {

    var children = []
    var menu

    React.Children.forEach(props.children, function(child){
        if (child){
            if (child.props && child.props.isMenu){
                menu = cloneWithProps(child, {
                    ref: 'subMenu'
                })
                menu.props.subMenu = true
                return
            }

            if (typeof child != 'string'){
                child = cloneWithProps(child, {
                    style    : props.cellStyle,
                    itemIndex: props.itemIndex,
                    itemCount: props.itemCount
                })
            }

            children.push(child)
        }
    })

    if (menu){
        props.menu = menu
        var expander = props.expander || true
        var expanderProps = {}

        if (expander){
            expanderProps.onClick = props.onExpanderClick
        }
        children.push(<MenuItemCell expander={expander} {...expanderProps}/>)
    }

    return children
}