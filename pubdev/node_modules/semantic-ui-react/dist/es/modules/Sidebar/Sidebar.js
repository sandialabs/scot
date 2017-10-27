import _extends from 'babel-runtime/helpers/extends';
import _classCallCheck from 'babel-runtime/helpers/classCallCheck';
import _createClass from 'babel-runtime/helpers/createClass';
import _possibleConstructorReturn from 'babel-runtime/helpers/possibleConstructorReturn';
import _inherits from 'babel-runtime/helpers/inherits';
import cx from 'classnames';
import React, { PropTypes } from 'react';

import { AutoControlledComponent as Component, customPropTypes, getUnhandledProps, getElementType, META, useKeyOnly } from '../../lib';
import SidebarPushable from './SidebarPushable';
import SidebarPusher from './SidebarPusher';

/**
 * A sidebar hides additional content beside a page.
 */

var Sidebar = function (_Component) {
  _inherits(Sidebar, _Component);

  function Sidebar() {
    var _ref;

    var _temp, _this, _ret;

    _classCallCheck(this, Sidebar);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = _possibleConstructorReturn(this, (_ref = Sidebar.__proto__ || Object.getPrototypeOf(Sidebar)).call.apply(_ref, [this].concat(args))), _this), _this.state = {}, _this.startAnimating = function () {
      var duration = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : 500;

      clearTimeout(_this.stopAnimatingTimer);

      _this.setState({ animating: true });

      _this.stopAnimatingTimer = setTimeout(function () {
        return _this.setState({ animating: false });
      }, duration);
    }, _temp), _possibleConstructorReturn(_this, _ret);
  }

  _createClass(Sidebar, [{
    key: 'componentWillReceiveProps',
    value: function componentWillReceiveProps(nextProps) {
      if (nextProps.visible !== this.props.visible) {
        this.startAnimating();
      }
    }
  }, {
    key: 'render',
    value: function render() {
      var _props = this.props,
          animation = _props.animation,
          className = _props.className,
          children = _props.children,
          direction = _props.direction,
          visible = _props.visible,
          width = _props.width;
      var animating = this.state.animating;


      var classes = cx('ui', animation, direction, width, useKeyOnly(animating, 'animating'), useKeyOnly(visible, 'visible'), 'sidebar', className);

      var rest = getUnhandledProps(Sidebar, this.props);
      var ElementType = getElementType(Sidebar, this.props);

      return React.createElement(
        ElementType,
        _extends({}, rest, { className: classes }),
        children
      );
    }
  }]);

  return Sidebar;
}(Component);

Sidebar.defaultProps = {
  direction: 'left'
};
Sidebar.autoControlledProps = ['visible'];
Sidebar._meta = {
  name: 'Sidebar',
  type: META.TYPES.MODULE
};
Sidebar.Pushable = SidebarPushable;
Sidebar.Pusher = SidebarPusher;
process.env.NODE_ENV !== "production" ? Sidebar.propTypes = {
  /** An element type to render as (string or function). */
  as: customPropTypes.as,

  /** Animation style. */
  animation: PropTypes.oneOf(['overlay', 'push', 'scale down', 'uncover', 'slide out', 'slide along']),

  /** Primary content. */
  children: PropTypes.node,

  /** Additional classes. */
  className: PropTypes.string,

  /** Initial value of visible. */
  defaultVisible: PropTypes.bool,

  /** Direction the sidebar should appear on. */
  direction: PropTypes.oneOf(['top', 'right', 'bottom', 'left']),

  /** Controls whether or not the sidebar is visible on the page. */
  visible: PropTypes.bool,

  /** Sidebar width. */
  width: PropTypes.oneOf(['very thin', 'thin', 'wide', 'very wide'])
} : void 0;
Sidebar.handledProps = ['animation', 'as', 'children', 'className', 'defaultVisible', 'direction', 'visible', 'width'];


export default Sidebar;