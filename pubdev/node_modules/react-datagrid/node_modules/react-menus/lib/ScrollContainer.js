'use strict';

var _reactDom = require('react-dom');

var React = require('react');
var assign = require('object-assign');
var buffer = require('buffer-function');

var Scroller = require('./Scroller');

function stop(event) {
    event.preventDefault();
    event.stopPropagation();
}

module.exports = React.createClass({

    displayName: 'ReactMenuScrollContainer',

    getInitialState: function getInitialState() {
        return {
            adjustScroll: true,
            scrollPos: 0
        };
    },

    getDefaultProps: function getDefaultProps() {
        return {
            scrollStep: 5,
            scrollSpeed: 50
        };
    },

    componentWillUnmount: function componentWillUnmount() {
        if (this.props.enableScroll) {
            window.removeEventListener('resize', this.onResizeListener);
        }
    },

    componentDidMount: function componentDidMount() {
        if (this.props.enableScroll) {
            setTimeout((function () {
                if (!this.isMounted()) {
                    return;
                }

                this.adjustScroll();

                window.addEventListener('resize', this.onResizeListener = buffer(this.onWindowResize, this.props.onWindowResizeBuffer, this));
            }).bind(this), 0);
        }
    },

    componentDidUpdate: function componentDidUpdate() {
        this.props.enableScroll && this.adjustScroll();
    },

    onWindowResize: function onWindowResize() {
        this.adjustScroll();
        this.doScroll(0);
    },

    render: function render() {

        var props = this.props;
        var children = props.children;

        if (!props.enableScroll) {
            return children;
        }

        var scrollStyle = {
            position: 'relative'
        };

        if (this.state.scrollPos) {
            scrollStyle.top = -this.state.scrollPos;
        }

        var containerStyle = {
            position: 'relative',
            overflow: 'hidden'
        };

        if (props.maxHeight) {
            containerStyle.maxHeight = props.maxHeight;
        }

        return React.createElement(
            'div',
            {
                onMouseEnter: props.onMouseEnter,
                onMouseLeave: props.onMouseLeave,
                className: 'z-menu-scroll-container',
                style: containerStyle
            },
            React.createElement(
                'div',
                { ref: 'tableWrap', style: scrollStyle },
                children
            ),
            this.renderScroller(props, -1),
            this.renderScroller(props, 1)
        );
    },

    renderScroller: function renderScroller(props, direction) {

        var onMouseDown = direction == -1 ? this.handleScrollTop : this.handleScrollBottom;

        var onDoubleClick = direction == -1 ? this.handleScrollTopMax : this.handleScrollBottomMax;

        var visible = direction == -1 ? this.state.hasTopScroll : this.state.hasBottomScroll;

        var scrollerProps = assign({}, props.scrollerProps, {
            visible: visible,
            side: direction == -1 ? 'top' : 'bottom',
            onMouseDown: onMouseDown,
            onDoubleClick: onDoubleClick
        });

        return React.createElement(Scroller, scrollerProps);
    },

    adjustScroll: function adjustScroll() {
        if (!this.props.enableScroll) {
            return;
        }

        if (!this.state.adjustScroll) {
            this.state.adjustScroll = true;
            return;
        }

        var availableHeight = this.getAvailableHeight();
        var tableHeight = this.getCurrentTableHeight();

        var state = {
            adjustScroll: false,
            hasTopScroll: false,
            hasBottomScroll: false
        };

        if (tableHeight > availableHeight) {
            state.maxScrollPos = tableHeight - availableHeight;
            state.hasTopScroll = this.state.scrollPos !== 0;
            state.hasBottomScroll = this.state.scrollPos != state.maxScrollPos;
        } else {
            state.maxScrollPos = 0;
            state.scrollPos = 0;
        }

        this.setState(state);
    },

    getAvailableHeight: function getAvailableHeight() {
        return this.getAvailableSizeDOM().clientHeight;
    },

    getAvailableSizeDOM: function getAvailableSizeDOM() {
        return (0, _reactDom.findDOMNode)(this);
    },

    getCurrentTableHeight: function getCurrentTableHeight() {
        return this.getCurrentSizeDOM().clientHeight;
    },

    getCurrentSizeDOM: function getCurrentSizeDOM() {
        return (0, _reactDom.findDOMNode)(this.refs.tableWrap);
    },

    handleScrollTop: function handleScrollTop(event) {
        event.preventDefault();
        this.handleScroll(-1);
    },

    handleScrollBottom: function handleScrollBottom(event) {
        event.preventDefault();
        this.handleScroll(1);
    },

    handleScrollTopMax: function handleScrollTopMax(event) {
        stop(event);
        this.handleScrollMax(-1);
    },

    handleScrollBottomMax: function handleScrollBottomMax(event) {
        stop(event);
        this.handleScrollMax(1);
    },

    handleScrollMax: function handleScrollMax(direction) {
        var maxPos = direction == -1 ? 0 : this.state.maxScrollPos;

        this.setScrollPosition(maxPos);
    },

    handleScroll: function handleScroll(direction /*1 to bottom, -1 to up*/) {
        var mouseUpListener = (function () {
            this.stopScroll();
            window.removeEventListener('mouseup', mouseUpListener);
        }).bind(this);

        window.addEventListener('mouseup', mouseUpListener);

        this.scrollInterval = setInterval(this.doScroll.bind(this, direction), this.props.scrollSpeed);
    },

    doScroll: function doScroll(direction) {
        this.setState({
            scrollDirection: direction
        });

        var newScrollPos = this.state.scrollPos + direction * this.props.scrollStep;

        this.setScrollPosition(newScrollPos);
    },

    setScrollPosition: function setScrollPosition(scrollPos) {
        if (scrollPos > this.state.maxScrollPos) {
            scrollPos = this.state.maxScrollPos;
        }

        if (scrollPos < 0) {
            scrollPos = 0;
        }

        this.setState({
            scrollPos: scrollPos,
            scrolling: true
        });
    },

    stopScroll: function stopScroll() {
        clearInterval(this.scrollInterval);

        this.setState({
            scrolling: false
        });
    }
});