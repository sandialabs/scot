import _extends from 'babel-runtime/helpers/extends';
import _without from 'lodash/without';
import _map from 'lodash/map';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, SUI, useKeyOnly, useWidthProp } from '../../lib';
import Statistic from './Statistic';

/**
 * A group of statistics.
 */
function StatisticGroup(props) {
  var children = props.children,
      className = props.className,
      color = props.color,
      horizontal = props.horizontal,
      inverted = props.inverted,
      items = props.items,
      size = props.size,
      widths = props.widths;


  var classes = cx('ui', color, size, useKeyOnly(horizontal, 'horizontal'), useKeyOnly(inverted, 'inverted'), useWidthProp(widths), 'statistics', className);
  var rest = getUnhandledProps(StatisticGroup, props);
  var ElementType = getElementType(StatisticGroup, props);

  if (!_isNil(children)) return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );

  var itemsJSX = _map(items, function (item) {
    return React.createElement(Statistic, _extends({ key: item.childKey || [item.label, item.title].join('-') }, item));
  });

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    itemsJSX
  );
}

StatisticGroup.handledProps = ['as', 'children', 'className', 'color', 'horizontal', 'inverted', 'items', 'size', 'widths'];
StatisticGroup._meta = {
  name: 'StatisticGroup',
  type: META.TYPES.VIEW,
  parent: 'Statistic'
};

process.env.NODE_ENV !== "production" ? StatisticGroup.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** A statistic group can be formatted to be different colors. */
  color: PropTypes.oneOf(SUI.COLORS),

  /** A statistic group can present its measurement horizontally. */
  horizontal: PropTypes.bool,

  /** A statistic group can be formatted to fit on a dark background. */
  inverted: PropTypes.bool,

  /** Array of props for Statistic. */
  items: customPropTypes.collectionShorthand,

  /** A statistic group can vary in size. */
  size: PropTypes.oneOf(_without(SUI.SIZES, 'big', 'massive', 'medium')),

  /** A statistic group can have its items divided evenly. */
  widths: PropTypes.oneOf(SUI.WIDTHS)
} : void 0;

export default StatisticGroup;