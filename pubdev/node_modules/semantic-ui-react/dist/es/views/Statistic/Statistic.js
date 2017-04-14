import _extends from 'babel-runtime/helpers/extends';
import _without from 'lodash/without';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, SUI, useKeyOnly, useValueAndKey } from '../../lib';
import StatisticGroup from './StatisticGroup';
import StatisticLabel from './StatisticLabel';
import StatisticValue from './StatisticValue';

/**
 * A statistic emphasizes the current value of an attribute.
 */
function Statistic(props) {
  var children = props.children,
      className = props.className,
      color = props.color,
      floated = props.floated,
      horizontal = props.horizontal,
      inverted = props.inverted,
      label = props.label,
      size = props.size,
      text = props.text,
      value = props.value;


  var classes = cx('ui', color, size, useValueAndKey(floated, 'floated'), useKeyOnly(horizontal, 'horizontal'), useKeyOnly(inverted, 'inverted'), 'statistic', className);
  var rest = getUnhandledProps(Statistic, props);
  var ElementType = getElementType(Statistic, props);

  if (!_isNil(children)) return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    React.createElement(StatisticValue, { text: text, value: value }),
    React.createElement(StatisticLabel, { label: label })
  );
}

Statistic.handledProps = ['as', 'children', 'className', 'color', 'floated', 'horizontal', 'inverted', 'label', 'size', 'text', 'value'];
Statistic._meta = {
  name: 'Statistic',
  type: META.TYPES.VIEW
};

process.env.NODE_ENV !== "production" ? Statistic.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** A statistic can be formatted to be different colors. */
  color: PropTypes.oneOf(SUI.COLORS),

  /** A statistic can sit to the left or right of other content. */
  floated: PropTypes.oneOf(SUI.FLOATS),

  /** A statistic can present its measurement horizontally. */
  horizontal: PropTypes.bool,

  /** A statistic can be formatted to fit on a dark background. */
  inverted: PropTypes.bool,

  /** Label content of the Statistic. */
  label: customPropTypes.contentShorthand,

  /** A statistic can vary in size. */
  size: PropTypes.oneOf(_without(SUI.SIZES, 'big', 'massive', 'medium')),

  /** Format the StatisticValue with smaller font size to fit nicely beside number values. */
  text: PropTypes.bool,

  /** Value content of the Statistic. */
  value: customPropTypes.contentShorthand
} : void 0;

Statistic.Group = StatisticGroup;
Statistic.Label = StatisticLabel;
Statistic.Value = StatisticValue;

export default Statistic;