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

var _startCase2 = require('lodash/startCase');

var _startCase3 = _interopRequireDefault(_startCase2);

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
 * A menu can contain an item.
 */
var MenuItem = function (_Component) {
  (0, _inherits3.default)(MenuItem, _Component);

  function MenuItem() {
    var _ref;

    var _temp, _this, _ret;

    (0, _classCallCheck3.default)(this, MenuItem);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, (_ref = MenuItem.__proto__ || Object.getPrototypeOf(MenuItem)).call.apply(_ref, [this].concat(args))), _this), _this.handleClick = function (e) {
      var onClick = _this.props.onClick;


      if (onClick) onClick(e, _this.props);
    }, _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
  }

  (0, _createClass3.default)(MenuItem, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          active = _props.active,
          children = _props.children,
          className = _props.className,
          color = _props.color,
          content = _props.content,
          disabled = _props.disabled,
          fitted = _props.fitted,
          header = _props.header,
          icon = _props.icon,
          link = _props.link,
          name = _props.name,
          onClick = _props.onClick,
          position = _props.position;


      var classes = (0, _classnames2.default)(color, position, (0, _lib.useKeyOnly)(active, 'active'), (0, _lib.useKeyOnly)(disabled, 'disabled'), (0, _lib.useKeyOnly)(icon === true || icon && !(name || content), 'icon'), (0, _lib.useKeyOnly)(header, 'header'), (0, _lib.useKeyOnly)(link, 'link'), (0, _lib.useKeyOrValueAndKey)(fitted, 'fitted'), 'item', className);
      var ElementType = (0, _lib.getElementType)(MenuItem, this.props, function () {
        if (onClick) return 'a';
      });
      var rest = (0, _lib.getUnhandledProps)(MenuItem, this.props);

      if (!(0, _isNil3.default)(children)) {
        return _react2.default.createElement(
          ElementType,
          (0, _extends3.default)({}, rest, { className: classes, onClick: this.handleClick }),
          children
        );
      }

      return _react2.default.createElement(
        ElementType,
        (0, _extends3.default)({}, rest, { className: classes, onClick: this.handleClick }),
        _Icon2.default.create(icon),
        content || (0, _startCase3.default)(name)
      );
    }
  }]);
  return MenuItem;
}(_react.Component);

MenuItem._meta = {
  name: 'MenuItem',
  type: _lib.META.TYPES.COLLECTION,
  parent: 'Menu'
};
exports.default = MenuItem;
process.env.NODE_ENV !== "production" ? MenuItem.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** A menu item can be active. */
  active: _react.PropTypes.bool,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Additional colors can be specified. */
  color: _react.PropTypes.oneOf(_lib.SUI.COLORS),

  /** Shorthand for primary content. */
  content: _lib.customPropTypes.contentShorthand,

  /** A menu item can be disabled. */
  disabled: _react.PropTypes.bool,

  /** A menu item or menu can remove element padding, vertically or horizontally. */
  fitted: _react.PropTypes.oneOfType([_react.PropTypes.bool, _react.PropTypes.oneOf(['horizontally', 'vertically'])]),

  /** A menu item may include a header or may itself be a header. */
  header: _react.PropTypes.bool,

  /** MenuItem can be only icon. */
  icon: _react.PropTypes.oneOfType([_react.PropTypes.bool, _lib.customPropTypes.itemShorthand]),

  /** MenuItem index inside Menu. */
  index: _react.PropTypes.number,

  /** A menu item can be link. */
  link: _react.PropTypes.bool,

  /** Internal name of the MenuItem. */
  name: _react.PropTypes.string,

  /**
   * Called on click. When passed, the component will render as an `a`
   * tag by default instead of a `div`.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onClick: _react.PropTypes.func,

  /** A menu item can take right position. */
  position: _react.PropTypes.oneOf(['right'])
} : void 0;
MenuItem.handledProps = ['active', 'as', 'children', 'className', 'color', 'content', 'disabled', 'fitted', 'header', 'icon', 'index', 'link', 'name', 'onClick', 'position'];


MenuItem.create = (0, _lib.createShorthandFactory)(MenuItem, function (val) {
  return { content: val, name: val };
}, true);