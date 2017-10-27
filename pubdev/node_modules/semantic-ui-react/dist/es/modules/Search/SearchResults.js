import _extends from 'babel-runtime/helpers/extends';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { customPropTypes, getElementType, getUnhandledProps, META } from '../../lib';

function SearchResults(props) {
  var children = props.children,
      className = props.className;

  var classes = cx('results transition', className);
  var rest = getUnhandledProps(SearchResults, props);
  var ElementType = getElementType(SearchResults, props);

  return React.createElement(
    ElementType,
    _extends({}, rest, { className: classes }),
    children
  );
}

SearchResults.handledProps = ['as', 'children', 'className'];
SearchResults._meta = {
  name: 'SearchResults',
  parent: 'Search',
  type: META.TYPES.MODULE
};

process.env.NODE_ENV !== "production" ? SearchResults.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string
} : void 0;

export default SearchResults;