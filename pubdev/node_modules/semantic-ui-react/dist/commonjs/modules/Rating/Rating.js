'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = require('babel-runtime/helpers/extends');

var _extends3 = _interopRequireDefault(_extends2);

var _classCallCheck2 = require('babel-runtime/helpers/classCallCheck');

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = require('babel-runtime/helpers/createClass');

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = require('babel-runtime/helpers/possibleConstructorReturn');

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = require('babel-runtime/helpers/inherits');

var _inherits3 = _interopRequireDefault(_inherits2);

var _times2 = require('lodash/times');

var _times3 = _interopRequireDefault(_times2);

var _invoke2 = require('lodash/invoke');

var _invoke3 = _interopRequireDefault(_invoke2);

var _without2 = require('lodash/without');

var _without3 = _interopRequireDefault(_without2);

var _classnames = require('classnames');

var _classnames2 = _interopRequireDefault(_classnames);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _lib = require('../../lib');

var _RatingIcon = require('./RatingIcon');

var _RatingIcon2 = _interopRequireDefault(_RatingIcon);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * A rating indicates user interest in content.
 */
var Rating = function (_Component) {
  (0, _inherits3.default)(Rating, _Component);

  function Rating() {
    var _ref;

    var _temp, _this, _ret;

    (0, _classCallCheck3.default)(this, Rating);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = (0, _possibleConstructorReturn3.default)(this, (_ref = Rating.__proto__ || Object.getPrototypeOf(Rating)).call.apply(_ref, [this].concat(args))), _this), _initialiseProps.call(_this), _temp), (0, _possibleConstructorReturn3.default)(_this, _ret);
  }

  (0, _createClass3.default)(Rating, [{
    key: 'render',
    value: function render() {
      var _this2 = this;

      var _props = this.props,
          className = _props.className,
          disabled = _props.disabled,
          icon = _props.icon,
          maxRating = _props.maxRating,
          size = _props.size;
      var _state = this.state,
          rating = _state.rating,
          selectedIndex = _state.selectedIndex,
          isSelecting = _state.isSelecting;


      var classes = (0, _classnames2.default)('ui', icon, size, (0, _lib.useKeyOnly)(disabled, 'disabled'), (0, _lib.useKeyOnly)(isSelecting && !disabled && selectedIndex >= 0, 'selected'), 'rating', className);
      var rest = (0, _lib.getUnhandledProps)(Rating, this.props);
      var ElementType = (0, _lib.getElementType)(Rating, this.props);

      return _react2.default.createElement(
        ElementType,
        (0, _extends3.default)({}, rest, { className: classes, role: 'radiogroup', onMouseLeave: this.handleMouseLeave }),
        (0, _times3.default)(maxRating, function (i) {
          return _react2.default.createElement(_RatingIcon2.default, {
            active: rating >= i + 1,
            'aria-checked': rating === i + 1,
            'aria-posinset': i + 1,
            'aria-setsize': maxRating,
            index: i,
            key: i,
            onClick: _this2.handleIconClick,
            onMouseEnter: _this2.handleIconMouseEnter,
            selected: selectedIndex >= i && isSelecting
          });
        })
      );
    }
  }]);
  return Rating;
}(_lib.AutoControlledComponent);

Rating.autoControlledProps = ['rating'];
Rating.defaultProps = {
  clearable: 'auto',
  maxRating: 1
};
Rating._meta = {
  name: 'Rating',
  type: _lib.META.TYPES.MODULE
};
Rating.Icon = _RatingIcon2.default;

var _initialiseProps = function _initialiseProps() {
  var _this3 = this;

  this.handleIconClick = function (e, _ref2) {
    var index = _ref2.index;
    var _props2 = _this3.props,
        clearable = _props2.clearable,
        disabled = _props2.disabled,
        maxRating = _props2.maxRating,
        onRate = _props2.onRate;
    var rating = _this3.state.rating;

    if (disabled) return;

    // default newRating is the clicked icon
    // allow toggling a binary rating
    // allow clearing ratings
    var newRating = index + 1;
    if (clearable === 'auto' && maxRating === 1) {
      newRating = +!rating;
    } else if (clearable === true && newRating === rating) {
      newRating = 0;
    }

    // set rating
    _this3.trySetState({ rating: newRating }, { isSelecting: false });
    if (onRate) onRate(e, (0, _extends3.default)({}, _this3.props, { rating: newRating }));
  };

  this.handleIconMouseEnter = function (e, _ref3) {
    var index = _ref3.index;

    if (_this3.props.disabled) return;

    _this3.setState({ selectedIndex: index, isSelecting: true });
  };

  this.handleMouseLeave = function () {
    for (var _len2 = arguments.length, args = Array(_len2), _key2 = 0; _key2 < _len2; _key2++) {
      args[_key2] = arguments[_key2];
    }

    _invoke3.default.apply(undefined, [_this3.props, 'onMouseLeave'].concat(args));

    if (_this3.props.disabled) return;

    _this3.setState({ selectedIndex: -1, isSelecting: false });
  };
};

exports.default = Rating;
process.env.NODE_ENV !== "production" ? Rating.propTypes = {
  /** An element type to render as (string or function). */
  as: _lib.customPropTypes.as,

  /** Additional classes. */
  className: _react.PropTypes.string,

  /**
   * You can clear the rating by clicking on the current start rating.
   * By default a rating will be only clearable if there is 1 icon.
   * Setting to `true`/`false` will allow or disallow a user to clear their rating.
   */
  clearable: _react.PropTypes.oneOfType([_react.PropTypes.bool, _react.PropTypes.oneOf(['auto'])]),

  /** The initial rating value. */
  defaultRating: _react.PropTypes.oneOfType([_react.PropTypes.number, _react.PropTypes.string]),

  /** You can disable or enable interactive rating.  Makes a read-only rating. */
  disabled: _react.PropTypes.bool,

  /** A rating can use a set of star or heart icons. */
  icon: _react.PropTypes.oneOf(['star', 'heart']),

  /** The total number of icons. */
  maxRating: _react.PropTypes.oneOfType([_react.PropTypes.number, _react.PropTypes.string]),

  /**
   * Called after user selects a new rating.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props and proposed rating.
   */
  onRate: _react.PropTypes.func,

  /** The current number of active icons. */
  rating: _react.PropTypes.oneOfType([_react.PropTypes.number, _react.PropTypes.string]),

  /** A progress bar can vary in size. */
  size: _react.PropTypes.oneOf((0, _without3.default)(_lib.SUI.SIZES, 'medium', 'big'))
} : void 0;
Rating.handledProps = ['as', 'className', 'clearable', 'defaultRating', 'disabled', 'icon', 'maxRating', 'onRate', 'rating', 'size'];