/** @jsx React.DOM */

var React = require('react');
var MenuOption = require('./MenuOption');
var cloneWithProps = require('react/lib/cloneWithProps')
var buildClassName = require('../mixins/buildClassName');

var MenuOptions = module.exports = React.createClass({

  contextTypes: {
    id: React.PropTypes.string,
    active: React.PropTypes.bool
  },

  getInitialState: function() {
    return {activeIndex: 0}
  },

  mixins: [buildClassName],

  onSelectionMade: function() {
    this.props.onSelectionMade();
  },


  moveSelectionUp: function() {
    this.updateFocusIndexBy(-1);
  },

  moveSelectionDown: function() {
    this.updateFocusIndexBy(1);
  },

  handleKeys: function(e) {
    var options = {
      'ArrowDown': this.moveSelectionDown,
      'ArrowUp': this.moveSelectionUp,
      'Escape': this.closeMenu
    }
    if(options[e.key]){
      options[e.key].call(this);
    }
  },

  normalizeSelectedBy: function(delta, numOptions){
    this.selectedIndex += delta;
    if (this.selectedIndex > numOptions - 1) {
      this.selectedIndex = 0;
    } else if (this.selectedIndex < 0) {
      this.selectedIndex = numOptions - 1;
    }
  },

  focusOption: function(index) {
    this.selectedIndex = index;
    this.updateFocusIndexBy(0);
  },

  updateFocusIndexBy: function(delta) {
    var optionNodes = this.getDOMNode().querySelectorAll('.Menu__MenuOption');
    this.normalizeSelectedBy(delta, optionNodes.length);
    this.setState({activeIndex: this.selectedIndex}, function () {
      optionNodes[this.selectedIndex].focus();
    });
  },

  renderOptions: function() {
    var index = 0;
    return React.Children.map(this.props.children, function(c){
      var clonedOption = c;
      if (c.type === MenuOption.type) {
        var active = this.state.activeIndex === index;
        clonedOption = cloneWithProps(c, {
          active: active,
          index: index,
          _internalFocus: this.focusOption,
          _internalSelect: this.onSelectionMade
        });
        index++;
      }
      return clonedOption;
    }.bind(this));
  },

  buildName: function() {
    var cn = this.buildClassName('Menu__MenuOptions');
    cn += ' Menu__MenuOptions--horizontal-' + this.props.horizontalPlacement;
    cn += ' Menu__MenuOptions--vertical-' + this.props.verticalPlacement;
    return cn;
  },

  render: function() {
    return (
      <div
        id={this.context.id}
        role="menu"
        tabIndex="-1"
        aria-expanded={this.context.active}
        style={{visibility: this.context.active ? 'visible' : 'hidden'}}
        className={this.buildName()}
        onKeyDown={this.handleKeys}
      >
        {this.renderOptions()}
      </div>
    )
  }

});
