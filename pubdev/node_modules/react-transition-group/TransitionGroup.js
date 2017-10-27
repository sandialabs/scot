'use strict';

exports.__esModule = true;

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _propTypes = require('prop-types');

var _propTypes2 = _interopRequireDefault(_propTypes);

var _react = require('react');

var _react2 = _interopRequireDefault(_react);

var _ChildMapping = require('./utils/ChildMapping');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) { var target = {}; for (var i in obj) { if (keys.indexOf(i) >= 0) continue; if (!Object.prototype.hasOwnProperty.call(obj, i)) continue; target[i] = obj[i]; } return target; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var values = Object.values || function (obj) {
  return Object.keys(obj).map(function (k) {
    return obj[k];
  });
};

var propTypes = {
  /**
   * `<TransitionGroup>` renders a `<div>` by default. You can change this
   * behavior by providing a `component` prop.
   */
  component: _propTypes2.default.any,
  /**
   * A set of `<Transition>` components, that are toggled `in` and out as they
   * leave. the `<TransitionGroup>` will inject specific transition props, so
   * remember to spread them through if you are wrapping the `<Transition>` as
   * with our `<Fade>` example.
   */
  children: _propTypes2.default.node,

  /**
   * A convenience prop that enables or disabled appear animations
   * for all children. Note that specifying this will override any defaults set
   * on individual children Transitions.
   */
  appear: _propTypes2.default.bool,
  /**
   * A convenience prop that enables or disabled enter animations
   * for all children. Note that specifying this will override any defaults set
   * on individual children Transitions.
   */
  enter: _propTypes2.default.bool,
  /**
    * A convenience prop that enables or disabled exit animations
    * for all children. Note that specifying this will override any defaults set
    * on individual children Transitions.
    */
  exit: _propTypes2.default.bool,

  /**
   * You may need to apply reactive updates to a child as it is exiting.
   * This is generally done by using `cloneElement` however in the case of an exiting
   * child the element has already been removed and not accessible to the consumer.
   *
   * If you do need to update a child as it leaves you can provide a `childFactory`
   * to wrap every child, even the ones that are leaving.
   *
   * @type Function(child: ReactElement) -> ReactElement
   */
  childFactory: _propTypes2.default.func
};

var defaultProps = {
  component: 'div',
  childFactory: function childFactory(child) {
    return child;
  }
};

/**
 * The `<TransitionGroup>` component manages a set of `<Transition>` components
 * in a list. Like with the `<Transition>` component, `<TransitionGroup>`, is a
 * state machine for managing the mounting and unmounting of components over
 * time.
 *
 * Consider the example below using the `Fade` CSS transition from before.
 * As items are removed or added to the TodoList the `in` prop is toggled
 * automatically by the `<TransitionGroup>`. You can use _any_ `<Transition>`
 * component in a `<TransitionGroup>`, not just css.
 *
 * ```jsx
 * import TransitionGroup from 'react-transition-group/TransitionGroup';
 *
 * class TodoList extends React.Component {
 *   constructor(props) {
 *     super(props)
 *     this.state = {items: ['hello', 'world', 'click', 'me']}
 *   }
 *   handleAdd() {
 *     const newItems = this.state.items.concat([
 *       prompt('Enter some text')
 *     ]);
 *     this.setState({ items: newItems });
 *   }
 *   handleRemove(i) {
 *     let newItems = this.state.items.slice();
 *     newItems.splice(i, 1);
 *     this.setState({items: newItems});
 *   }
 *   render() {
 *     return (
 *       <div>
 *         <button onClick={() => this.handleAdd()}>Add Item</button>
 *         <TransitionGroup>
 *           {this.state.items.map((item, i) => (
 *             <FadeTransition key={item}>
 *               <div>
 *                 {item}{' '}
 *                 <button onClick={() => this.handleRemove(i)}>
 *                   remove
 *                 </button>
 *               </div>
 *             </FadeTransition>
 *           ))}
 *         </TransitionGroup>
 *       </div>
 *     );
 *   }
 * }
 * ```
 *
 * Note that `<TransitionGroup>`  does not define any animation behavior!
 * Exactly _how_ a list item animates is up to the individual `<Transition>`
 * components. This means you can mix and match animations across different
 * list items.
 */

var TransitionGroup = function (_React$Component) {
  _inherits(TransitionGroup, _React$Component);

  function TransitionGroup(props, context) {
    _classCallCheck(this, TransitionGroup);

    // Initial children should all be entering, dependent on appear
    var _this = _possibleConstructorReturn(this, _React$Component.call(this, props, context));

    _this.handleExited = function (key, node, originalHandler) {
      var currentChildMapping = (0, _ChildMapping.getChildMapping)(_this.props.children);

      if (key in currentChildMapping) return;

      if (originalHandler) originalHandler(node);

      _this.setState(function (state) {
        var children = _extends({}, state.children);

        delete children[key];
        return { children: children };
      });
    };

    _this.state = {
      children: (0, _ChildMapping.getChildMapping)(props.children, function (child) {
        var onExited = function onExited(node) {
          _this.handleExited(child.key, node, child.props.onExited);
        };

        return (0, _react.cloneElement)(child, {
          onExited: onExited,
          in: true,
          appear: _this.getProp(child, 'appear'),
          enter: _this.getProp(child, 'enter'),
          exit: _this.getProp(child, 'exit')
        });
      })
    };
    return _this;
  }

  TransitionGroup.prototype.getChildContext = function getChildContext() {
    return {
      transitionGroup: { isMounting: !this.appeared }
    };
  };
  // use child config unless explictly set by the Group


  TransitionGroup.prototype.getProp = function getProp(child, prop) {
    var props = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : this.props;

    return props[prop] != null ? props[prop] : child.props[prop];
  };

  TransitionGroup.prototype.componentDidMount = function componentDidMount() {
    this.appeared = true;
  };

  TransitionGroup.prototype.componentWillReceiveProps = function componentWillReceiveProps(nextProps) {
    var _this2 = this;

    var prevChildMapping = this.state.children;
    var nextChildMapping = (0, _ChildMapping.getChildMapping)(nextProps.children);

    var children = (0, _ChildMapping.mergeChildMappings)(prevChildMapping, nextChildMapping);

    Object.keys(children).forEach(function (key) {
      var child = children[key];

      if (!(0, _react.isValidElement)(child)) return;

      var onExited = function onExited(node) {
        _this2.handleExited(child.key, node, child.props.onExited);
      };

      var hasPrev = key in prevChildMapping;
      var hasNext = key in nextChildMapping;

      var prevChild = prevChildMapping[key];
      var isLeaving = (0, _react.isValidElement)(prevChild) && !prevChild.props.in;

      // item is new (entering)
      if (hasNext && (!hasPrev || isLeaving)) {
        // console.log('entering', key)
        children[key] = (0, _react.cloneElement)(child, {
          onExited: onExited,
          in: true,
          exit: _this2.getProp(child, 'exit', nextProps),
          enter: _this2.getProp(child, 'enter', nextProps)
        });
      }
      // item is old (exiting)
      else if (!hasNext && hasPrev && !isLeaving) {
          // console.log('leaving', key)
          children[key] = (0, _react.cloneElement)(child, { in: false });
        }
        // item hasn't changed transition states
        // copy over the last transition props;
        else if (hasNext && hasPrev && (0, _react.isValidElement)(prevChild)) {
            // console.log('unchanged', key)
            children[key] = (0, _react.cloneElement)(child, {
              onExited: onExited,
              in: prevChild.props.in,
              exit: _this2.getProp(child, 'exit', nextProps),
              enter: _this2.getProp(child, 'enter', nextProps)
            });
          }
    });

    this.setState({ children: children });
  };

  TransitionGroup.prototype.render = function render() {
    var _props = this.props,
        Component = _props.component,
        childFactory = _props.childFactory,
        props = _objectWithoutProperties(_props, ['component', 'childFactory']);

    var children = this.state.children;


    delete props.appear;
    delete props.enter;
    delete props.exit;

    return _react2.default.createElement(
      Component,
      props,
      values(children).map(childFactory)
    );
  };

  return TransitionGroup;
}(_react2.default.Component);

TransitionGroup.childContextTypes = {
  transitionGroup: _propTypes2.default.object.isRequired
};


TransitionGroup.propTypes = process.env.NODE_ENV !== "production" ? propTypes : {};
TransitionGroup.defaultProps = defaultProps;

exports.default = TransitionGroup;
module.exports = exports['default'];