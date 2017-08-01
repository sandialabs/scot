import _extends from 'babel-runtime/helpers/extends';
import _without from 'lodash/without';
import _map from 'lodash/map';
import _each from 'lodash/each';
import _isNil from 'lodash/isNil';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { customPropTypes, getUnhandledProps, getElementType, META, SUI } from '../../lib';
import BreadcrumbDivider from './BreadcrumbDivider';
import BreadcrumbSection from './BreadcrumbSection';

/**
 * A breadcrumb is used to show hierarchy between content.
 */
function Breadcrumb(props) {
  var children = props.children,
      className = props.className,
      divider = props.divider,
      icon = props.icon,
      sections = props.sections,
      size = props.size;


  var classes = cx('ui', size, 'breadcrumb', className);
  var rest = getUnhandledProps(Breadcrumb, props);
  var ElementType = getElementType(Breadcrumb, props);

  if (!_isNil(children)) {
    return React.createElement(
      ElementType,
      _extends({}, rest, { className: classes }),
      children
    );
  }

  var childElements = [];

  _each(sections, function (section, index) {
    // section
    var breadcrumbSection = BreadcrumbSection.create(section);
    childElements.push(breadcrumbSection);

    // divider
    if (index !== sections.length - 1) {
      // TODO generate a key from breadcrumbSection.props once this is merged:
      // https://github.com/Semantic-Org/Semantic-UI-React/pull/645
      //
      // Stringify the props of the section as the divider key.
      //
      // Section:     { content: 'Home', link: true, onClick: handleClick }
      // Divider key: content=Home|link=true|onClick=handleClick
      var key = void 0;
      if (section.key) {
        key = section.key + '_divider';
      } else {
        key = _map(breadcrumbSection.props, function (v, k) {
          return k + '=' + (typeof v === 'function' ? v.name || 'func' : v);
        }).join('|');
      }
      childElements.push(BreadcrumbDivider.create({ content: divider, icon: icon, key: key }));
    }
  });

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    childElements
  );
}

Breadcrumb.handledProps = ['as', 'children', 'className', 'divider', 'icon', 'sections', 'size'];
Breadcrumb._meta = {
  name: 'Breadcrumb',
  type: META.TYPES.COLLECTION
};

process.env.NODE_ENV !== "production" ? Breadcrumb.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Shorthand for primary content of the Breadcrumb.Divider. */
  divider: customPropTypes.every([customPropTypes.disallow(['icon']), customPropTypes.contentShorthand]),

  /** For use with the sections prop. Render as an `Icon` component with `divider` class instead of a `div` in
   *  Breadcrumb.Divider. */
  icon: customPropTypes.every([customPropTypes.disallow(['divider']), customPropTypes.itemShorthand]),

  /** Shorthand array of props for Breadcrumb.Section. */
  sections: customPropTypes.collectionShorthand,

  /** Size of Breadcrumb. */
  size: PropTypes.oneOf(_without(SUI.SIZES, 'medium'))
} : void 0;

Breadcrumb.Divider = BreadcrumbDivider;
Breadcrumb.Section = BreadcrumbSection;

export default Breadcrumb;