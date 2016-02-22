'use strict';

var React = require('react/addons');

var ExpandableNavContainer = React.createClass({displayName: "ExpandableNavContainer",
  getInitialState:function() {
    return {
      expanded: this.props.expanded || false,
    };
  },
  handleToggle:function() {
    this.setState({expanded: !this.state.expanded});
  },
  render:function() {
    return (
      React.createElement("div", React.__spread({},  this.props), 
        React.Children.map(this.props.children, this.renderChild)
      )
    );
  },
  renderChild:function(child, i) {
    return React.addons.cloneWithProps(child, {
      key: child.key ? child.key : i,
      expanded: this.state.expanded,
      handleToggle: this.handleToggle,
      ref: child.ref
    });
  },
});

module.exports = ExpandableNavContainer;
