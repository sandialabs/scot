/** @jsx React.DOM */

var React = require('react');
var buildClassName = require('../mixins/buildClassName');

var MenuTrigger = module.exports = React.createClass({

  contextTypes: {
    id: React.PropTypes.string,
    active: React.PropTypes.bool
  },

  mixins: [buildClassName],

  toggleActive: function() {
    this.props.onToggleActive(!this.context.active);
  },

  handleKeyUp: function(e) {
    if (e.key === ' ')
      this.toggleActive();
  },

  handleKeyDown: function(e) {
    if (e.key === 'Enter')
      this.toggleActive();
  },

  handleClick: function() {
    this.toggleActive();
  },

  render: function() {
    var triggerClassName =
      this.buildClassName(
        'Menu__MenuTrigger ' +
        (this.context.active
        ? 'Menu__MenuTrigger__active'
        : 'Menu__MenuTrigger__inactive')
      );

    return (
      <div
        className={triggerClassName}
        onClick={this.handleClick}
        onKeyUp={this.handleKeyUp}
        onKeyDown={this.handleKeyDown}
        tabIndex="0"
        role="button"
        aria-owns={this.context.id}
        aria-haspopup="true"
      >
        {this.props.children}
      </div>
    )
  }

});
