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

var _isUndefined2 = require('lodash/isUndefined');

var _isUndefined3 = _interopRequireDefault(_isUndefined2);

var _isNil2 = require('lodash/isNil');

var _isNil3 = _interopRequireDefault(_isNil2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _Icon = require('../Icon/Icon');

var _Icon2 = _interopRequireDefault(_Icon);

var _Image = require('../Image/Image');

var _Image2 = _interopRequireDefault(_Image);

var _LabelDetail = require('./LabelDetail');

var _LabelDetail2 = _interopRequireDefault(_LabelDetail);

var _LabelGroup = require('./LabelGroup');

var _LabelGroup2 = _interopRequireDefault(_LabelGroup);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A label displays content classification.
 */
var Label = function (_Component) {
  (0, _inherits3.default)(Label, _Component);

  function Label() {
    var _ref;

    var _temp, _this, _ret;

    (0, _classCallCheck3.default)(this, Label);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, (_ref = Label.__proto__ || Object.getPrototypeOf(Label)).call.apply(_ref, [this].concat(args))), _this), _this.handleClick = function (e) {
      var onClick = _this.props.onClick;


      if (onClick) onClick(e, _this.props);
    }, _this.handleRemove = function (e) {
      var onRemove = _this.props.onRemove;


      if (onRemove) onRemove(e, _this.props);
    }, _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
  }

  (0, _createClass3.default)(Label, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          active = _props.active,
          attached = _props.attached,
          basic = _props.basic,
          children = _props.children,
          circular = _props.circular,
          className = _props.className,
          color = _props.color,
          content = _props.content,
          corner = _props.corner,
          detail = _props.detail,
          empty = _props.empty,
          floating = _props.floating,
          horizontal = _props.horizontal,
          icon = _props.icon,
          image = _props.image,
          onRemove = _props.onRemove,
          pointing = _props.pointing,
          removeIcon = _props.removeIcon,
          ribbon = _props.ribbon,
          size = _props.size,
          tag = _props.tag;


      var pointingClass = pointing === true && 'pointing' || (pointing === 'left' || pointing === 'right') && pointing + ' pointing' || (pointing === 'above' || pointing === 'below') && 'pointing ' + pointing;

      var classes = (0, _classnames2.default)('ui', color, pointingClass, size, (0, _lib.useKeyOnly)(active, 'active'), (0, _lib.useKeyOnly)(basic, 'basic'), (0, _lib.useKeyOnly)(circular, 'circular'), (0, _lib.useKeyOnly)(empty, 'empty'), (0, _lib.useKeyOnly)(floating, 'floating'), (0, _lib.useKeyOnly)(horizontal, 'horizontal'), (0, _lib.useKeyOnly)(image === true, 'image'), (0, _lib.useKeyOnly)(tag, 'tag'), (0, _lib.useKeyOrValueAndKey)(corner, 'corner'), (0, _lib.useKeyOrValueAndKey)(ribbon, 'ribbon'), (0, _lib.useValueAndKey)(attached, 'attached'), 'label', className);
      var rest = (0, _lib.getUnhandledProps)(Label, this.props);
      var ElementType = (0, _lib.getElementType)(Label, this.props);

      if (!(0, _isNil3.default)(children)) {
        return _react2.default.createElement(
          ElementType,
          (0, _extends3.default)({}, rest, { className: classes, onClick: this.handleClick }),
          children
        );
      }

      var removeIconShorthand = (0, _isUndefined3.default)(removeIcon) ? 'delete' : removeIcon;

      return _react2.default.createElement(
        ElementType,
        (0, _extends3.default)({ className: classes, onClick: this.handleClick }, rest),
        _Icon2.default.create(icon),
        typeof image !== 'boolean' && _Image2.default.create(image),
        content,
        (0, _lib.createShorthand)(_LabelDetail2.default, function (val) {
          return { content: val };
        }, detail),
        onRemove && _Icon2.default.create(removeIconShorthand, { onClick: this.handleRemove })
      );
    }
  }]);
  return Label;
}(_react.Component);

Label._meta = {
  name: 'Label',
  type: _lib.META.TYPES.ELEMENT
};
Label.Detail = _LabelDetail2.default;
Label.Group = _LabelGroup2.default;
exports.default = Label;
process.env.NODE_ENV !== "production" ? Label.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** A label can be active. */
  active: _react.PropTypes.bool,

  /** A label can attach to a content segment. */
  attached: _react.PropTypes.oneOf(['top', 'bottom', 'top right', 'top left', 'bottom left', 'bottom right']),

  /** A label can reduce its complexity. */
  basic: _react.PropTypes.bool,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** A label can be circular. */
  circular: _react.PropTypes.bool,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Color of the label. */
  color: _react.PropTypes.oneOf(_lib.SUI.COLORS),

  /** Shorthand for primary content. */
  content: _lib.customPropTypes.contentShorthand,

  /** A label can position itself in the corner of an element. */
  corner: _react.PropTypes.oneOfType([_react.PropTypes.bool, _react.PropTypes.oneOf(['left', 'right'])]),

  /** Shorthand for LabelDetail. */
  detail: _lib.customPropTypes.itemShorthand,

  /** Formats the label as a dot. */
  empty: _lib.customPropTypes.every([_react.PropTypes.bool, _lib.customPropTypes.demand(['circular'])]),

  /** Float above another element in the upper right corner. */
  floating: _react.PropTypes.bool,

  /** A horizontal label is formatted to label content along-side it horizontally. */
  horizontal: _react.PropTypes.bool,

  /** Shorthand for Icon. */
  icon: _lib.customPropTypes.itemShorthand,

  /** A label can be formatted to emphasize an image or prop can be used as shorthand for Image. */
  image: _react.PropTypes.oneOfType([_react.PropTypes.bool, _lib.customPropTypes.itemShorthand]),

  /**
   * Called on click.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onClick: _react.PropTypes.func,

  /**
   * Adds an "x" icon, called when "x" is clicked.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onRemove: _react.PropTypes.func,

  /** A label can point to content next to it. */
  pointing: _react.PropTypes.oneOfType([_react.PropTypes.bool, _react.PropTypes.oneOf(['above', 'below', 'left', 'right'])]),

  /** Shorthand for Icon to appear as the last child and trigger onRemove. */
  removeIcon: _lib.customPropTypes.itemShorthand,

  /** A label can appear as a ribbon attaching itself to an element. */
  ribbon: _react.PropTypes.oneOfType([_react.PropTypes.bool, _react.PropTypes.oneOf(['right'])]),

  /** A label can have different sizes. */
  size: _react.PropTypes.oneOf(_lib.SUI.SIZES),

  /** A label can appear as a tag. */
  tag: _react.PropTypes.bool
} : void 0;
Label.handledProps = ['active', 'as', 'attached', 'basic', 'children', 'circular', 'className', 'color', 'content', 'corner', 'detail', 'empty', 'floating', 'horizontal', 'icon', 'image', 'onClick', 'onRemove', 'pointing', 'removeIcon', 'ribbon', 'size', 'tag'];


Label.create = (0, _lib.createShorthandFactory)(Label, function (value) {
  return { content: value };
});