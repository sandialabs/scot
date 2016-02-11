'use strict';

var React = require('react/addons');

var joinClasses = require('../utils/joinClasses'),
    assign = require('object-assign');

var ExpandableNavbar = React.createClass({displayName: "ExpandableNavbar",
  propTypes: {
    fullWidth: React.PropTypes.number,
    smallWidth: React.PropTypes.number,
    fullClass: React.PropTypes.string,
    smallClass: React.PropTypes.string
  },
  getDefaultProps:function() {
    return {
      fullWidth: 240,
      smallWidth: 50
    };
  },
  render:function() {
    var navbarStyle = assign({
      position: 'fixed',
      top: 0,
      left: 0,
      height: 100 + '%',
      borderRadius: 0,
      border: 0,
      width: this.props.expanded ? this.props.fullWidth : this.props.smallWidth
    }, this.props.style);

    var navbarContainerStyle = {
      padding: 0,
      width: 100 + '%',
      height: 100 + '%',
      position: 'relative'
    };

    var classes = "navbar navbar-inverse " +
      joinClasses(this.props.className, this.props.expanded ? this.props.fullClass : this.props.smallClass);
    return (
      React.createElement("div", {className: classes, style: navbarStyle, role: "navigation"}, 
        React.createElement("div", {style: navbarContainerStyle}, 
          React.Children.map(this.props.children, this.renderChild)
        )
      )
    );
  },
  renderChild:function(child, i) {
    return React.addons.cloneWithProps(child, {
      key: i,
      expanded: this.props.expanded
    });
  },
});

module.exports = ExpandableNavbar;
