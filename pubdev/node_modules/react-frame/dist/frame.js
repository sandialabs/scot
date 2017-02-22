'use strict';

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var blacklist = require('blacklist');
var React = require('react');
var ReactDOM = require('react-dom');

var Frame = function (_React$Component) {
  _inherits(Frame, _React$Component);

  function Frame() {
    _classCallCheck(this, Frame);

    return _possibleConstructorReturn(this, (Frame.__proto__ || Object.getPrototypeOf(Frame)).apply(this, arguments));
  }

  _createClass(Frame, [{
    key: 'componentWillReceiveProps',
    value: function componentWillReceiveProps(nextProps) {
      if (nextProps.styleSheets.join('') !== this.props.styleSheets.join('')) {
        this.updateStylesheets(nextProps.styleSheets);
      }

      if (nextProps.css !== this.props.css) {
        this.updateCss(nextProps.css);
      }

      var frame = ReactDOM.findDOMNode(this);
      ReactDOM.render(nextProps.children, frame.contentDocument.getElementById('root'));
    }
  }, {
    key: 'componentDidMount',
    value: function componentDidMount() {
      setTimeout(this.renderFrame.bind(this), 0);
    }
  }, {
    key: 'componentWillUnmount',
    value: function componentWillUnmount() {
      ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this).contentDocument.getElementById('root'));
    }
  }, {
    key: 'updateStylesheets',
    value: function updateStylesheets(styleSheets) {
      var _this2 = this;

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
          _this2.head.appendChild(link);
        });
      }
    }
  }, {
    key: 'updateCss',
    value: function updateCss(css) {
      if (!this.styleEl) {
        var _el = document.createElement('style');
        _el.type = 'text/css';
        this.head.appendChild(_el);
        this.styleEl = _el;
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
    }
  }, {
    key: 'renderFrame',
    value: function renderFrame() {
      var _props = this.props,
          styleSheets = _props.styleSheets,
          css = _props.css;

      var frame = ReactDOM.findDOMNode(this);
      var root = document.createElement('div');

      root.setAttribute('id', 'root');

      this.head = frame.contentDocument.head;
      this.body = frame.contentDocument.body;
      this.body.appendChild(root);

      this.updateStylesheets(styleSheets);
      this.updateCss(css);

      ReactDOM.render(this._children, root);
    }
  }, {
    key: 'render',
    value: function render() {
      this._children = this.props.children;
      // render children manually
      var props = blacklist(this.props, 'children', 'styleSheets', 'css');
      return React.createElement('iframe', _extends({}, props, { onLoad: this.renderFrame }));
    }
  }]);

  return Frame;
}(React.Component);

module.exports = Frame;