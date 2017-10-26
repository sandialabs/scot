'use strict'

var React = require('react')

var SIZER_STYLES = {
  position: 'absolute',
  width: 0,
  height: 0,
  visibility: 'hidden',
  overflow: 'scroll',
  whiteSpace: 'pre'
}

var STYLE_PROPS = [
  'fontSize',
  'fontFamily',
  'fontWeight',
  'fontStyle',
  'letterSpacing'
]

var Input = (function (superclass) {
  function Input (props) {
    superclass.call(this, props)
    this.state = { inputWidth: null }
  }

  if ( superclass ) Input.__proto__ = superclass;
  Input.prototype = Object.create( superclass && superclass.prototype );
  Input.prototype.constructor = Input;

  Input.prototype.componentDidMount = function componentDidMount () {
    if (this.props.autoresize) {
      this.copyInputStyles()
      this.updateInputWidth()
    }

    if (this.props.autofocus) {
      this.input.focus()
    }
  };

  Input.prototype.componentDidUpdate = function componentDidUpdate (prevProps) {
    this.updateInputWidth()
  };

  Input.prototype.componentWillReceiveProps = function componentWillReceiveProps (newProps) {
    if (this.input.value !== newProps.query) {
      this.input.value = newProps.query
    }
  };

  Input.prototype.copyInputStyles = function copyInputStyles () {
    var this$1 = this;

    var inputStyle = window.getComputedStyle(this.input)

    STYLE_PROPS.forEach(function (prop) {
      this$1.sizer.style[prop] = inputStyle[prop]
    })
  };

  Input.prototype.updateInputWidth = function updateInputWidth () {
    var inputWidth

    if (this.props.autoresize) {
      // scrollWidth is designed to be fast not accurate.
      // +2 is completely arbitrary but does the job.
      inputWidth = Math.ceil(this.sizer.scrollWidth) + 2
    }

    if (inputWidth !== this.state.inputWidth) {
      this.setState({ inputWidth: inputWidth })
    }
  };

  Input.prototype.render = function render () {
    var this$1 = this;

    var sizerText = this.props.query || this.props.placeholder

    var ref = this.props;
    var expandable = ref.expandable;
    var placeholder = ref.placeholder;
    var listboxId = ref.listboxId;
    var selectedIndex = ref.selectedIndex;

    var selectedId = listboxId + "-" + selectedIndex

    return (
      React.createElement( 'div', { className: this.props.classNames.searchInput },
        React.createElement( 'input', {
          ref: function (c) { this$1.input = c }, role: 'combobox', 'aria-autocomplete': 'list', 'aria-label': placeholder, 'aria-owns': listboxId, 'aria-activedescendant': selectedIndex > -1 ? selectedId : null, 'aria-expanded': expandable, placeholder: placeholder, style: { width: this.state.inputWidth } }),
        React.createElement( 'div', { ref: function (c) { this$1.sizer = c }, style: SIZER_STYLES }, sizerText)
      )
    )
  };

  return Input;
}(React.Component));

module.exports = Input
