var ReactDOM = require('react-dom');
var elementResizeEvent = require('element-resize-event');

module.exports = {
  getInitialState: function() {
    if (this.props.initialComponentWidth !== undefined && this.props.initialComponentWidth !== null) {
      return {
        componentWidth: this.props.initialComponentWidth
      };
    } else {
      return {};
    }
  },
  // Add our resize sensor.
  componentDidMount: function() {
    this.setState({
      componentWidth: ReactDOM.findDOMNode(this).getBoundingClientRect().width
    });
    elementResizeEvent(ReactDOM.findDOMNode(this), this.onResize);
  },
  // When the DOM updates, check that our resize sensor is still there.
  componentDidUpdate: function() {
    if (0 === ReactDOM.findDOMNode(this).getElementsByClassName('resize-sensor').length) {
      elementResizeEvent(ReactDOM.findDOMNode(this), this.onResize);
    }
  },
  onResize: function() {
    this.setState({
      componentWidth: ReactDOM.findDOMNode(this).getBoundingClientRect().width
    });
  }
};
