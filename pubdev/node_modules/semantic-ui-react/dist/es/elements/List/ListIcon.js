import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { createShorthandFactory, getUnhandledProps, META, SUI, useVerticalAlignProp } from '../../lib';
import Icon from '../Icon/Icon';

/**
 * A list item can contain an icon.
 */
function ListIcon(props) {
  var className = props.className,
      verticalAlign = props.verticalAlign;

  var classes = cx(useVerticalAlignProp(verticalAlign), className);
  var rest = getUnhandledProps(ListIcon, props);

  return React.createElement(Icon, _extends({}, rest, { className: classes }));
}

ListIcon.handledProps = ['className', 'verticalAlign'];
ListIcon._meta = {
  name: 'ListIcon',
  parent: 'List',
  type: META.TYPES.ELEMENT
};

process.env.NODE_ENV !== "production" ? ListIcon.propTypes = {
  /** Additional classes. */
  className: PropTypes.string,

  /** An element inside a list can be vertically aligned. */
  verticalAlign: PropTypes.oneOf(SUI.VERTICAL_ALIGNMENTS)
} : void 0;

ListIcon.create = createShorthandFactory(ListIcon, function (name) {
  return { name: name };
});

export default ListIcon;