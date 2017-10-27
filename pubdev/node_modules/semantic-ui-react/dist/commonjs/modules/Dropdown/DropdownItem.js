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

var _Flag = require('../../elements/Flag');

var _Flag2 = _interopRequireDefault(_Flag);

var _Icon = require('../../elements/Icon');

var _Icon2 = _interopRequireDefault(_Icon);

var _Image = require('../../elements/Image');

var _Image2 = _interopRequireDefault(_Image);

var _Label = require('../../elements/Label');

var _Label2 = _interopRequireDefault(_Label);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * An item sub-component for Dropdown component.
 */
var DropdownItem = function (_Component) {
  (0, _inherits3.default)(DropdownItem, _Component);

  function DropdownItem() {
    var _ref;

    var _temp, _this, _ret;

    (0, _classCallCheck3.default)(this, DropdownItem);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, (_ref = DropdownItem.__proto__ || Object.getPrototypeOf(DropdownItem)).call.apply(_ref, [this].concat(args))), _this), _this.handleClick = function (e) {
      var onClick = _this.props.onClick;


      if (onClick) onClick(e, _this.props);
    }, _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
  }

  (0, _createClass3.default)(DropdownItem, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          active = _props.active,
          children = _props.children,
          className = _props.className,
          content = _props.content,
          disabled = _props.disabled,
          description = _props.description,
          flag = _props.flag,
          icon = _props.icon,
          image = _props.image,
          label = _props.label,
          selected = _props.selected,
          text = _props.text;


      var classes = (0, _classnames2.default)((0, _lib.useKeyOnly)(active, 'active'), (0, _lib.useKeyOnly)(disabled, 'disabled'), (0, _lib.useKeyOnly)(selected, 'selected'), 'item', className);
      // add default dropdown icon if item contains another menu
      var iconName = (0, _isNil3.default)(icon) ? _lib.childrenUtils.someByType(children, 'DropdownMenu') && 'dropdown' : icon;
      var rest = (0, _lib.getUnhandledProps)(DropdownItem, this.props);
      var ElementType = (0, _lib.getElementType)(DropdownItem, this.props);
      var ariaOptions = {
        role: 'option',
        'aria-disabled': disabled,
        'aria-checked': active,
        'aria-selected': selected
      };

      if (!(0, _isNil3.default)(children)) {
        return _react2.default.createElement(
          ElementType,
          (0, _extends3.default)({}, rest, ariaOptions, { className: classes, onClick: this.handleClick }),
          children
        );
      }

      var flagElement = _Flag2.default.create(flag);
      var iconElement = _Icon2.default.create(iconName);
      var imageElement = _Image2.default.create(image);
      var labelElement = _Label2.default.create(label);
      var descriptionElement = (0, _lib.createShorthand)('span', function (val) {
        return { children: val };
      }, description, function (props) {
        return { className: 'description' };
      });
      var textElement = (0, _lib.createShorthand)('span', function (val) {
        return { children: val };
      }, content || text, function (props) {
        return { className: 'text' };
      });

      return _react2.default.createElement(
        ElementType,
        (0, _extends3.default)({}, rest, ariaOptions, { className: classes, onClick: this.handleClick }),
        imageElement,
        iconElement,
        flagElement,
        labelElement,
        descriptionElement,
        textElement
      );
    }
  }]);
  return DropdownItem;
}(_react.Component);

DropdownItem._meta = {
  name: 'DropdownItem',
  parent: 'Dropdown',
  type: _lib.META.TYPES.MODULE
};
exports.default = DropdownItem;
process.env.NODE_ENV !== "production" ? DropdownItem.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Style as the currently chosen item. */
  active: _react.PropTypes.bool,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Shorthand for primary content. */
  content: _lib.customPropTypes.contentShorthand,

  /** Additional text with less emphasis. */
  description: _lib.customPropTypes.itemShorthand,

  /** A dropdown item can be disabled. */
  disabled: _react.PropTypes.bool,

  /** Shorthand for Flag. */
  flag: _lib.customPropTypes.itemShorthand,

  /** Shorthand for Icon. */
  icon: _lib.customPropTypes.itemShorthand,

  /** Shorthand for Image. */
  image: _lib.customPropTypes.itemShorthand,

  /** Shorthand for Label. */
  label: _lib.customPropTypes.itemShorthand,

  /**
   * Called on click.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onClick: _react.PropTypes.func,

  /**
   * The item currently selected by keyboard shortcut.
   * This is not the active item.
   */
  selected: _react.PropTypes.bool,

  /** Display text. */
  text: _lib.customPropTypes.contentShorthand,

  /** Stored value. */
  value: _react.PropTypes.oneOfType([_react.PropTypes.number, _react.PropTypes.string])
} : void 0;
DropdownItem.handledProps = ['active', 'as', 'children', 'className', 'content', 'description', 'disabled', 'flag', 'icon', 'image', 'label', 'onClick', 'selected', 'text', 'value'];