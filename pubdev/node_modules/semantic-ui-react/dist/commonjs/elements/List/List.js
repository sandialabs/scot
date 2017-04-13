'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

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

var _ListContent = require('./ListContent');

var _ListContent2 = _interopRequireDefault(_ListContent);

var _ListDescription = require('./ListDescription');

var _ListDescription2 = _interopRequireDefault(_ListDescription);

var _ListHeader = require('./ListHeader');

var _ListHeader2 = _interopRequireDefault(_ListHeader);

var _ListIcon = require('./ListIcon');

var _ListIcon2 = _interopRequireDefault(_ListIcon);

var _ListItem = require('./ListItem');

var _ListItem2 = _interopRequireDefault(_ListItem);

var _ListList = require('./ListList');

var _ListList2 = _interopRequireDefault(_ListList);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A list groups related content.
 */
function List(props) {
  var animated = props.animated,
      bulleted = props.bulleted,
      celled = props.celled,
      children = props.children,
      className = props.className,
      divided = props.divided,
      floated = props.floated,
      horizontal = props.horizontal,
      inverted = props.inverted,
      items = props.items,
      link = props.link,
      ordered = props.ordered,
      relaxed = props.relaxed,
      selection = props.selection,
      size = props.size,
      verticalAlign = props.verticalAlign;


  var classes = (0, _classnames2.default)('ui', size, (0, _lib.useKeyOnly)(animated, 'animated'), (0, _lib.useKeyOnly)(bulleted, 'bulleted'), (0, _lib.useKeyOnly)(celled, 'celled'), (0, _lib.useKeyOnly)(divided, 'divided'), (0, _lib.useKeyOnly)(horizontal, 'horizontal'), (0, _lib.useKeyOnly)(inverted, 'inverted'), (0, _lib.useKeyOnly)(link, 'link'), (0, _lib.useKeyOnly)(ordered, 'ordered'), (0, _lib.useKeyOnly)(selection, 'selection'), (0, _lib.useKeyOrValueAndKey)(relaxed, 'relaxed'), (0, _lib.useValueAndKey)(floated, 'floated'), (0, _lib.useVerticalAlignProp)(verticalAlign), 'list', className);
  var rest = (0, _lib.getUnhandledProps)(List, props);
  var ElementType = (0, _lib.getElementType)(List, props);

  if (!(0, _isNil3.default)(children)) {
    return _react2.default.createElement(
      ElementType,
      (0, _extends3.default)({}, rest, { role: 'list', className: classes }),
      children
    );
  }

  return _react2.default.createElement(
    ElementType,
    (0, _extends3.default)({}, rest, { role: 'list', className: classes }),
    (0, _map3.default)(items, function (item) {
      return _ListItem2.default.create(item);
    })
  );
}

List.handledProps = ['animated', 'as', 'bulleted', 'celled', 'children', 'className', 'divided', 'floated', 'horizontal', 'inverted', 'items', 'link', 'ordered', 'relaxed', 'selection', 'size', 'verticalAlign'];
List._meta = {
  name: 'List',
  type: _lib.META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? List.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** A list can animate to set the current item apart from the list. */
  animated: _react.PropTypes.bool,

  /** A list can mark items with a bullet. */
  bulleted: _react.PropTypes.bool,

  /** A list can divide its items into cells. */
  celled: _react.PropTypes.bool,

  /** Primary content. */
  children: _react.PropTypes.node,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /** A list can show divisions between content. */
  divided: _react.PropTypes.bool,

  /** An list can be floated left or right. */
  floated: _react.PropTypes.oneOf(_lib.SUI.FLOATS),

  /** A list can be formatted to have items appear horizontally. */
  horizontal: _react.PropTypes.bool,

  /** A list can be inverted to appear on a dark background. */
  inverted: _react.PropTypes.bool,

  /** Shorthand array of props for ListItem. */
  items: _lib.customPropTypes.collectionShorthand,

  /** A list can be specially formatted for navigation links. */
  link: _react.PropTypes.bool,

  /** A list can be ordered numerically. */
  ordered: _react.PropTypes.bool,

  /** A list can relax its padding to provide more negative space. */
  relaxed: _react.PropTypes.oneOfType([_react.PropTypes.bool, _react.PropTypes.oneOf(['very'])]),

  /** A selection list formats list items as possible choices. */
  selection: _react.PropTypes.bool,

  /** A list can vary in size. */
  size: _react.PropTypes.oneOf(_lib.SUI.SIZES),

  /** An element inside a list can be vertically aligned. */
  verticalAlign: _react.PropTypes.oneOf(_lib.SUI.VERTICAL_ALIGNMENTS)
} : void 0;

List.Content = _ListContent2.default;
List.Description = _ListDescription2.default;
List.Header = _ListHeader2.default;
List.Icon = _ListIcon2.default;
List.Item = _ListItem2.default;
List.List = _ListList2.default;

exports.default = List;