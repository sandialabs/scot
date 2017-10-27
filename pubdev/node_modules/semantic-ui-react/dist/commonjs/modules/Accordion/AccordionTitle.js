'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = require('babel-runtime/helpers/createClass');

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

var _isNil2 = require('lodash/isNil');

var _isNil3 = _interopRequireDefault(_isNil2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _Icon = require('../../elements/Icon');

var _Icon2 = _interopRequireDefault(_Icon);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A title sub-component for Accordion component.
 */
var AccordionTitle = function (_Component) {
  (0, _inherits3.default)(AccordionTitle, _Component);

  function AccordionTitle() {
    var _ref;

    var _temp, _this, _ret;

    (0, _classCallCheck3.default)(this, AccordionTitle);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, (_ref = AccordionTitle.__proto__ || Object.getPrototypeOf(AccordionTitle)).call.apply(_ref, [this].concat(args))), _this), _this.handleClick = function (e) {
      var onClick = _this.props.onClick;


      if (onClick) onClick(e, _this.props);
    }, _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
  }

  (0, _createClass3.default)(AccordionTitle, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          active = _props.active,
          children = _props.children,
          className = _props.className,
          content = _props.content;


      var classes = (0, _classnames2.default)((0, _lib.useKeyOnly)(active, 'active'), 'title', className);
      var rest = (0, _lib.getUnhandledProps)(AccordionTitle, this.props);
      var ElementType = (0, _lib.getElementType)(AccordionTitle, this.props);

      if ((0, _isNil3.default)(content)) {
        return _react2.default.createElement(
          ElementType,
          (0, _extends3.default)({}, rest, { className: classes, onClick: this.handleClick }),
          children
        );
      }

      return _react2.default.createElement(
        ElementType,
        (0, _extends3.default)({}, rest, { className: classes, onClick: this.handleClick }),
        _react2.default.createElement(_Icon2.default, { name: 'dropdown' }),
        content
      );
    }
  }]);
  return AccordionTitle;
}(_react.Component);

AccordionTitle._meta = {
  name: 'AccordionTitle',
  type: _lib.META.TYPES.MODULE,
  parent: 'Accordion'
};
exports.default = AccordionTitle;
process.env.NODE_ENV !== "production" ? AccordionTitle.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Whether or not the title is in the open state. */
  active: _react.PropTypes.bool,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Shorthand for primary content. */
  content: _lib.customPropTypes.contentShorthand,

  /**
   * Called on click.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onClick: _react.PropTypes.func
} : void 0;
AccordionTitle.handledProps = ['active', 'as', 'children', 'className', 'content', 'onClick'];


AccordionTitle.create = (0, _lib.createShorthandFactory)(AccordionTitle, function (content) {
  return { content: content };
});