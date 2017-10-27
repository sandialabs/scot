'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.EXITING = exports.ENTERED = exports.ENTERING = exports.EXITED = exports.UNMOUNTED = undefined;

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _on = require('dom-helpers/events/on');

var _on2 = _interopRequireDefault(_on);

var _properties = require('dom-helpers/transition/properties');

var _properties2 = _interopRequireDefault(_properties);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _reactDom = require('react-dom');

var _reactDom2 = _interopRequireDefault(_reactDom);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) { var target = {}; for (var i in obj) { if (keys.indexOf(i) >= 0) continue; if (!Object.prototype.hasOwnProperty.call(obj, i)) continue; target[i] = obj[i]; } return target; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var transitionEndEvent = _properties2.default.end;

var UNMOUNTED = exports.UNMOUNTED = 0;
var EXITED = exports.EXITED = 1;
var ENTERING = exports.ENTERING = 2;
var ENTERED = exports.ENTERED = 3;
var EXITING = exports.EXITING = 4;

/**
 * The Transition component lets you define and run css transitions with a simple declarative api.
 * It works similar to React's own [CSSTransitionGroup](http://facebook.github.io/react/docs/animation.html#high-level-api-reactcsstransitiongroup)
 * but is specifically optimized for transitioning a single child "in" or "out".
 *
 * You don't even need to use class based css transitions if you don't want to (but it is easiest).
 * The extensive set of lifecycle callbacks means you have control over
 * the transitioning now at each step of the way.
 */

var Transition = function (_React$Component) {
  _inherits(Transition, _React$Component);

  function Transition(props, context) {
    _classCallCheck(this, Transition);

    var _this = _possibleConstructorReturn(this, (Transition.__proto__ || Object.getPrototypeOf(Transition)).call(this, props, context));

    var initialStatus = void 0;
    _this.nextStatus = null;

    if (props.in) {
      if (props.transitionAppear) {
        initialStatus = EXITED;
        _this.nextStatus = ENTERING;
      } else {
        initialStatus = ENTERED;
      }
    } else {
      if (props.unmountOnExit || props.mountOnEnter) {
        initialStatus = UNMOUNTED;
      } else {
        initialStatus = EXITED;
      }
    }

    _this.state = { status: initialStatus };

    _this.nextCallback = null;
    return _this;
  }

  _createClass(Transition, [{
    key: 'componentDidMount',
    value: function componentDidMount() {
      this.updateStatus();
    }
  }, {
    key: 'componentWillReceiveProps',
    value: function componentWillReceiveProps(nextProps) {
      var status = this.state.status;


      if (nextProps.in) {
        if (status === UNMOUNTED) {
          this.setState({ status: EXITED });
        }
        if (status !== ENTERING && status !== ENTERED) {
          this.nextStatus = ENTERING;
        }
      } else {
        if (status === ENTERING || status === ENTERED) {
          this.nextStatus = EXITING;
        }
      }
    }
  }, {
    key: 'componentDidUpdate',
    value: function componentDidUpdate() {
      this.updateStatus();
    }
  }, {
    key: 'componentWillUnmount',
    value: function componentWillUnmount() {
      this.cancelNextCallback();
    }
  }, {
    key: 'updateStatus',
    value: function updateStatus() {
      var _this2 = this;

      if (this.nextStatus !== null) {
        // nextStatus will always be ENTERING or EXITING.
        this.cancelNextCallback();
        var node = _reactDom2.default.findDOMNode(this);

        if (this.nextStatus === ENTERING) {
          this.props.onEnter(node);

          this.safeSetState({ status: ENTERING }, function () {
            _this2.props.onEntering(node);

            _this2.onTransitionEnd(node, function () {
              _this2.safeSetState({ status: ENTERED }, function () {
                _this2.props.onEntered(node);
              });
            });
          });
        } else {
          this.props.onExit(node);

          this.safeSetState({ status: EXITING }, function () {
            _this2.props.onExiting(node);

            _this2.onTransitionEnd(node, function () {
              _this2.safeSetState({ status: EXITED }, function () {
                _this2.props.onExited(node);
              });
            });
          });
        }

        this.nextStatus = null;
      } else if (this.props.unmountOnExit && this.state.status === EXITED) {
        this.setState({ status: UNMOUNTED });
      }
    }
  }, {
    key: 'cancelNextCallback',
    value: function cancelNextCallback() {
      if (this.nextCallback !== null) {
        this.nextCallback.cancel();
        this.nextCallback = null;
      }
    }
  }, {
    key: 'safeSetState',
    value: function safeSetState(nextState, callback) {
      // This shouldn't be necessary, but there are weird race conditions with
      // setState callbacks and unmounting in testing, so always make sure that
      // we can cancel any pending setState callbacks after we unmount.
      this.setState(nextState, this.setNextCallback(callback));
    }
  }, {
    key: 'setNextCallback',
    value: function setNextCallback(callback) {
      var _this3 = this;

      var active = true;

      this.nextCallback = function (event) {
        if (active) {
          active = false;
          _this3.nextCallback = null;

          callback(event);
        }
      };

      this.nextCallback.cancel = function () {
        active = false;
      };

      return this.nextCallback;
    }
  }, {
    key: 'onTransitionEnd',
    value: function onTransitionEnd(node, handler) {
      this.setNextCallback(handler);

      if (node) {
        (0, _on2.default)(node, transitionEndEvent, this.nextCallback);
        setTimeout(this.nextCallback, this.props.timeout);
      } else {
        setTimeout(this.nextCallback, 0);
      }
    }
  }, {
    key: 'render',
    value: function render() {
      var status = this.state.status;
      if (status === UNMOUNTED) {
        return null;
      }

      var _props = this.props,
          children = _props.children,
          className = _props.className,
          childProps = _objectWithoutProperties(_props, ['children', 'className']);

      Object.keys(Transition.propTypes).forEach(function (key) {
        return delete childProps[key];
      });

      var transitionClassName = void 0;
      if (status === EXITED) {
        transitionClassName = this.props.exitedClassName;
      } else if (status === ENTERING) {
        transitionClassName = this.props.enteringClassName;
      } else if (status === ENTERED) {
        transitionClassName = this.props.enteredClassName;
      } else if (status === EXITING) {
        transitionClassName = this.props.exitingClassName;
      }

      var child = _react2.default.Children.only(children);
      return _react2.default.cloneElement(child, _extends({}, childProps, {
        className: (0, _classnames2.default)(child.props.className, className, transitionClassName)
      }));
    }
  }]);

  return Transition;
}(_react2.default.Component);

Transition.propTypes = {
  /**
   * Show the component; triggers the enter or exit animation
   */
  in: _react2.default.PropTypes.bool,

  /**
   * Wait until the first "enter" transition to mount the component (add it to the DOM)
   */
  mountOnEnter: _react2.default.PropTypes.bool,

  /**
   * Unmount the component (remove it from the DOM) when it is not shown
   */
  unmountOnExit: _react2.default.PropTypes.bool,

  /**
   * Run the enter animation when the component mounts, if it is initially
   * shown
   */
  transitionAppear: _react2.default.PropTypes.bool,

  /**
   * A Timeout for the animation, in milliseconds, to ensure that a node doesn't
   * transition indefinately if the browser transitionEnd events are
   * canceled or interrupted.
   *
   * By default this is set to a high number (5 seconds) as a failsafe. You should consider
   * setting this to the duration of your animation (or a bit above it).
   */
  timeout: _react2.default.PropTypes.number,

  /**
   * CSS class or classes applied when the component is exited
   */
  exitedClassName: _react2.default.PropTypes.string,
  /**
   * CSS class or classes applied while the component is exiting
   */
  exitingClassName: _react2.default.PropTypes.string,
  /**
   * CSS class or classes applied when the component is entered
   */
  enteredClassName: _react2.default.PropTypes.string,
  /**
   * CSS class or classes applied while the component is entering
   */
  enteringClassName: _react2.default.PropTypes.string,

  /**
   * Callback fired before the "entering" classes are applied
   */
  onEnter: _react2.default.PropTypes.func,
  /**
   * Callback fired after the "entering" classes are applied
   */
  onEntering: _react2.default.PropTypes.func,
  /**
   * Callback fired after the "enter" classes are applied
   */
  onEntered: _react2.default.PropTypes.func,
  /**
   * Callback fired before the "exiting" classes are applied
   */
  onExit: _react2.default.PropTypes.func,
  /**
   * Callback fired after the "exiting" classes are applied
   */
  onExiting: _react2.default.PropTypes.func,
  /**
   * Callback fired after the "exited" classes are applied
   */
  onExited: _react2.default.PropTypes.func
};

// Name the function so it is clearer in the documentation
function noop() {}

Transition.displayName = 'Transition';

Transition.defaultProps = {
  in: false,
  unmountOnExit: false,
  transitionAppear: false,

  timeout: 5000,

  onEnter: noop,
  onEntering: noop,
  onEntered: noop,

  onExit: noop,
  onExiting: noop,
  onExited: noop
};

exports.default = Transition;