'use strict';

var React         = require('react')
var assign        = require('object-assign')
var getArrowStyle = require('arrow-style')

function emptyFn(){}

var SCROLLER_STYLE = {
    left      : 0,
    right     : 0,
    position  : 'absolute',
    cursor    : 'pointer',
    zIndex    : 1
}

function generateArrowStyle(props, state, overrideStyle){
    var style = assign({}, overrideStyle)

    var arrowConfig = {
        color: style.color || props.arrowColor
    }

    var offset = 4
    var width  = style.width  || props.arrowWidth  || props.arrowSize || (props.style.height - offset)
    var height = style.height || props.arrowHeight || props.arrowSize || (props.style.height - offset)

    arrowConfig.width  = width
    arrowConfig.height = height

    assign(style, getArrowStyle(props.side == 'top'? 'up':'down', arrowConfig))

    style.display = 'inline-block'
    style.position = 'absolute'

    style.left = '50%'
    style.marginLeft = -width

    style.top = '50%'
    style.marginTop = -height/2

    if (state.active){
        style.marginTop += props.side == 'top'? -1: 1
    }

    return style
}

var Scroller = React.createClass({displayName: "Scroller",

    display: 'ReactMenuScroller',

    getInitialState: function() {
        return {}
    },

    getDefaultProps: function(){
        return {
            height: 10,
            defaultStyle: {
                background : 'white'
            },
            defaultOverStyle: {},
            overStyle: {},

            defaultTopStyle: {
                borderBottom: '1px solid gray'
            },
            topStyle: {},
            defaultBottomStyle: {
                borderTop: '1px solid gray'
            },
            bottomStyle: {},

            arrowColor: 'gray',

            arrowStyle: {},
            defaultArrowStyle: {},
            defaultArrowOverStyle: {
                color: 'rgb(74, 74, 74)'
            },
            arrowOverStyle: {}
        }
    },

    handleMouseEnter: function() {
        this.setState({
            mouseOver: true
        })
    },

    handleMouseLeave: function() {
        this.setState({
            mouseOver: false
        })
    },

    handleMouseDown: function(event) {
        this.setState({
            active: true
        })

        ;(this.props.onMouseDown || emptyFn)(event)
    },

    handleMouseUp: function(event) {
        this.setState({
            active: false
        })

        ;(this.props.onMouseUp || emptyFn)(event)
    },

    render: function(){
        var props = assign({}, this.props, {
            onMouseEnter: this.handleMouseEnter,
            onMouseLeave: this.handleMouseLeave,

            onMouseDown: this.handleMouseDown,
            onMouseUp  : this.handleMouseUp
        })

        var state = this.state
        var side  = props.side

        props.className = this.prepareClassName(props, state)

        props.style = this.prepareStyle(props, state)

        var arrowStyle = this.prepareArrowStyle(props, state)

        return props.factory?
                    props.factory(props, side):
                    React.createElement("div", React.__spread({},  props), 
                        React.createElement("div", {style: arrowStyle})
                    )
    },

    prepareStyle: function(props, state) {
        var defaultOverStyle
        var overStyle

        if (state.mouseOver){
            overStyle        = props.overStyle
            defaultOverStyle = props.defaultOverStyle
        }

        var defaultSideStyle = props.side == 'top'?
                                props.defaultTopStyle:
                                props.defaultBottomStyle
        var sideStyle = props.side == 'top'?
                            props.topStyle:
                            props.bottomStyle

        var style = assign({}, SCROLLER_STYLE,
                            props.defaultStyle, defaultSideStyle, defaultOverStyle,
                            props.style, sideStyle, overStyle)

        style.height = style.height || props.height
        style[props.side] = 0
        if (!props.visible){
            style.display = 'none'
        }

        return style
    },

    prepareClassName: function(props, state) {
        //className
        var className = props.className || ''
        className += ' z-menu-scroller ' + props.side

        if (props.active && props.visible){
            className += ' active'
        }

        return className
    },

    prepareArrowStyle: function(props, state) {

        var defaultArrowOverStyle
        var arrowOverStyle

        if (state.mouseOver){
            defaultArrowOverStyle = props.defaultArrowOverStyle
            arrowOverStyle        = props.arrowOverStyle
        }

        var arrowStyle = assign({}, props.defaultArrowStyle, defaultArrowOverStyle, props.arrowStyle, arrowOverStyle)

        return generateArrowStyle(props, state, arrowStyle)
    },

    handleClick: function(event){
        event.stopPropagation
    }
})

module.exports = Scroller