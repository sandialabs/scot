'use strict';

var React = require('react');

var assign = require('object-assign'),
    joinClasses = require('../utils/joinClasses');

var ExpandableNavItem = require('./ExpandableNavItem');

var ExpandableNavHeader = React.createClass({displayName: "ExpandableNavHeader",
  propTypes: {
    small: React.PropTypes.element,
    full: React.PropTypes.element,
    headerStyle: React.PropTypes.object,
    smallStyle: React.PropTypes.object,
    fullStyle: React.PropTypes.object,
    smallClass: React.PropTypes.string,
    fullClass: React.PropTypes.string
  },
  getDefaultProps:function() {
    return {
      headerStyle: {
        width: 100 + '%',
        margin: 0
      },
    };
  },
  render:function() {
    var headerStyle = assign(this.props.headerStyle || {}, {
      display: 'block',
      float: 'none'
    });
    var sharedStyle = {
      display: 'block',
      fontWeight: 'bold',
      fontSize: 20,
    };
    var smallStyle = assign(this.props.smallStyle || {}, sharedStyle),
        fullStyle = assign(this.props.fullStyle || {}, sharedStyle);

    var classes = "navbar-header " +
      joinClasses(this.props.className, this.props.expanded ? this.props.fullClass : this.props.smallClass);

    var navItemStyle = {
      cursor: 'pointer'
    };
    return (
      React.createElement("div", {style: headerStyle, className: classes}, 
        React.createElement("div", {style: headerStyle, className: "navbar-brand"}, 
          React.createElement(ExpandableNavItem, {style: navItemStyle, ref: "navItem", 
            smallStyle: smallStyle, fullStyle: fullStyle, 
            smallClass: this.props.smallClass, fullClass: this.props.fullClass, 
            small: this.props.small, full: this.props.full, expanded: this.props.expanded})
        )
      )
    );
  },
  getNavItem:function() {
    return this.refs.navItem;
  }
});

module.exports = ExpandableNavHeader;
