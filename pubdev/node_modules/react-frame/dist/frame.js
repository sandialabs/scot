'use strict';

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var blacklist = require('blacklist');
var React = require('react');
var ReactDOM = require('react-dom');

module.exports = React.createClass({
  displayName: 'Frame',

  render: function render() {
    this._children = this.props.children;
    // render children manually
    var props = blacklist(this.props, 'children');
    return React.createElement('iframe', _extends({}, props, { onLoad: this.renderFrame }));
  },
  updateStylesheets: function updateStylesheets(styleSheets) {
    var _this = this;

    var links = this.head.querySelectorAll('link');
    for (var i = 0, l = links.length; i < l; i++) {
      var link = links[i];
      link.parentNode.removeChild(link);
    }

    if (styleSheets && styleSheets.length) {
      styleSheets.forEach(function (href) {
        var link = document.createElement('link');
        link.setAttribute('rel', 'stylesheet');
        link.setAttribute('type', 'text/css');
        link.setAttribute('href', href);
        _this.head.appendChild(link);
      });
    }
  },
  updateCss: function updateCss(css) {
    if (!this.styleEl) {
      var el = document.createElement('style');
      el.type = 'text/css';
      this.head.appendChild(el);
      this.styleEl = el;
    }

    var el = this.styleEl;

    if (el.styleSheet) {
      el.styleSheet.cssText = css;
    } else {
      var cssNode = document.createTextNode(css);
      if (this.cssNode) el.removeChild(this.cssNode);
      el.appendChild(cssNode);
      this.cssNode = cssNode;
    }
  },
  renderFrame: function renderFrame() {
    var frame = ReactDOM.findDOMNode(this);
    this.head = frame.contentDocument.head;
    this.body = frame.contentDocument.body;

    this.updateStylesheets(this.props.styleSheets);
    this.updateCss(this.props.css);

    ReactDOM.render(this._children, this.body);
  },
  componentDidMount: function componentDidMount() {
    setTimeout(this.renderFrame, 0);
  },
  componentWillReceiveProps: function componentWillReceiveProps(nextProps) {
    if (nextProps.styleSheets.join('') !== this.props.styleSheets.join('')) {
      this.updateStylesheets(nextProps.styleSheets);
    }

    if (nextProps.css !== this.props.css) {
      this.updateCss(nextProps.css);
    }

    var frame = ReactDOM.findDOMNode(this);
    ReactDOM.render(nextProps.children, frame.contentDocument.body);
  },
  componentWillUnmount: function componentWillUnmount() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this).contentDocument.body);
  }
});