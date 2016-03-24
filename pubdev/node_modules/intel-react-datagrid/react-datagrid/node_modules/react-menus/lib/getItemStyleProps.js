'use strict';

var assign = require('object-assign')

module.exports = function(props, state){

    var itemStyle         = assign({}, props.defaultItemStyle, props.itemStyle)
    var itemOverStyle     = assign({}, props.defaultItemOverStyle, props.itemOverStyle)
    var itemActiveStyle   = assign({}, props.defaultItemActiveStyle, props.itemActiveStyle)
    var itemDisabledStyle = assign({}, props.defaultItemDisabledStyle, props.itemDisabledStyle)
    var itemExpandedStyle = assign({}, props.defaultItemExpandedStyle, props.itemExpandedStyle)
    var cellStyle     = assign({}, props.defaultCellStyle, props.cellStyle)

    return {
        itemStyle        : itemStyle,
        itemOverStyle    : itemOverStyle,
        itemActiveStyle  : itemActiveStyle,
        itemDisabledStyle: itemDisabledStyle,
        itemExpandedStyle: itemExpandedStyle,
        cellStyle        : cellStyle
    }
}