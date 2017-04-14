import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, useKeyOnly } from '../../lib';

/**
 * An ad displays third-party promotional content.
 */
function Advertisement(props) {
  var centered = props.centered,
      children = props.children,
      className = props.className,
      test = props.test,
      unit = props.unit;


  var classes = cx('ui', unit, useKeyOnly(centered, 'centered'), useKeyOnly(test, 'test'), 'ad', className);
  var rest = getUnhandledProps(Advertisement, props);
  var ElementType = getElementType(Advertisement, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes, 'data-text': test }),
    children
  );
}

Advertisement.handledProps = ['as', 'centered', 'children', 'className', 'test', 'unit'];
Advertisement._meta = {
  name: 'Advertisement',
  type: META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? Advertisement.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Center the advertisement. */
  centered: PropTypes.bool,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Text to be displayed on the advertisement. */
  test: PropTypes.oneOfType([PropTypes.bool, PropTypes.number, PropTypes.string]),

  /** Varies the size of the advertisement. */
  unit: PropTypes.oneOf(['medium rectangle', 'large rectangle', 'vertical rectangle', 'small rectangle', 'mobile banner', 'banner', 'vertical banner', 'top banner', 'half banner', 'button', 'square button', 'small button', 'skyscraper', 'wide skyscraper', 'leaderboard', 'large leaderboard', 'mobile leaderboard', 'billboard', 'panorama', 'netboard', 'half page', 'square', 'small square']).isRequired

} : void 0;

export default Advertisement;