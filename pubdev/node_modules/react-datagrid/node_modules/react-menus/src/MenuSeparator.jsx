'use strict';

var React  = require('react')
var assign = require('object-assign')

var emptyFn = function(){}

var MenuSeparator = React.createClass({

    displayName: 'ReactMenuSeparator',

    getDefaultProps: function() {
        return {
            size: 1
        }
    },

    render: function() {
        var props = this.prepareProps(this.props)

        return <tr {...props}><td colSpan={10} style={{padding: 0}}></td></tr>
    },

    prepareProps: function(thisProps) {
        var props = {}

        assign(props, thisProps)

        props.style = this.prepareStyle(props)
        props.className = this.prepareClassName(props)

        return props
    },

    prepareClassName: function(props) {
        var className = props.className || ''

        className += ' menu-separator'

        return className
    },

    prepareStyle: function(props) {
        var style = {}

        assign(style,
            MenuSeparator.defaultStyle,
            MenuSeparator.style,
            {
                height: MenuSeparator.size || props.size
            },
            props.style
        )

        return style
    }
})

MenuSeparator.defaultStyle = {
    cursor    : 'auto',
    background: 'gray'
}

MenuSeparator.style = {}

module.exports = MenuSeparator