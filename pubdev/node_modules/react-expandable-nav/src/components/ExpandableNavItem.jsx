'use strict';

var React = require('react/addons');

var assign = require('object-assign');

var ExpandableNavItem = React.createClass({
  propTypes: {
    small: React.PropTypes.element,
    full: React.PropTypes.element,
    smallStyle: React.PropTypes.object,
    fullStyle: React.PropTypes.object
  },
  getDefaultProps() {
    return {
      smallStyle: {},
      fullStyle: {}
    };
  },
  render() {
    var style = assign(this.props.expanded ? this.props.fullStyle : this.props.smallStyle, this.props.style);

    return (
      <span style={style}>{this.props.expanded ? this.props.full : this.props.small}</span>
    );
  }
});

module.exports = ExpandableNavItem;
