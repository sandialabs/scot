import _extends from 'babel-runtime/helpers/extends';
import _without from 'lodash/without';
import _map from 'lodash/map';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META, SUI, useValueAndKey, useKeyOnly } from '../../lib';
import Step from './Step';

/**
 * A set of steps.
 */
function StepGroup(props) {
  var children = props.children,
      className = props.className,
      fluid = props.fluid,
      items = props.items,
      ordered = props.ordered,
      size = props.size,
      stackable = props.stackable,
      vertical = props.vertical;

  var classes = cx('ui', size, useKeyOnly(fluid, 'fluid'), useKeyOnly(ordered, 'ordered'), useKeyOnly(vertical, 'vertical'), useValueAndKey(stackable, 'stackable'), 'steps', className);
  var rest = getUnhandledProps(StepGroup, props);
  var ElementType = getElementType(StepGroup, props);

  if (!_isNil(children)) {
    return React.createElement(
      ElementType,
      _extends({}, rest, { className: classes }),
      children
    );
  }

  var content = _map(items, function (item) {
    var key = item.key || [item.title, item.description].join('-');
    return React.createElement(Step, _extends({ key: key }, item));
  });

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    content
  );
}

StepGroup.handledProps = ['as', 'children', 'className', 'fluid', 'items', 'ordered', 'size', 'stackable', 'vertical'];
StepGroup._meta = {
  name: 'StepGroup',
  parent: 'Step',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? StepGroup.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** A fluid step takes up the width of its container. */
  fluid: PropTypes.bool,

  /** Shorthand array of props for Step. */
  items: customPropTypes.collectionShorthand,

  /** A step can show a ordered sequence of steps. */
  ordered: PropTypes.bool,

  /** Steps can have different sizes. */
  size: PropTypes.oneOf(_without(SUI.SIZES, 'medium')),

  /** A step can stack vertically only on smaller screens. */
  stackable: PropTypes.oneOf(['tablet']),

  /** A step can be displayed stacked vertically. */
  vertical: PropTypes.bool
} : void 0;

export default StepGroup;