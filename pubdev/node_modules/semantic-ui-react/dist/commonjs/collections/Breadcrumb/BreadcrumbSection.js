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

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A section sub-component for Breadcrumb component.
 */
var BreadcrumbSection = function (_Component) {
  (0, _inherits3.default)(BreadcrumbSection, _Component);

  function BreadcrumbSection() {
    var _ref;

    var _temp, _this, _ret;

    (0, _classCallCheck3.default)(this, BreadcrumbSection);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, (_ref = BreadcrumbSection.__proto__ || Object.getPrototypeOf(BreadcrumbSection)).call.apply(_ref, [this].concat(args))), _this), _this.handleClick = function (e) {
      var onClick = _this.props.onClick;


      if (onClick) onClick(e, _this.props);
    }, _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
  }

  (0, _createClass3.default)(BreadcrumbSection, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          active = _props.active,
          children = _props.children,
          className = _props.className,
          content = _props.content,
          href = _props.href,
          link = _props.link,
          onClick = _props.onClick;


      var classes = (0, _classnames2.default)((0, _lib.useKeyOnly)(active, 'active'), 'section', className);
      var rest = (0, _lib.getUnhandledProps)(BreadcrumbSection, this.props);
      var ElementType = (0, _lib.getElementType)(BreadcrumbSection, this.props, function () {
        if (link || onClick) return 'a';
      });

      return _react2.default.createElement(
        ElementType,
        (0, _extends3.default)({}, rest, { className: classes, href: href, onClick: this.handleClick }),
        (0, _isNil3.default)(children) ? content : children
      );
    }
  }]);
  return BreadcrumbSection;
}(_react.Component);

BreadcrumbSection._meta = {
  name: 'BreadcrumbSection',
  type: _lib.META.TYPES.COLLECTION,
  parent: 'Breadcrumb'
};
exports.default = BreadcrumbSection;
process.env.NODE_ENV !== "production" ? BreadcrumbSection.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Style as the currently active section. */
  active: _react.PropTypes.bool,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Shorthand for primary content. */
  content: _lib.customPropTypes.contentShorthand,

  /** Render as an `a` tag instead of a `div` and adds the href attribute. */
  href: _lib.customPropTypes.every([_lib.customPropTypes.disallow(['link']), _react.PropTypes.string]),

  /** Render as an `a` tag instead of a `div`. */
  link: _lib.customPropTypes.every([_lib.customPropTypes.disallow(['href']), _react.PropTypes.bool]),

  /**
   * Called on click. When passed, the component will render as an `a`
   * tag by default instead of a `div`.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onClick: _react.PropTypes.func
} : void 0;
BreadcrumbSection.handledProps = ['active', 'as', 'children', 'className', 'content', 'href', 'link', 'onClick'];


BreadcrumbSection.create = (0, _lib.createShorthandFactory)(BreadcrumbSection, function (content) {
  return { content: content, link: true };
}, true);