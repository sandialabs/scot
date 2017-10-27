'use strict'

var React = require('react')
var PropTypes = require('prop-types')
var Tag = require('./Tag')
var Input = require('./Input')
var Suggestions = require('./Suggestions')

var KEYS = {
  ENTER: 13,
  TAB: 9,
  BACKSPACE: 8,
  UP_ARROW: 38,
  DOWN_ARROW: 40
}

var CLASS_NAMES = {
  root: 'react-tags',
  rootFocused: 'is-focused',
  selected: 'react-tags__selected',
  selectedTag: 'react-tags__selected-tag',
  selectedTagName: 'react-tags__selected-tag-name',
  search: 'react-tags__search',
  searchInput: 'react-tags__search-input',
  suggestions: 'react-tags__suggestions',
  suggestionActive: 'is-active',
  suggestionDisabled: 'is-disabled'
}

var ReactTags = (function (superclass) {
  function ReactTags (props) {
    superclass.call(this, props)

    this.state = {
      query: '',
      focused: false,
      expandable: false,
      selectedIndex: -1,
      classNames: Object.assign({}, CLASS_NAMES, this.props.classNames)
    }
  }

  if ( superclass ) ReactTags.__proto__ = superclass;
  ReactTags.prototype = Object.create( superclass && superclass.prototype );
  ReactTags.prototype.constructor = ReactTags;

  ReactTags.prototype.componentWillReceiveProps = function componentWillReceiveProps (newProps) {
    this.setState({
      classNames: Object.assign({}, CLASS_NAMES, newProps.classNames)
    })
  };

  ReactTags.prototype.handleChange = function handleChange (e) {
    var query = e.target.value

    if (this.props.handleInputChange) {
      this.props.handleInputChange(query)
    }

    this.setState({ query: query })
  };

  ReactTags.prototype.handleKeyDown = function handleKeyDown (e) {
    var ref = this.state;
    var query = ref.query;
    var selectedIndex = ref.selectedIndex;

    // when one of the terminating keys is pressed, add current query to the tags.
    if (this.props.delimiters.indexOf(e.keyCode) !== -1) {
      (query || selectedIndex > -1) && e.preventDefault()

      if (query.length >= this.props.minQueryLength) {
        // Check if the user typed in an existing suggestion.
        var match = this.suggestions.state.options.findIndex(function (suggestion) {
          return suggestion.name.search(new RegExp(("^" + query + "$"), 'i')) === 0
        })

        var index = selectedIndex === -1 ? match : selectedIndex

        if (index > -1) {
          this.addTag(this.suggestions.state.options[index])
        } else if (this.props.allowNew) {
          this.addTag({ name: query })
        }
      }
    }

    // when backspace key is pressed and query is blank, delete the last tag
    if (e.keyCode === KEYS.BACKSPACE && query.length === 0 && this.props.allowBackspace) {
      this.deleteTag(this.props.tags.length - 1)
    }

    if (e.keyCode === KEYS.UP_ARROW) {
      e.preventDefault()

      // if last item, cycle to the bottom
      if (selectedIndex <= 0) {
        this.setState({ selectedIndex: this.suggestions.state.options.length - 1 })
      } else {
        this.setState({ selectedIndex: selectedIndex - 1 })
      }
    }

    if (e.keyCode === KEYS.DOWN_ARROW) {
      e.preventDefault()

      this.setState({ selectedIndex: (selectedIndex + 1) % this.suggestions.state.options.length })
    }
  };

  ReactTags.prototype.handleClick = function handleClick (e) {
    if (document.activeElement !== e.target) {
      this.input.input.focus()
    }
  };

  ReactTags.prototype.handleBlur = function handleBlur () {
    this.setState({ focused: false, selectedIndex: -1 })
  };

  ReactTags.prototype.handleFocus = function handleFocus () {
    this.setState({ focused: true })
  };

  ReactTags.prototype.addTag = function addTag (tag) {
    if (tag.disabled) {
      return
    }

    this.props.handleAddition(tag)

    // reset the state
    this.setState({
      query: '',
      selectedIndex: -1
    })
  };

  ReactTags.prototype.deleteTag = function deleteTag (i) {
    this.props.handleDelete(i)
    this.setState({ query: '' })
  };

  ReactTags.prototype.render = function render () {
    var this$1 = this;

    var listboxId = 'ReactTags-listbox'

    var TagComponent = this.props.tagComponent || Tag

    var tags = this.props.tags.map(function (tag, i) { return (
      React.createElement( TagComponent, {
        key: i, tag: tag, classNames: this$1.state.classNames, onDelete: this$1.deleteTag.bind(this$1, i) })
    ); })

    var expandable = this.state.focused && this.state.query.length >= this.props.minQueryLength
    var classNames = [this.state.classNames.root]

    this.state.focused && classNames.push(this.state.classNames.rootFocused)

    return (
      React.createElement( 'div', { className: classNames.join(' '), onClick: this.handleClick.bind(this) },
        React.createElement( 'div', { className: this.state.classNames.selected, 'aria-live': 'polite', 'aria-relevant': 'additions removals' },
          tags
        ),
        React.createElement( 'div', {
          className: this.state.classNames.search, onBlur: this.handleBlur.bind(this), onFocus: this.handleFocus.bind(this), onChange: this.handleChange.bind(this), onKeyDown: this.handleKeyDown.bind(this) },
          React.createElement( Input, Object.assign({}, this.state, { ref: function (c) { this$1.input = c }, listboxId: listboxId, autofocus: this.props.autofocus, autoresize: this.props.autoresize, expandable: expandable, placeholder: this.props.placeholder })),
          React.createElement( Suggestions, Object.assign({}, this.state, { ref: function (c) { this$1.suggestions = c }, listboxId: listboxId, expandable: expandable, suggestions: this.props.suggestions, addTag: this.addTag.bind(this), maxSuggestionsLength: this.props.maxSuggestionsLength }))
        )
      )
    )
  };

  return ReactTags;
}(React.Component));

ReactTags.defaultProps = {
  tags: [],
  placeholder: 'Add new tag',
  suggestions: [],
  autofocus: true,
  autoresize: true,
  delimiters: [KEYS.TAB, KEYS.ENTER],
  minQueryLength: 2,
  maxSuggestionsLength: 6,
  allowNew: false,
  allowBackspace: true,
  tagComponent: null
}

ReactTags.propTypes = {
  tags: PropTypes.arrayOf(PropTypes.object),
  placeholder: PropTypes.string,
  suggestions: PropTypes.arrayOf(PropTypes.object),
  autofocus: PropTypes.bool,
  autoresize: PropTypes.bool,
  delimiters: PropTypes.arrayOf(PropTypes.number),
  handleDelete: PropTypes.func.isRequired,
  handleAddition: PropTypes.func.isRequired,
  handleInputChange: PropTypes.func,
  minQueryLength: PropTypes.number,
  maxSuggestionsLength: PropTypes.number,
  classNames: PropTypes.object,
  allowNew: PropTypes.bool,
  allowBackspace: PropTypes.bool,
  tagComponent: PropTypes.oneOfType([
    PropTypes.func,
    PropTypes.element
  ])
}

module.exports = ReactTags
