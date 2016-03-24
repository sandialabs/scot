'use strict';

function emptyFn(){}

var React      = require('react')
var assign     = require('object-assign')
var Region     = require('region-align')
var inTriangle = require('point-in-triangle')
var hasTouch = require('has-touch')

var normalize = require('react-style-normalizer')

var getMenuOffset = require('./getMenuOffset')
var getConstrainRegion = require('./align/getConstrainRegion')
var getItemStyleProps = require('./getItemStyleProps')
var renderSubMenu     = require('./renderSubMenu')
var renderChildren    = require('./renderChildren')
var prepareItem       = require('./prepareItem')

var propTypes = require('./propTypes')
var ScrollContainer = require('./ScrollContainer')

var MenuItem = require('./MenuItem')

var MenuClass = React.createClass({

    displayName: 'Menu',

    propTypes: propTypes,

    getDefaultProps: function(){

        return {
            isMenu: true,
            constrainTo: true,
            enableScroll: true,
            interactionStyles: true,
            applyDefaultTheme: true,

            defaultStyle: {
                display  : 'inline-block',
                boxSizing: 'border-box',
                position : 'relative',

                background: 'white',
                //theme props
                border: '1px solid rgb(46, 153, 235)'
            },
            defaultSubMenuStyle: {
                position: 'absolute'
            },
            subMenuStyle: null,


            scrollerProps: {},

            columns: ['label'],
            items  : null,
            visible: true,

            defaultItemStyle: {},
            itemStyle: {},

            defaultItemOverStyle: {},
            itemOverStyle: {},

            defaultItemDisabledStyle: {},
            itemDisabledStyle: {},

            defaultItemExpandedStyle: {},
            itemExpandedStyle: {},

            defaultCellStyle: {},
            cellStyle: {},

            stopClickPropagation: true
        }
    },

    getInitialState: function() {
        return {
            mouseOver: false
        }
    },

    componentWillUnmount: function(){
        this.didMount = false
    },

    componentDidMount: function() {
        ;(this.props.onMount || emptyFn)(this)

        this.didMount = true

        if ((this.props.constrainTo || this.props.alignTo) && !this.props.subMenu){
            setTimeout(function(){

                if (!this.isMounted()){
                    return
                }

                var props = this.props

                var scrollRegion = Region.from(this.refs.scrollContainer.getDOMNode())
                var domNode      = this.getDOMNode()
                var domRegion    = Region.from(domNode)
                var paddingSize  = domRegion.height

                var actualHeight = scrollRegion.height + paddingSize
                //get clientHeight of this dom node, so as to account for padding

                //build the actual region of the menu
                var actualRegion = Region({
                    left  : domRegion.left,
                    right : domRegion.right,

                    top   : domRegion.top,
                    bottom: domRegion.top + actualHeight
                })

                var constrainRegion = props.constrainTo?
                                        getConstrainRegion(props.constrainTo):
                                        null

                var newState

                if (props.alignTo){
                    var parentRegion = Region.from(domNode.parentNode)
                    var alignRegion = Region.from(props.alignTo)

                    actualRegion.alignTo(alignRegion, props.alignPositions, {
                        offset: props.alignOffset,
                        constrain: constrainRegion
                    })

                    var newTop = actualRegion.top - parentRegion.top
                    var newLeft = actualRegion.left - parentRegion.left

                    newState = {
                        style: {
                            left: newLeft,
                            top : newTop
                        }
                    }
                }

                if (constrainRegion){
                    newState = newState || {}

                    if (actualRegion.bottom > constrainRegion.bottom){
                        newState.maxHeight = constrainRegion.bottom - actualRegion.top - paddingSize
                    }
                }

                newState && this.setState(newState)
            }.bind(this), 0)
        }
    },

    prepareProps: function(thisProps, state) {
        var props = {}

        assign(props, this.props)

        props.style     = this.prepareStyle(props, state)
        props.className = this.prepareClassName(props)

        props.itemStyleProps = getItemStyleProps(props, state)
        props.children  = this.prepareChildren(props, state)

        props.scrollerProps = this.prepareScrollerProps(props)

        return props
    },

    prepareScrollerProps: function(props) {
        return assign({}, props.scrollerProps)
    },

    prepareChildren: function(props, state){

        var children = props.children

        if (props.items && props.items.length){
            children = props.items.map(this.prepareItem.bind(this, props, state))
        }

        return children
    },

    prepareItem: prepareItem,

    prepareClassName: function(props) {
        var className = props.className || ''

        className += ' z-menu'

        return className
    },

    prepareStyle: function(props, state) {
        var subMenuStyle = props.subMenu?
                            props.defaultSubMenuStyle:
                            null

        var style = assign({}, props.defaultStyle, subMenuStyle, props.style, props.subMenuStyle)

        if (!props.visible || (props.items && !props.items.length)){
            style.display = 'none'
        }

        if (props.absolute){
            style.position = 'absolute'
        }

        if (props.at){
            var isArray = Array.isArray(props.at)
            var coords = {
                left: isArray?
                        props.at[0]:
                        props.at.left === undefined?
                            props.at.x || props.at.pageX:
                            props.at.left,

                top: isArray?
                        props.at[1]:
                        props.at.top === undefined?
                            props.at.y || props.at.pageY:
                            props.at.top
            }

            assign(style, coords)
        }

        if (state.style){
            assign(style, state.style)
        }

        if (!this.didMount && (props.constrainTo || props.alignTo) && !props.subMenu){
            //when a top menu is initially rendered (and should be constrained or has alignTo)
            //we show it hidden initially, so we can safely constrain and/or align it
            style.visibility = 'hidden'
            style.maxHeight  = 0
            style.overflow   = 'hidden'
        }

        return normalize(style)
    },

    /////////////// RENDERING LOGIC

    renderSubMenu: renderSubMenu,

    render: function() {
        var state = this.state
        var props = this.prepareProps(this.props, state)

        var menu     = this.renderSubMenu(props, state)
        var children = this.renderChildren(props, state)

        return (
            React.createElement("div", React.__spread({},  props), 
                menu, 
                React.createElement(ScrollContainer, {
                    onMouseEnter: this.handleMouseEnter, 
                    onMouseLeave: this.handleMouseLeave, 
                    scrollerProps: props.scrollerProps, 
                    ref: "scrollContainer", enableScroll: props.enableScroll, maxHeight: state.maxHeight || props.maxHeight}, 
                    React.createElement("table", {ref: "table", style: {borderSpacing: 0}}, 
                        React.createElement("tbody", null, 
                            children
                        )
                    )
                )
            )
        )
    },

    renderChildren: renderChildren,

    ////////////////////////// BEHAVIOUR LOGIC

    handleMouseEnter: function() {
        this.setState({
            mouseInside: true
        })

        this.onActivate()
    },

    handleMouseLeave: function() {
        this.setState({
            mouseInside: false
        })

        if (!this.state.menu && !this.state.nextItem){
        // if (!this.state.nextItem){
            this.onInactivate()
        }
    },

    onActivate: function() {
        if (!this.state.activated){
            // console.log('activate')
            this.setState({
                activated: true
            })

            ;(this.props.onActivate || emptyFn)()
        }
    },

    onInactivate: function() {
        if (this.state.activated){

            this.setState({
                activated: false
            })

            // console.log('inactivate')
            ;(this.props.onInactivate || emptyFn)()
        }
    },

    //we also need mouseOverSubMenu: Boolean
    //since when from a submenu we move back to a parent menu, we may move
    //to a different menu item than the one that triggered the submenu
    //so we should display another submenu
    handleSubMenuMouseEnter: function() {
        this.setState({
            mouseOverSubMenu: true
        })
    },

    handleSubMenuMouseLeave: function() {
        this.setState({
            mouseOverSubMenu: false
        })
    },

    isSubMenuActive: function() {
        return this.state.subMenuActive
    },

    onSubMenuActivate: function() {
        this.setState({
            subMenuActive: true
        })
    },

    onSubMenuInactivate: function() {
        var ts = +new Date()

        var nextItem      = this.state.nextItem
        var nextTimestamp = this.state.nextTimestamp || 0

        this.setState({
            subMenuActive: false,
            timestamp       : ts
        }, function(){

            setTimeout(function(){
                if (ts != this.state.timestamp || (nextItem && (ts - nextTimestamp < 100))){
                    //a menu show has occured in the mean-time,
                    //so skip hiding the menu
                    this.setItem(this.state.nextItem, this.state.nextOffset)
                    return
                }

                if (!this.isSubMenuActive()){
                    this.setItem()
                }
            }.bind(this), 10)

        })

    },

    removeMouseMoveListener: function() {
        if (this.onWindowMouseMove){
            window.removeEventListener('mousemove', this.onWindowMouseMove)
            this.onWindowMouseMove = null
        }
    },

    onMenuItemMouseOut: function(itemProps, leaveOffset) {
        if (this.state.menu){
            this.setupCheck(leaveOffset)
        }
    },

    /**
     * Called when mouseout happens on the item for which there is a submenu displayed
     */
    onMenuItemMouseOver: function(itemProps, menuOffset, entryPoint) {

        if (!this.didMount){
            return
        }

        var menu = itemProps.menu
        var ts   = +new Date()

        if (!menu){
            return
        }

        if (!this.state.menu){
            //there is no menu visible, so it's safe to show the menu
            this.setItem(itemProps, menuOffset)
        } else {
            //there is a menu visible, from the previous item that had mouse over
            //so we should queue this item's menu as the next menu to be shown
            this.setNextItem(itemProps, menuOffset)
        }
    },

    setupCheck: function(offset){
        if (!this.didMount){
            return
        }

        var tolerance = 5

        var domNode    = this.getDOMNode()
        var menuNode   = domNode.querySelector('.z-menu')

        if (!menuNode){
            return
        }

        var menuRegion = Region.from(menuNode)

        var x1 = menuRegion.left
        var y1 = menuRegion.top// - tolerance

        var x2 = menuRegion.left
        var y2 = menuRegion.bottom// + tolerance

        if (this.subMenuPosition == 'left'){
            x1 = menuRegion.right
            x2 = menuRegion.right
        }

        var x3 = offset.x + (this.subMenuPosition == 'left'? tolerance: -tolerance)
        var y3 = offset.y

        var triangle = [
            [x1, y1],
            [x2, y2],
            [x3, y3]
        ]

        this.removeMouseMoveListener()

        this.onWindowMouseMove = function(event){

            var point = [event.pageX, event.pageY]

            if (!inTriangle(point, triangle)){

                this.removeMouseMoveListener()

                if (!this.state.mouseOverSubMenu){
                    //the mouse is not over a sub menu item
                    //
                    //so we show a menu of a sibling item, or hide the menu
                    //if no sibling item visited
                    this.setItem(this.state.nextItem, this.state.nextOffset)
                }
            }
        }.bind(this)

        window.addEventListener('mousemove', this.onWindowMouseMove)
    },

    setNextItem: function(itemProps, menuOffset) {

        var ts = +new Date()

        this.setState({
            timestamp        : ts,

            nextItem     : itemProps,
            nextOffset   : menuOffset,
            nextTimestamp: +new Date()
        })
    },

    setItem: function(itemProps, offset) {

        var menu = itemProps?
                        itemProps.menu:
                        null

        // if (!menu){
        //     return
        // }

        this.removeMouseMoveListener()

        if (!this.didMount){
            return
        }

        if (!menu && !this.state.mouseInside){
            this.onInactivate()
        }

        this.setState({
            itemProps    : itemProps,

            menu         : menu,
            menuOffset   : offset,
            timestamp    : +new Date(),

            nextItem     : null,
            nextOffset   : null,
            nextTimestamp: null
        })
    },

    onMenuItemExpanderClick: function(event) {
        event.nativeEvent.expanderClick = true
    },

    onMenuItemClick: function(event, props, index) {

        var stopped = event.isPropagationStopped()

        this.props.stopClickPropagation && event.stopPropagation()

        if (hasTouch && props && event && event.nativeEvent && event.nativeEvent.expanderClick){

            var offset = {
                x: event.pageX,
                y: event.pageY
            }

            var menuOffset = getMenuOffset(event.currentTarget)
            this.onMenuItemMouseOver(props, menuOffset, offset)

            return
        }

        if (!stopped){
            if (props){
                ;(this.props.onClick || emptyFn)(event, props, index)
            }

            this.onChildClick(event, props)
        }
    },

    onChildClick: function(event, props) {
        ;(this.props.onChildClick || emptyFn)(event, props)

        if (this.props.parentMenu){
            this.props.parentMenu.onChildClick(event, props)
        }
    }
})

MenuClass.themes = require('./MenuItem/themes')

module.exports = MenuClass