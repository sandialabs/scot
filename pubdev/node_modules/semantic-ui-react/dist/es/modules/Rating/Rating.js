import _extends from 'babel-runtime/helpers/extends';
import _classCallCheck from 'babel-runtime/helpers/classCallCheck';
import _createClass from 'babel-runtime/helpers/createClass';
import _possibleConstructorReturn from 'babel-runtime/helpers/possibleConstructorReturn';
import _inherits from 'babel-runtime/helpers/inherits';
import _times from 'lodash/times';
import _invoke from 'lodash/invoke';
import _without from 'lodash/without';
import cx from 'classnames';

import React, { PropTypes } from 'react';

import { AutoControlledComponent as Component, customPropTypes, getElementType, getUnhandledProps, META, SUI, useKeyOnly } from '../../lib';
import RatingIcon from './RatingIcon';

/**
 * A rating indicates user interest in content.
 */

var Rating = function (_Component) {
  _inherits(Rating, _Component);

  function Rating() {
    var _ref;

    var _temp, _this, _ret;

    _classCallCheck(this, Rating);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = _possibleConstructorReturn(this, (_ref = Rating.__proto__ || Object.getPrototypeOf(Rating)).call.apply(_ref, [this].concat(args))), _this), _initialiseProps.call(_this), _temp), _possibleConstructorReturn(_this, _ret);
  }

  _createClass(Rating, [{
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


      var classes = cx('ui', icon, size, useKeyOnly(disabled, 'disabled'), useKeyOnly(isSelecting && !disabled && selectedIndex >= 0, 'selected'), 'rating', className);
      var rest = getUnhandledProps(Rating, this.props);
      var ElementType = getElementType(Rating, this.props);

      return React.createElement(
        ElementType,
        _extends({}, rest, { className: classes, role: 'radiogroup', onMouseLeave: this.handleMouseLeave }),
        _times(maxRating, function (i) {
          return React.createElement(RatingIcon, {
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
}(Component);

Rating.autoControlledProps = ['rating'];
Rating.defaultProps = {
  clearable: 'auto',
  maxRating: 1
};
Rating._meta = {
  name: 'Rating',
  type: META.TYPES.MODULE
};
Rating.Icon = RatingIcon;

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
    if (onRate) onRate(e, _extends({}, _this3.props, { rating: newRating }));
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

    _invoke.apply(undefined, [_this3.props, 'onMouseLeave'].concat(args));

    if (_this3.props.disabled) return;

    _this3.setState({ selectedIndex: -1, isSelecting: false });
  };
};

export default Rating;
process.env.NODE_ENV !== "production" ? Rating.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Additional classes. */
  className: PropTypes.string,

  /**
   * You can clear the rating by clicking on the current start rating.
   * By default a rating will be only clearable if there is 1 icon.
   * Setting to `true`/`false` will allow or disallow a user to clear their rating.
   */
  clearable: PropTypes.oneOfType([PropTypes.bool, PropTypes.oneOf(['auto'])]),

  /** The initial rating value. */
  defaultRating: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),

  /** You can disable or enable interactive rating.  Makes a read-only rating. */
  disabled: PropTypes.bool,

  /** A rating can use a set of star or heart icons. */
  icon: PropTypes.oneOf(['star', 'heart']),

  /** The total number of icons. */
  maxRating: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),

  /**
   * Called after user selects a new rating.
   *
   * @param {SyntheticEvent} event - React's original SyntheticEvent.
   * @param {object} data - All props and proposed rating.
   */
  onRate: PropTypes.func,

  /** The current number of active icons. */
  rating: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),

  /** A progress bar can vary in size. */
  size: PropTypes.oneOf(_without(SUI.SIZES, 'medium', 'big'))
} : void 0;
Rating.handledProps = ['as', 'className', 'clearable', 'defaultRating', 'disabled', 'icon', 'maxRating', 'onRate', 'rating', 'size'];