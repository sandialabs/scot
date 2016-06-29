'use strict';

var React = require('react'),
    assign = require('object-assign');

var ExpandableNavPage = React.createClass({displayName: "ExpandableNavPage",
  propTypes: {
    fullStyle: React.PropTypes.object,
    smallStyle: React.PropTypes.object,
    fullClass: React.PropTypes.string,
    smallClass: React.PropTypes.string
  },
  getDefaultProps:function() {
    return {
      fullStyle: {
        paddingTop: 10,
        paddingBottom: 10,
        paddingLeft: 240,
        paddingRight: 60
      },
      smallStyle: {
        paddingTop: 10,
        paddingBottom: 10,
        paddingLeft: 60,
        paddingRight: 60
      }
    };
  },
  render:function() {
    var style = assign(this.props.expanded ? this.props.fullStyle : this.props.smallStyle,
                      this.props.style);
    var classes = this.props.expanded ? this.props.fullClass : this.props.smallClass;
    return (
      React.createElement("div", {style: style, className: classes}, 
        this.props.children
      )
    );
  }
});

module.exports = ExpandableNavPage;
