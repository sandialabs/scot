"use strict";

var React = require('react');
var ReactDOM = require('react-dom');
var util = require('dom-find');
var SimplePageScrollMixin = {
    componentDidMount: function () {
        window.addEventListener('scroll', this.onScroll, false);
    },
    componentWillUnmount: function () {
        window.removeEventListener('scroll', this.onScroll, false);
    }
};
var SimpleResizeMixin = {
    componentDidMount: function() {
        window.addEventListener('resize', this.handleResize);
    },

    componentWillUnmount: function() {
        window.removeEventListener('resize', this.handleResize);
    }
};

var StickyDiv = React.createClass({
    mixins: [SimplePageScrollMixin, SimpleResizeMixin],
    displayName:"StickyDiv",
    propTypes:{
        offsetTop: React.PropTypes.number,
        zIndex: React.PropTypes.number,
        className: React.PropTypes.string
    },
    getInitialState : function(){
        return {
            fix: false,
            width: null
        };
    },
    getDefaultProps: function() {
        return {
            offsetTop: 0,
            className: '',
            zIndex: 9999
        };
    },
    handleResize : function(){
        this.checkWidth();
        this.checkPositions();
    },
    onScroll: function () {
        this.checkWidth();
        this.checkPositions();
    },
    checkPositions: function(){
        var pos = util.findPosRelativeToViewport(ReactDOM.findDOMNode(this));

        if (pos[1]<=this.props.offsetTop){
            this.setState({fix: true});
        } else {
            this.setState({fix: false});
        }
    },
    checkWidth: function () {
        var width = null;
        if (this.refs.duplicate) {
            width = this.refs.duplicate.getBoundingClientRect().width;
        } else {
            width = this.refs.original.getBoundingClientRect().width;
        }
        if (this.state.width !== width) {
            this.setState({
                width: width
            });
        }
    },
    componentDidMount: function () {
        this.checkWidth();
    },
    render: function () {
        var divStyle;

        if (this.state.fix) {
            divStyle = {
                display: 'block',
                position: 'fixed',
                width: this.state.width ? (this.state.width + 'px') : null,
                top: this.props.offsetTop
            };
            return <div style={{zIndex : this.props.zIndex, position:'relative', width:'100%'}}>
                <div ref='duplicate' key='duplicate' style={{visibility:'hidden'}}>
            {this.props.children}
                </div>
                <div ref='original' key='original' className={this.props.className} style={divStyle} >
            {this.props.children}
                </div>
            </div>;
        }
        else {
            divStyle = {
                display: 'block',
                position: 'relative'
            };
            return <div style={{zIndex : this.props.zIndex, position:'relative', width:'100%'}}>
                <div ref='original' key='original' style={divStyle}>
          {this.props.children}
                </div>
            </div>;
        }
    }
});

module.exports = StickyDiv;
