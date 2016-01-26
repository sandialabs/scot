'use strict';

var React        = require('react')
var assign       = require('object-assign')
var MenuItemCell = require('../MenuItemCell')

module.exports = function(props, column) {
    var style = assign({}, props.defaultCellStyle, props.cellStyle)

    return React.createElement(MenuItemCell, {style: style}, props.data[column])
}