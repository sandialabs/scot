/**
 * <TextareaAutosize />
 */

'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _createClass = (function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ('value' in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; })();

var _get = function get(_x, _x2, _x3) { var _again = true; _function: while (_again) { var object = _x, property = _x2, receiver = _x3; desc = parent = getter = undefined; _again = false; if (object === null) object = Function.prototype; var desc = Object.getOwnPropertyDescriptor(object, property); if (desc === undefined) { var parent = Object.getPrototypeOf(object); if (parent === null) { return undefined; } else { _x = parent; _x2 = property; _x3 = receiver; _again = true; continue _function; } } else if ('value' in desc) { return desc.value; } else { var getter = desc.get; if (getter === undefined) { return undefined; } return getter.call(receiver); } } };

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

function _objectWithoutProperties(obj, keys) { var target = {}; for (var i in obj) { if (keys.indexOf(i) >= 0) continue; if (!Object.prototype.hasOwnProperty.call(obj, i)) continue; target[i] = obj[i]; } return target; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError('Cannot call a class as a function'); } }

function _inherits(subClass, superClass) { if (typeof superClass !== 'function' && superClass !== null) { throw new TypeError('Super expression must either be null or a function, not ' + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _calculateNodeHeight = require('./calculateNodeHeight');

var _calculateNodeHeight2 = _interopRequireDefault(_calculateNodeHeight);

var emptyFunction = function emptyFunction() {};

var TextareaAutosize = (function (_React$Component) {
  _inherits(TextareaAutosize, _React$Component);

  _createClass(TextareaAutosize, null, [{
    key: 'propTypes',
    value: {
      /**
       * Current textarea value.
       */
      value: _react2['default'].PropTypes.string,

      /**
       * Callback on value change.
       */
      onChange: _react2['default'].PropTypes.func,

      /**
       * Callback on height changes.
       */
      onHeightChange: _react2['default'].PropTypes.func,

      /**
       * Try to cache DOM measurements performed by component so that we don't
       * touch DOM when it's not needed.
       *
       * This optimization doesn't work if we dynamically style <textarea />
       * component.
       */
      useCacheForDOMMeasurements: _react2['default'].PropTypes.bool,

      /**
       * Minimal numbder of rows to show.
       */
      rows: _react2['default'].PropTypes.number,

      /**
       * Alias for `rows`.
       */
      minRows: _react2['default'].PropTypes.number,

      /**
       * Maximum number of rows to show.
       */
      maxRows: _react2['default'].PropTypes.number
    },
    enumerable: true
  }, {
    key: 'defaultProps',
    value: {
      onChange: emptyFunction,
      onHeightChange: emptyFunction,
      useCacheForDOMMeasurements: false
    },
    enumerable: true
  }]);

  function TextareaAutosize(props) {
    _classCallCheck(this, TextareaAutosize);

    _get(Object.getPrototypeOf(TextareaAutosize.prototype), 'constructor', this).call(this, props);
    this.state = {
      height: null,
      minHeight: -Infinity,
      maxHeight: Infinity
    };
    this._onNextFrameActionId = null;
    this._rootDOMNode = null;
    this._onChange = this._onChange.bind(this);
    this._resizeComponent = this._resizeComponent.bind(this);
    this._onRootDOMNode = this._onRootDOMNode.bind(this);
  }

  _createClass(TextareaAutosize, [{
    key: 'render',
    value: function render() {
      var _props = this.props;
      var valueLink = _props.valueLink;
      var onChange = _props.onChange;

      var props = _objectWithoutProperties(_props, ['valueLink', 'onChange']);

      props = _extends({}, props);
      if (typeof valueLink === 'object') {
        props.value = this.props.valueLink.value;
      }
      props.style = _extends({}, props.style, {
        height: this.state.height
      });
      var maxHeight = Math.max(props.style.maxHeight ? props.style.maxHeight : Infinity, this.state.maxHeight);
      if (maxHeight < this.state.height) {
        props.style.overflow = 'hidden';
      }
      return _react2['default'].createElement('textarea', _extends({}, props, {
        onChange: this._onChange,
        ref: this._onRootDOMNode
      }));
    }
  }, {
    key: 'componentDidMount',
    value: function componentDidMount() {
      this._resizeComponent();
      window.addEventListener('resize', this._resizeComponent);
    }
  }, {
    key: 'componentWillReceiveProps',
    value: function componentWillReceiveProps() {
      // Re-render with the new content then recalculate the height as required.
      this._clearNextFrame();
      this._onNextFrameActionId = onNextFrame(this._resizeComponent);
    }
  }, {
    key: 'componentDidUpdate',
    value: function componentDidUpdate(prevProps, prevState) {
      // Invoke callback when old height does not equal to new one.
      if (this.state.height !== prevState.height) {
        this.props.onHeightChange(this.state.height);
      }
    }
  }, {
    key: 'componentWillUnmount',
    value: function componentWillUnmount() {
      // Remove any scheduled events to prevent manipulating the node after it's
      // been unmounted.
      this._clearNextFrame();
      window.removeEventListener('resize', this._resizeComponent);
    }
  }, {
    key: '_clearNextFrame',
    value: function _clearNextFrame() {
      if (this._onNextFrameActionId) {
        clearNextFrameAction(this._onNextFrameActionId);
      }
    }
  }, {
    key: '_onRootDOMNode',
    value: function _onRootDOMNode(node) {
      this._rootDOMNode = node;
    }
  }, {
    key: '_onChange',
    value: function _onChange(e) {
      this._resizeComponent();
      var _props2 = this.props;
      var valueLink = _props2.valueLink;
      var onChange = _props2.onChange;

      if (valueLink) {
        valueLink.requestChange(e.target.value);
      } else {
        onChange(e);
      }
    }
  }, {
    key: '_resizeComponent',
    value: function _resizeComponent() {
      var useCacheForDOMMeasurements = this.props.useCacheForDOMMeasurements;

      this.setState((0, _calculateNodeHeight2['default'])(this._rootDOMNode, useCacheForDOMMeasurements, this.props.rows || this.props.minRows, this.props.maxRows));
    }

    /**
     * Read the current value of <textarea /> from DOM.
     */
  }, {
    key: 'focus',

    /**
     * Put focus on a <textarea /> DOM element.
     */
    value: function focus() {
      this._rootDOMNode.focus();
    }

    /**
     * Shifts focus away from a <textarea /> DOM element.
     */
  }, {
    key: 'blur',
    value: function blur() {
      this._rootDOMNode.blur();
    }
  }, {
    key: 'value',
    get: function get() {
      return this._rootDOMNode.value;
    },

    /**
     * Set the current value of <textarea /> DOM node.
     */
    set: function set(val) {
      this._rootDOMNode.value = val;
    }

    /**
     * Read the current selectionStart of <textarea /> from DOM.
     */
  }, {
    key: 'selectionStart',
    get: function get() {
      return this._rootDOMNode.selectionStart;
    },

    /**
     * Set the current selectionStart of <textarea /> DOM node.
     */
    set: function set(val) {
      this._rootDOMNode.selectionStart = val;
    }

    /**
     * Read the current selectionEnd of <textarea /> from DOM.
     */
  }, {
    key: 'selectionEnd',
    get: function get() {
      return this._rootDOMNode.selectionEnd;
    },

    /**
     * Set the current selectionEnd of <textarea /> DOM node.
     */
    set: function set(val) {
      this._rootDOMNode.selectionEnd = val;
    }
  }]);

  return TextareaAutosize;
})(_react2['default'].Component);

exports['default'] = TextareaAutosize;

function onNextFrame(cb) {
  if (window.requestAnimationFrame) {
    return window.requestAnimationFrame(cb);
  }
  return window.setTimeout(cb, 1);
}

function clearNextFrameAction(nextFrameId) {
  if (window.cancelAnimationFrame) {
    window.cancelAnimationFrame(nextFrameId);
  } else {
    window.clearTimeout(nextFrameId);
  }
}
module.exports = exports['default'];
