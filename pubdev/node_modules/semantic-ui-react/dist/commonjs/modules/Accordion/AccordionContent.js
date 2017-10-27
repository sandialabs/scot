'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _isNil2 = require('lodash/isNil');

var _isNil3 = _interopRequireDefault(_isNil2);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _lib = require('../../lib');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A content sub-component for Accordion component.
 */
function AccordionContent(props) {
  var active = props.active,
      children = props.children,
      className = props.className,
      content = props.content;

  var classes = (0, _classnames2.default)('content', (0, _lib.useKeyOnly)(active, 'active'), className);
  var rest = (0, _lib.getUnhandledProps)(AccordionContent, props);
  var ElementType = (0, _lib.getElementType)(AccordionContent, props);

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    (0, _isNil3.default)(children) ? content : children
  );
}

AccordionContent.handledProps = ['active', 'as', 'children', 'className', 'content'];
process.env.NODE_ENV !== "production" ? AccordionContent.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Whether or not the content is visible. */
  active: _react.PropTypes.bool,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Shorthand for primary content. */
  content: _lib.customPropTypes.contentShorthand
} : void 0;

AccordionContent._meta = {
  name: 'AccordionContent',
  type: _lib.META.TYPES.MODULE,
  parent: 'Accordion'
};

AccordionContent.create = (0, _lib.createShorthandFactory)(AccordionContent, function (content) {
  return { content: content };
});

exports.default = AccordionContent;