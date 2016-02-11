'use strict';

var React = require('react');

var assign = require('object-assign'),
    joinClasses = require('../utils/joinClasses');

var ExpandableNavItem = require('./ExpandableNavItem');

var ExpandableNavMenuItem = React.createClass({displayName: "ExpandableNavMenuItem",
  propTypes: {
    small: React.PropTypes.element,
    full: React.PropTypes.element,
    smallClass: React.PropTypes.string,
    fullClass: React.PropTypes.string,
    smallStyle: React.PropTypes.object,
    fullStyle: React.PropTypes.object,
    url: React.PropTypes.string,
    tooltip: React.PropTypes.string,
    active: React.PropTypes.bool,
    onClick: React.PropTypes.func
  },
  componentDidUpdate:function() {
    if (!this.props.tooltip) {
      return;
    }
    var $ = this.props.jquery;
    if (this.props.expanded) {
      $(this.refs.link.getDOMNode()).tooltip('disable');
    } else {
      $(this.refs.link.getDOMNode()).tooltip('enable');
    }
  },
  getDefaultProps:function() {
    var sharedStyle = {
      paddingTop: 13,
      paddingRight: 15,
      paddingBottom: 13,
      paddingLeft: 12
    };
    return {
      smallStyle: sharedStyle,
      fullStyle: sharedStyle
    };
  },
  handleClick:function(e) {
    if (this.props.onClick) {
      this.props.onClick(e);
    }
    this.props.onSelect();
  },
  render:function() {
    var $__0=      this.props,active=$__0.active,url=$__0.url,small=$__0.small,full=$__0.full,props=(function(source, exclusion) {var rest = {};var hasOwn = Object.prototype.hasOwnProperty;if (source == null) {throw new TypeError();}for (var key in source) {if (hasOwn.call(source, key) && !hasOwn.call(exclusion, key)) {rest[key] = source[key];}}return rest;})($__0,{active:1,url:1,small:1,full:1});

    var liStyle = {
      float: 'none'
    };
    var aStyle = {
      padding: 0
    };
    var smallStyle = assign(this.props.smallStyle || {}, {
      display: 'block',
      fontSize: 20,
    });
    var fullStyle = assign(this.props.fullStyle || {}, {
      display: 'block',
      fontSize: 20,
    });
    var classes = active ? 'active' : '' +
      joinClasses(this.props.className, this.props.expanded ? this.props.fullClass : this.props.smallClass);

    var link;
    var navItemStyle = {
      cursor: 'pointer'
    };
    if (this.props.tooltip) {
      if (!this.props.jquery) {
        throw new Error('jQuery dependency must be passed to ExpandableNavMenuItem to enable tooltip function');
      }
      link = (
        React.createElement("a", {ref: "link", href: url, onClick: this.handleClick, style: aStyle, "data-toggle": "menuitem-tooltip", "data-placement": "right", title: this.props.tooltip}, 
          React.createElement(ExpandableNavItem, React.__spread({style: navItemStyle, small: small, full: full, smallStyle: smallStyle, fullStyle: fullStyle},  props))
        )
      );
    } else {
      link = (
        React.createElement("a", {ref: "link", href: url, onClick: this.handleClick, style: aStyle}, 
          React.createElement(ExpandableNavItem, React.__spread({style: navItemStyle, small: small, full: full, smallStyle: smallStyle, fullStyle: fullStyle},  props))
        )
      );
    }

    return (
      React.createElement("li", {className: classes, style: liStyle}, 
        link
      )
    );
  }
});

module.exports = ExpandableNavMenuItem;
