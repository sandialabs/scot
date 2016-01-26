'use strict';

var React = require('react/addons');

var ExpandableNavContainer = React.createClass({
  getInitialState() {
    return {
      expanded: this.props.expanded || false,
    };
  },
  handleToggle() {
    this.setState({expanded: !this.state.expanded});
  },
  render() {
    return (
      <div {...this.props}>
        {React.Children.map(this.props.children, this.renderChild)}
      </div>
    );
  },
  renderChild(child, i) {
    return React.addons.cloneWithProps(child, {
      key: child.key ? child.key : i,
      expanded: this.state.expanded,
      handleToggle: this.handleToggle,
      ref: child.ref
    });
  },
});

module.exports = ExpandableNavContainer;
