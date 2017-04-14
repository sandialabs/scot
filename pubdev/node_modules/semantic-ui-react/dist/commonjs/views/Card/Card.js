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

var _Image = require('../../elements/Image');

var _Image2 = _interopRequireDefault(_Image);

var _CardContent = require('./CardContent');

var _CardContent2 = _interopRequireDefault(_CardContent);

var _CardDescription = require('./CardDescription');

var _CardDescription2 = _interopRequireDefault(_CardDescription);

var _CardGroup = require('./CardGroup');

var _CardGroup2 = _interopRequireDefault(_CardGroup);

var _CardHeader = require('./CardHeader');

var _CardHeader2 = _interopRequireDefault(_CardHeader);

var _CardMeta = require('./CardMeta');

var _CardMeta2 = _interopRequireDefault(_CardMeta);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A card displays site content in a manner similar to a playing card.
 */
var Card = function (_Component) {
  (0, _inherits3.default)(Card, _Component);

  function Card() {
    var _ref;

    var _temp, _this, _ret;

    (0, _classCallCheck3.default)(this, Card);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, (_ref = Card.__proto__ || Object.getPrototypeOf(Card)).call.apply(_ref, [this].concat(args))), _this), _this.handleClick = function (e) {
      var onClick = _this.props.onClick;


      if (onClick) onClick(e, _this.props);
    }, _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
  }

  (0, _createClass3.default)(Card, [{
    key: 'render',
    value: function render() {
      var _props = this.props,
          centered = _props.centered,
          children = _props.children,
          className = _props.className,
          color = _props.color,
          description = _props.description,
          extra = _props.extra,
          fluid = _props.fluid,
          header = _props.header,
          href = _props.href,
          image = _props.image,
          link = _props.link,
          meta = _props.meta,
          onClick = _props.onClick,
          raised = _props.raised;


      var classes = (0, _classnames2.default)('ui', color, (0, _lib.useKeyOnly)(centered, 'centered'), (0, _lib.useKeyOnly)(fluid, 'fluid'), (0, _lib.useKeyOnly)(link, 'link'), (0, _lib.useKeyOnly)(raised, 'raised'), 'card', className);
      var rest = (0, _lib.getUnhandledProps)(Card, this.props);
      var ElementType = (0, _lib.getElementType)(Card, this.props, function () {
        if (onClick) return 'a';
      });

      if (!(0, _isNil3.default)(children)) {
        return _react2.default.createElement(
          ElementType,
          (0, _extends3.default)({}, rest, { className: classes, href: href, onClick: this.handleClick }),
          children
        );
      }

      return _react2.default.createElement(
        ElementType,
        (0, _extends3.default)({}, rest, { className: classes, href: href, onClick: this.handleClick }),
        _Image2.default.create(image),
        (description || header || meta) && _react2.default.createElement(_CardContent2.default, { description: description, header: header, meta: meta }),
        extra && _react2.default.createElement(
          _CardContent2.default,
          { extra: true },
          extra
        )
      );
    }
  }]);
  return Card;
}(_react.Component);

Card._meta = {
  name: 'Card',
  type: _lib.META.TYPES.VIEW
};
Card.Content = _CardContent2.default;
Card.Description = _CardDescription2.default;
Card.Group = _CardGroup2.default;
Card.Header = _CardHeader2.default;
Card.Meta = _CardMeta2.default;
exports.default = Card;
process.env.NODE_ENV !== "production" ? Card.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** A Card can center itself inside its container. */
  centered: _react.PropTypes.bool,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** A Card can be formatted to display different colors. */
  color: _react.PropTypes.oneOf(_lib.SUI.COLORS),

  /** Shorthand for CardDescription. */
  description: _lib.customPropTypes.itemShorthand,

  /** Shorthand for primary content of CardContent. */
  extra: _lib.customPropTypes.contentShorthand,

  /** A Card can be formatted to take up the width of its container. */
  fluid: _react.PropTypes.bool,

  /** Shorthand for CardHeader. */
  header: _lib.customPropTypes.itemShorthand,

  /** Render as an `a` tag instead of a `div` and adds the href attribute. */
  href: _react.PropTypes.string,

  /** A card can contain an Image component. */
  image: _lib.customPropTypes.itemShorthand,

  /** A card can be formatted to link to other content. */
  link: _react.PropTypes.bool,

  /** Shorthand for CardMeta. */
  meta: _lib.customPropTypes.itemShorthand,

  /**
   * Called on click. When passed, the component renders as an `a`
   * tag by default instead of a `div`.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onClick: _react.PropTypes.func,

  /** A Card can be formatted to raise above the page. */
  raised: _react.PropTypes.bool
} : void 0;
Card.handledProps = ['as', 'centered', 'children', 'className', 'color', 'description', 'extra', 'fluid', 'header', 'href', 'image', 'link', 'meta', 'onClick', 'raised'];