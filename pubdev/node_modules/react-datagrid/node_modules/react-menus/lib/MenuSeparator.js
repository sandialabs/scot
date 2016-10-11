'use strict';

var React = require('react');
var assign = require('object-assign');

var emptyFn = function emptyFn() {};

var MenuSeparator = React.createClass({

    displayName: 'ReactMenuSeparator',

    getDefaultProps: function getDefaultProps() {
        return {
            size: 1
        };
    },

    render: function render() {
        var props = this.prepareProps(this.props);

        return React.createElement(
            'tr',
            props,
            React.createElement('td', { colSpan: 10, style: { padding: 0 } })
        );
    },

    prepareProps: function prepareProps(thisProps) {
        var props = {};

        assign(props, thisProps);

        props.style = this.prepareStyle(props);
        props.className = this.prepareClassName(props);

        return props;
    },

    prepareClassName: function prepareClassName(props) {
        var className = props.className || '';

        className += ' menu-separator';

        return className;
    },

    prepareStyle: function prepareStyle(props) {
        var style = {};

        assign(style, MenuSeparator.defaultStyle, MenuSeparator.style, {
            height: MenuSeparator.size || props.size
        }, props.style);

        return style;
    }
});

MenuSeparator.defaultStyle = {
    cursor: 'auto',
    background: 'gray'
};

MenuSeparator.style = {};

module.exports = MenuSeparator;