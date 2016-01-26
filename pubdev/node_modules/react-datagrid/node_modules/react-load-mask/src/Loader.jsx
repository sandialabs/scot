'use strict';

var React  = require('react')
var assign = require('object-assign')

module.exports = React.createClass({

    displayName: 'Loader',

    getDefaultProps: function(){
        return {
            defaultStyle: {
                margin: 'auto',
                position: 'absolute',
                top: 0,
                left: 0,
                bottom: 0,
                right: 0,
            },
            defaultClassName: 'loader',
            size: 40,
        }
    },

    render: function() {
        var props = assign({}, this.props)

        this.prepareStyle(props)

        props.className = props.className || ''
        props.className += ' ' + props.defaultClassName

        return React.DOM.div(props,
            <div className="loadbar loadbar-1" />,
            <div className="loadbar loadbar-2" />,
            <div className="loadbar loadbar-3" />,
            <div className="loadbar loadbar-4" />,
            <div className="loadbar loadbar-5" />,
            <div className="loadbar loadbar-6" />,
            <div className="loadbar loadbar-7" />,
            <div className="loadbar loadbar-8" />,
            <div className="loadbar loadbar-9" />,
            <div className="loadbar loadbar-10" />,
            <div className="loadbar loadbar-11" />,
            <div className="loadbar loadbar-12" />
        )
    },

    prepareStyle: function(props){

        var style = {}

        assign(style, props.defaultStyle)
        assign(style, props.style)

        style.width = props.size
        style.height = props.size

        props.style = style
    }
})