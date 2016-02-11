'use strict';

var React = require('react');

var assign = require('object-assign'),
    joinClasses = require('../utils/joinClasses');

var ExpandableNavItem = require('./ExpandableNavItem');

var ExpandableNavHeader = React.createClass({
  propTypes: {
    small: React.PropTypes.element,
    full: React.PropTypes.element,
    headerStyle: React.PropTypes.object,
    smallStyle: React.PropTypes.object,
    fullStyle: React.PropTypes.object,
    smallClass: React.PropTypes.string,
    fullClass: React.PropTypes.string
  },
  getDefaultProps() {
    return {
      headerStyle: {
        width: 100 + '%',
        margin: 0
      },
    };
  },
  render() {
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
      <div style={headerStyle} className={classes}>
        <div style={headerStyle} className="navbar-brand">
          <ExpandableNavItem style={navItemStyle} ref="navItem"
            smallStyle={smallStyle} fullStyle={fullStyle}
            smallClass={this.props.smallClass} fullClass={this.props.fullClass}
            small={this.props.small} full={this.props.full} expanded={this.props.expanded}/>
        </div>
      </div>
    );
  },
  getNavItem() {
    return this.refs.navItem;
  }
});

module.exports = ExpandableNavHeader;
