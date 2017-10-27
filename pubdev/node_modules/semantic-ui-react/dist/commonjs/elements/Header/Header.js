'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _without2 = require('lodash/without');

var _without3 = _interopRequireDefault(_without2);

var _isNil2 = require('lodash/isNil');

var _isNil3 = _interopRequireDefault(_isNil2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _Icon = require('../../elements/Icon');

var _Icon2 = _interopRequireDefault(_Icon);

var _Image = require('../../elements/Image');

var _Image2 = _interopRequireDefault(_Image);

var _HeaderSubheader = require('./HeaderSubheader');

var _HeaderSubheader2 = _interopRequireDefault(_HeaderSubheader);

var _HeaderContent = require('./HeaderContent');

var _HeaderContent2 = _interopRequireDefault(_HeaderContent);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A header provides a short summary of content
 */
function Header(props) {
  var attached = props.attached,
      block = props.block,
      children = props.children,
      className = props.className,
      color = props.color,
      content = props.content,
      disabled = props.disabled,
      dividing = props.dividing,
      floated = props.floated,
      icon = props.icon,
      image = props.image,
      inverted = props.inverted,
      size = props.size,
      sub = props.sub,
      subheader = props.subheader,
      textAlign = props.textAlign;


  var classes = (0, _classnames2.default)('ui', color, size, (0, _lib.useKeyOnly)(block, 'block'), (0, _lib.useKeyOnly)(disabled, 'disabled'), (0, _lib.useKeyOnly)(dividing, 'dividing'), (0, _lib.useValueAndKey)(floated, 'floated'), (0, _lib.useKeyOnly)(icon === true, 'icon'), (0, _lib.useKeyOnly)(image === true, 'image'), (0, _lib.useKeyOnly)(inverted, 'inverted'), (0, _lib.useKeyOnly)(sub, 'sub'), (0, _lib.useKeyOrValueAndKey)(attached, 'attached'), (0, _lib.useTextAlignProp)(textAlign), 'header', className);
  var rest = (0, _lib.getUnhandledProps)(Header, props);
  var ElementType = (0, _lib.getElementType)(Header, props);

  if (!(0, _isNil3.default)(children)) {
    return _react2.default.createElement(
      ElementType,
      (0, _extends3.default)({}, rest, { className: classes }),
      children
    );
  }

  var iconElement = _Icon2.default.create(icon);
  var imageElement = _Image2.default.create(image);
  var subheaderElement = _HeaderSubheader2.default.create(subheader);

  if (iconElement || imageElement) {
    return _react2.default.createElement(
      ElementType,
      (0, _extends3.default)({}, rest, { className: classes }),
      iconElement || imageElement,
      (content || subheaderElement) && _react2.default.createElement(
        _HeaderContent2.default,
        null,
        content,
        subheaderElement
      )
    );
  }

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    content,
    subheaderElement
  );
}

Header.handledProps = ['as', 'attached', 'block', 'children', 'className', 'color', 'content', 'disabled', 'dividing', 'floated', 'icon', 'image', 'inverted', 'size', 'sub', 'subheader', 'textAlign'];
Header._meta = {
  name: 'Header',
  type: _lib.META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? Header.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Attach header  to other content, like a segment. */
  attached: _react.PropTypes.oneOfType([_react.PropTypes.bool, _react.PropTypes.oneOf(['top', 'bottom'])]),

  /** Format header to appear inside a content block. */
  block: _react.PropTypes.bool,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Color of the header. */
  color: _react.PropTypes.oneOf(_lib.SUI.COLORS),

  /** Shorthand for primary content. */
  content: _lib.customPropTypes.contentShorthand,

  /** Show that the header is inactive. */
  disabled: _react.PropTypes.bool,

  /** Divide header from the content below it. */
  dividing: _react.PropTypes.bool,

  /** Header can sit to the left or right of other content. */
  floated: _react.PropTypes.oneOf(_lib.SUI.FLOATS),

  /** Add an icon by icon name or pass an Icon. */
  icon: _lib.customPropTypes.every([_lib.customPropTypes.disallow(['image']), _react.PropTypes.oneOfType([_react.PropTypes.bool, _lib.customPropTypes.itemShorthand])]),

  /** Add an image by img src or pass an Image. */
  image: _lib.customPropTypes.every([_lib.customPropTypes.disallow(['icon']), _react.PropTypes.oneOfType([_react.PropTypes.bool, _lib.customPropTypes.itemShorthand])]),

  /** Inverts the color of the header for dark backgrounds. */
  inverted: _react.PropTypes.bool,

  /** Content headings are sized with em and are based on the font-size of their container. */
  size: _react.PropTypes.oneOf((0, _without3.default)(_lib.SUI.SIZES, 'big', 'massive')),

  /** Headers may be formatted to label smaller or de-emphasized content. */
  sub: _react.PropTypes.bool,

  /** Shorthand for Header.Subheader. */
  subheader: _lib.customPropTypes.itemShorthand,

  /** Align header content. */
  textAlign: _react.PropTypes.oneOf(_lib.SUI.TEXT_ALIGNMENTS)
} : void 0;

Header.Content = _HeaderContent2.default;
Header.Subheader = _HeaderSubheader2.default;

exports.default = Header;