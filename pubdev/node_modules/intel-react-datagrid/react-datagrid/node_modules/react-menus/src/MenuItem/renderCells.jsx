'use strict';

var renderCell = require('./renderCell')

module.exports = function(props) {
    return props.columns.map(renderCell.bind(null, props))
}