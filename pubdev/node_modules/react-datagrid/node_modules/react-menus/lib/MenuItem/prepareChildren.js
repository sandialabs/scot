'use strict';

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _react = require('react');

var React = require('react');
var Menu = require('../Menu');
var MenuItemCell = require('../MenuItemCell');
var renderCell = require('./renderCell');

module.exports = function (props) {

    var children = [];
    var menu;

    React.Children.forEach(props.children, function (child) {
        if (child) {
            if (child.props && child.props.isMenu) {
                menu = (0, _react.cloneElement)(child, {
                    ref: 'subMenu',
                    subMenu: true
                });
                return;
            }

            if (typeof child != 'string') {
                child = (0, _react.cloneElement)(child, {
                    style: props.cellStyle,
                    itemIndex: props.itemIndex,
                    itemCount: props.itemCount
                });
            }

            children.push(child);
        }
    });

    if (menu) {
        props.menu = menu;
        var expander = props.expander || true;
        var expanderProps = {};

        if (expander) {
            expanderProps.onClick = props.onExpanderClick;
        }
        children.push(React.createElement(MenuItemCell, _extends({ expander: expander }, expanderProps)));
    }

    return children;
};