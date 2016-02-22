'use strict';

exports.__esModule = true;

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

function _objectWithoutProperties(obj, keys) { var target = {}; for (var i in obj) { if (keys.indexOf(i) >= 0) continue; if (!Object.prototype.hasOwnProperty.call(obj, i)) continue; target[i] = obj[i]; } return target; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError('Cannot call a class as a function'); } }

function _inherits(subClass, superClass) { if (typeof superClass !== 'function' && superClass !== null) { throw new TypeError('Super expression must either be null or a function, not ' + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var _attrAccept = require('attr-accept');

var _attrAccept2 = _interopRequireDefault(_attrAccept);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var supportMultiple = typeof document !== 'undefined' && document && document.createElement ? 'multiple' in document.createElement('input') : true;

var Dropzone = (function (_React$Component) {
  _inherits(Dropzone, _React$Component);

  function Dropzone(props, context) {
    _classCallCheck(this, Dropzone);

    _React$Component.call(this, props, context);
    this.onClick = this.onClick.bind(this);
    this.onDragEnter = this.onDragEnter.bind(this);
    this.onDragLeave = this.onDragLeave.bind(this);
    this.onDragOver = this.onDragOver.bind(this);
    this.onDrop = this.onDrop.bind(this);

    this.state = {
      isDragActive: false
    };
  }

  Dropzone.prototype.componentDidMount = function componentDidMount() {
    this.enterCounter = 0;
  };

  Dropzone.prototype.onDragEnter = function onDragEnter(e) {
    e.preventDefault();

    // Count the dropzone and any children that are entered.
    ++this.enterCounter;

    // This is tricky. During the drag even the dataTransfer.files is null
    // But Chrome implements some drag store, which is accesible via dataTransfer.items
    var dataTransferItems = e.dataTransfer && e.dataTransfer.items ? e.dataTransfer.items : [];

    // Now we need to convert the DataTransferList to Array
    var allFilesAccepted = this.allFilesAccepted(Array.prototype.slice.call(dataTransferItems));

    this.setState({
      isDragActive: allFilesAccepted,
      isDragReject: !allFilesAccepted
    });

    if (this.props.onDragEnter) {
      this.props.onDragEnter.call(this, e);
    }
  };

  Dropzone.prototype.onDragOver = function onDragOver(e) {
    e.preventDefault();
    e.stopPropagation();
    return false;
  };

  Dropzone.prototype.onDragLeave = function onDragLeave(e) {
    e.preventDefault();

    // Only deactivate once the dropzone and all children was left.
    if (--this.enterCounter > 0) {
      return;
    }

    this.setState({
      isDragActive: false,
      isDragReject: false
    });

    if (this.props.onDragLeave) {
      this.props.onDragLeave.call(this, e);
    }
  };

  Dropzone.prototype.onDrop = function onDrop(e) {
    e.preventDefault();

    // Reset the counter along with the drag on a drop.
    this.enterCounter = 0;

    this.setState({
      isDragActive: false,
      isDragReject: false
    });

    var droppedFiles = e.dataTransfer ? e.dataTransfer.files : e.target.files;
    var max = this.props.multiple ? droppedFiles.length : 1;
    var files = [];

    for (var i = 0; i < max; i++) {
      var file = droppedFiles[i];
      // We might want to disable the preview creation to support big files
      if (!this.props.disablePreview) {
        file.preview = window.URL.createObjectURL(file);
      }
      files.push(file);
    }

    if (this.props.onDrop) {
      this.props.onDrop.call(this, files, e);
    }

    if (this.allFilesAccepted(files)) {
      if (this.props.onDropAccepted) {
        this.props.onDropAccepted.call(this, files, e);
      }
    } else {
      if (this.props.onDropRejected) {
        this.props.onDropRejected.call(this, files, e);
      }
    }
  };

  Dropzone.prototype.onClick = function onClick() {
    if (!this.props.disableClick) {
      this.open();
    }
  };

  Dropzone.prototype.allFilesAccepted = function allFilesAccepted(files) {
    var _this = this;

    return files.every(function (file) {
      return _attrAccept2['default'](file, _this.props.accept);
    });
  };

  Dropzone.prototype.open = function open() {
    this.fileInputEl.value = null;
    this.fileInputEl.click();
  };

  Dropzone.prototype.render = function render() {
    var _this2 = this;

    var _props = this.props;
    var accept = _props.accept;
    var activeClassName = _props.activeClassName;
    var inputProps = _props.inputProps;
    var multiple = _props.multiple;
    var name = _props.name;
    var rejectClassName = _props.rejectClassName;

    var rest = _objectWithoutProperties(_props, ['accept', 'activeClassName', 'inputProps', 'multiple', 'name', 'rejectClassName']);

    var activeStyle = // eslint-disable-line prefer-const
    rest.activeStyle;
    var className = rest.className;
    var rejectStyle = rest.rejectStyle;
    var style = rest.style;

    var props = _objectWithoutProperties(rest, ['activeStyle', 'className', 'rejectStyle', 'style']);

    var _state = this.state;
    var isDragActive = _state.isDragActive;
    var isDragReject = _state.isDragReject;

    className = className || '';

    if (isDragActive && activeClassName) {
      className += ' ' + activeClassName;
    }
    if (isDragReject && rejectClassName) {
      className += ' ' + rejectClassName;
    }

    if (!className && !style && !activeStyle && !rejectStyle) {
      style = {
        width: 200,
        height: 200,
        borderWidth: 2,
        borderColor: '#666',
        borderStyle: 'dashed',
        borderRadius: 5
      };
      activeStyle = {
        borderStyle: 'solid',
        backgroundColor: '#eee'
      };
      rejectStyle = {
        borderStyle: 'solid',
        backgroundColor: '#ffdddd'
      };
    }

    var appliedStyle = undefined;
    if (activeStyle && isDragActive) {
      appliedStyle = _extends({}, style, activeStyle);
    } else if (rejectStyle && isDragReject) {
      appliedStyle = _extends({}, style, rejectStyle);
    } else {
      appliedStyle = _extends({}, style);
    }

    var inputAttributes = {
      accept: accept,
      type: 'file',
      style: { display: 'none' },
      multiple: supportMultiple && multiple,
      ref: function ref(el) {
        return _this2.fileInputEl = el;
      },
      onChange: this.onDrop
    };

    if (name && name.length) {
      inputAttributes.name = name;
    }

    return _react2['default'].createElement(
      'div',
      _extends({
        className: className,
        style: appliedStyle
      }, props, /* expand user provided props first so event handlers are never overridden */{
        onClick: this.onClick,
        onDragEnter: this.onDragEnter,
        onDragOver: this.onDragOver,
        onDragLeave: this.onDragLeave,
        onDrop: this.onDrop
      }),
      this.props.children,
      _react2['default'].createElement('input', _extends({}, inputProps, /* expand user provided inputProps first so inputAttributes override them */inputAttributes))
    );
  };

  return Dropzone;
})(_react2['default'].Component);

Dropzone.defaultProps = {
  disablePreview: false,
  disableClick: false,
  multiple: true
};

Dropzone.propTypes = {
  onDrop: _react2['default'].PropTypes.func,
  onDropAccepted: _react2['default'].PropTypes.func,
  onDropRejected: _react2['default'].PropTypes.func,
  onDragEnter: _react2['default'].PropTypes.func,
  onDragLeave: _react2['default'].PropTypes.func,

  children: _react2['default'].PropTypes.node,
  style: _react2['default'].PropTypes.object,
  activeStyle: _react2['default'].PropTypes.object,
  rejectStyle: _react2['default'].PropTypes.object,
  className: _react2['default'].PropTypes.string,
  activeClassName: _react2['default'].PropTypes.string,
  rejectClassName: _react2['default'].PropTypes.string,

  disablePreview: _react2['default'].PropTypes.bool,
  disableClick: _react2['default'].PropTypes.bool,

  inputProps: _react2['default'].PropTypes.object,
  multiple: _react2['default'].PropTypes.bool,
  accept: _react2['default'].PropTypes.string,
  name: _react2['default'].PropTypes.string
};

exports['default'] = Dropzone;
module.exports = exports['default'];