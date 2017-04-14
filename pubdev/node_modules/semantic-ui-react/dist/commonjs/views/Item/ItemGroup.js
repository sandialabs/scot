'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _objectWithoutProperties2 = require('babel-runtime/helpers/objectWithoutProperties');

var _objectWithoutProperties3 = _interopRequireDefault(_objectWithoutProperties2);

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _map2 = require('lodash/map');

var _map3 = _interopRequireDefault(_map2);

var _isNil2 = require('lodash/isNil');

var _isNil3 = _interopRequireDefault(_isNil2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _Item = require('./Item');

var _Item2 = _interopRequireDefault(_Item);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A group of items.
 */
function ItemGroup(props) {
  var children = props.children,
      className = props.className,
      divided = props.divided,
      items = props.items,
      link = props.link,
      relaxed = props.relaxed;


  var classes = (0, _classnames2.default)('ui', (0, _lib.useKeyOnly)(divided, 'divided'), (0, _lib.useKeyOnly)(link, 'link'), (0, _lib.useKeyOrValueAndKey)(relaxed, 'relaxed'), 'items', className);
  var rest = (0, _lib.getUnhandledProps)(ItemGroup, props);
  var ElementType = (0, _lib.getElementType)(ItemGroup, props);

  if (!(0, _isNil3.default)(children)) {
    return _react2.default.createElement(
      ElementType,
      (0, _extends3.default)({}, rest, { className: classes }),
      children
    );
  }

  var itemsJSX = (0, _map3.default)(items, function (item) {
    var childKey = item.childKey,
        itemProps = (0, _objectWithoutProperties3.default)(item, ['childKey']);

    var finalKey = childKey || [itemProps.content, itemProps.description, itemProps.header, itemProps.meta].join('-');

    return _react2.default.createElement(_Item2.default, (0, _extends3.default)({}, itemProps, { key: finalKey }));
  });

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { className: classes }),
    itemsJSX
  );
}

ItemGroup.handledProps = ['as', 'children', 'className', 'divided', 'items', 'link', 'relaxed'];
ItemGroup._meta = {
  name: 'ItemGroup',
  type: _lib.META.TYPES.VIEW,
  parent: 'Item'
};

process.env.NODE_ENV !== "production" ? ItemGroup.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** Items can be divided to better distinguish between grouped content. */
  divided: _react.PropTypes.bool,

  /** Shorthand array of props for Item. */
  items: _lib.customPropTypes.collectionShorthand,

  /** An item can be formatted so that the entire contents link to another page. */
  link: _react.PropTypes.bool,

  /** A group of items can relax its padding to provide more negative space. */
  relaxed: _react.PropTypes.oneOfType([_react.PropTypes.bool, _react.PropTypes.oneOf(['very'])])
} : void 0;

exports.default = ItemGroup;