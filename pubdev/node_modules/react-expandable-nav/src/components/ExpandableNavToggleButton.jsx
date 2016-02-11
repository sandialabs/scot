'use strict';

var React = require('react/addons');

var assign = require('object-assign'),
    joinClasses = require('../utils/joinClasses');

var ExpandableNavToggleButton = React.createClass({
  propTypes: {
    small: React.PropTypes.element,
    full: React.PropTypes.element,
    smallStyle: React.PropTypes.object,
    fullStyle: React.PropTypes.object,
    smallClass: React.PropTypes.string,
    fullClass: React.PropTypes.string
  },
  getDefaultProps() {
    return {
      small: <span className="glyphicon glyphicon-chevron-right"></span>,
      full: <span className="glyphicon glyphicon-chevron-left"></span>,
      smallStyle: {top: 5, left: 55},
      fullStyle: {top: 5, left: 245}
    };
  },
  render() {
    return (
      <div>
        {this.renderToggleButton()}
      </div>
    );
  },
  renderToggleButton() {
    var toggleButton, style, classes;

    var sharedStyle = {
      position: 'fixed',
    };

    style = assign(sharedStyle, this.props.style || {});

    if (this.props.expanded) {
      toggleButton = this.props.full;
      style = assign(style, this.props.fullStyle);
      classes = this.props.fullClass;
    } else {
      toggleButton = this.props.small;
      style = assign(style, this.props.smallStyle);
      classes = this.props.smallClass;
    }

    return React.addons.cloneWithProps(toggleButton, {
      ref: toggleButton.ref,
      className: joinClasses(this.props.className, classes),
      style: style,
      onClick: this.props.handleToggle
    });
  }
});

module.exports = ExpandableNavToggleButton;
