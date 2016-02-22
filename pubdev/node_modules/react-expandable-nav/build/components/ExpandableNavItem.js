'use strict';

var React = require('react/addons');

var assign = require('object-assign');

var ExpandableNavItem = React.createClass({displayName: "ExpandableNavItem",
  propTypes: {
    small: React.PropTypes.element,
    full: React.PropTypes.element,
    smallStyle: React.PropTypes.object,
    fullStyle: React.PropTypes.object
  },
  getDefaultProps:function() {
    return {
      smallStyle: {},
      fullStyle: {}
    };
  },
  render:function() {
    var style = assign(this.props.expanded ? this.props.fullStyle : this.props.smallStyle, this.props.style);

    return (
      React.createElement("span", {style: style}, this.props.expanded ? this.props.full : this.props.small)
    );
  }
});

module.exports = ExpandableNavItem;
