import _extends from 'babel-runtime/helpers/extends';
import _classCallCheck from 'babel-runtime/helpers/classCallCheck';
import _createClass from 'babel-runtime/helpers/createClass';
import _possibleConstructorReturn from 'babel-runtime/helpers/possibleConstructorReturn';
import _inherits from 'babel-runtime/helpers/inherits';
import _isNil from 'lodash/isNil';

import cx from 'classnames';
import React, { Component, PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, SUI, useKeyOnly } from '../../lib';
import Image from '../../elements/Image';
import CardContent from './CardContent';
import CardDescription from './CardDescription';
import CardGroup from './CardGroup';
import CardHeader from './CardHeader';
import CardMeta from './CardMeta';

/**
 * A card displays site content in a manner similar to a playing card.
 */

var Card = function (_Component) {
  _inherits(Card, _Component);

  function Card() {
    var _ref;

    var _temp, _this, _ret;

    _classCallCheck(this, Card);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = _possibleConstructorReturn(this, (_ref = Card.__proto__ || Object.getPrototypeOf(Card)).call.apply(_ref, [this].concat(args))), _this), _this.handleClick = function (e) {
      var onClick = _this.props.onClick;


      if (onClick) onClick(e, _this.props);
    }, _temp), _possibleConstructorReturn(_this, _ret);
  }

  _createClass(Card, [{
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


      var classes = cx('ui', color, useKeyOnly(centered, 'centered'), useKeyOnly(fluid, 'fluid'), useKeyOnly(link, 'link'), useKeyOnly(raised, 'raised'), 'card', className);
      var rest = getUnhandledProps(Card, this.props);
      var ElementType = getElementType(Card, this.props, function () {
        if (onClick) return 'a';
      });

      if (!_isNil(children)) {
        return React.createElement(
          ElementType,
          _extends({}, rest, { className: classes, href: href, onClick: this.handleClick }),
          children
        );
      }

      return React.createElement(
        ElementType,
        _extends({}, rest, { className: classes, href: href, onClick: this.handleClick }),
        Image.create(image),
        (description || header || meta) && React.createElement(CardContent, { description: description, header: header, meta: meta }),
        extra && React.createElement(
          CardContent,
          { extra: true },
          extra
        )
      );
    }
  }]);

  return Card;
}(Component);

Card._meta = {
  name: 'Card',
  type: META.TYPES.VIEW
};
Card.Content = CardContent;
Card.Description = CardDescription;
Card.Group = CardGroup;
Card.Header = CardHeader;
Card.Meta = CardMeta;
export default Card;
process.env.NODE_ENV !== "production" ? Card.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** A Card can center itself inside its container. */
  centered: PropTypes.bool,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** A Card can be formatted to display different colors. */
  color: PropTypes.oneOf(SUI.COLORS),

  /** Shorthand for CardDescription. */
  description: customPropTypes.itemShorthand,

  /** Shorthand for primary content of CardContent. */
  extra: customPropTypes.contentShorthand,

  /** A Card can be formatted to take up the width of its container. */
  fluid: PropTypes.bool,

  /** Shorthand for CardHeader. */
  header: customPropTypes.itemShorthand,

  /** Render as an `a` tag instead of a `div` and adds the href attribute. */
  href: PropTypes.string,

  /** A card can contain an Image component. */
  image: customPropTypes.itemShorthand,

  /** A card can be formatted to link to other content. */
  link: PropTypes.bool,

  /** Shorthand for CardMeta. */
  meta: customPropTypes.itemShorthand,

  /**
   * Called on click. When passed, the component renders as an `a`
   * tag by default instead of a `div`.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props.
   */
  onClick: PropTypes.func,

  /** A Card can be formatted to raise above the page. */
  raised: PropTypes.bool
} : void 0;
Card.handledProps = ['as', 'centered', 'children', 'className', 'color', 'description', 'extra', 'fluid', 'header', 'href', 'image', 'link', 'meta', 'onClick', 'raised'];