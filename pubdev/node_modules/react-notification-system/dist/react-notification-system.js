(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory(require("react"), require("react-dom"));
	else if(typeof define === 'function' && define.amd)
		define(["react", "react-dom"], factory);
	else if(typeof exports === 'object')
		exports["ReactNotificationSystem"] = factory(require("react"), require("react-dom"));
	else
		root["ReactNotificationSystem"] = factory(root["React"], root["ReactDOM"]);
})(this, function(__WEBPACK_EXTERNAL_MODULE_2__, __WEBPACK_EXTERNAL_MODULE_18__) {
return /******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};

/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {

/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId])
/******/ 			return installedModules[moduleId].exports;

/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			exports: {},
/******/ 			id: moduleId,
/******/ 			loaded: false
/******/ 		};

/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);

/******/ 		// Flag the module as loaded
/******/ 		module.loaded = true;

/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}


/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;

/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;

/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";

/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ (function(module, exports, __webpack_require__) {

	module.exports = __webpack_require__(1);


/***/ }),
/* 1 */
/***/ (function(module, exports, __webpack_require__) {

	var React = __webpack_require__(2);
	var createReactClass = __webpack_require__(3);
	var PropTypes = __webpack_require__(11);
	var merge = __webpack_require__(6);
	var NotificationContainer = __webpack_require__(16);
	var Constants = __webpack_require__(19);
	var Styles = __webpack_require__(21);

	var NotificationSystem = createReactClass({
	  displayName: 'NotificationSystem',


	  uid: 3400,

	  _isMounted: false,

	  _getStyles: {
	    overrideStyle: {},

	    overrideWidth: null,

	    setOverrideStyle: function () {
	      function setOverrideStyle(style) {
	        this.overrideStyle = style;
	      }

	      return setOverrideStyle;
	    }(),

	    wrapper: function () {
	      function wrapper() {
	        if (!this.overrideStyle) return {};
	        return merge({}, Styles.Wrapper, this.overrideStyle.Wrapper);
	      }

	      return wrapper;
	    }(),

	    container: function () {
	      function container(position) {
	        var override = this.overrideStyle.Containers || {};
	        if (!this.overrideStyle) return {};

	        this.overrideWidth = Styles.Containers.DefaultStyle.width;

	        if (override.DefaultStyle && override.DefaultStyle.width) {
	          this.overrideWidth = override.DefaultStyle.width;
	        }

	        if (override[position] && override[position].width) {
	          this.overrideWidth = override[position].width;
	        }

	        return merge({}, Styles.Containers.DefaultStyle, Styles.Containers[position], override.DefaultStyle, override[position]);
	      }

	      return container;
	    }(),

	    elements: {
	      notification: 'NotificationItem',
	      title: 'Title',
	      messageWrapper: 'MessageWrapper',
	      dismiss: 'Dismiss',
	      action: 'Action',
	      actionWrapper: 'ActionWrapper'
	    },

	    byElement: function () {
	      function byElement(element) {
	        var self = this;
	        return function (level) {
	          var _element = self.elements[element];
	          var override = self.overrideStyle[_element] || {};
	          if (!self.overrideStyle) return {};
	          return merge({}, Styles[_element].DefaultStyle, Styles[_element][level], override.DefaultStyle, override[level]);
	        };
	      }

	      return byElement;
	    }()
	  },

	  _didNotificationRemoved: function () {
	    function _didNotificationRemoved(uid) {
	      var notification;
	      var notifications = this.state.notifications.filter(function (toCheck) {
	        if (toCheck.uid === uid) {
	          notification = toCheck;
	          return false;
	        }
	        return true;
	      });

	      if (this._isMounted) {
	        this.setState({ notifications: notifications });
	      }

	      if (notification && notification.onRemove) {
	        notification.onRemove(notification);
	      }
	    }

	    return _didNotificationRemoved;
	  }(),

	  getInitialState: function () {
	    function getInitialState() {
	      return {
	        notifications: []
	      };
	    }

	    return getInitialState;
	  }(),

	  propTypes: {
	    style: PropTypes.oneOfType([PropTypes.bool, PropTypes.object]),
	    noAnimation: PropTypes.bool,
	    allowHTML: PropTypes.bool
	  },

	  getDefaultProps: function () {
	    function getDefaultProps() {
	      return {
	        style: {},
	        noAnimation: false,
	        allowHTML: false
	      };
	    }

	    return getDefaultProps;
	  }(),

	  addNotification: function () {
	    function addNotification(notification) {
	      var _notification = merge({}, Constants.notification, notification);
	      var notifications = this.state.notifications;
	      var i;

	      if (!_notification.level) {
	        throw new Error('notification level is required.');
	      }

	      if (Object.keys(Constants.levels).indexOf(_notification.level) === -1) {
	        throw new Error('\'' + _notification.level + '\' is not a valid level.');
	      }

	      // eslint-disable-next-line
	      if (isNaN(_notification.autoDismiss)) {
	        throw new Error('\'autoDismiss\' must be a number.');
	      }

	      if (Object.keys(Constants.positions).indexOf(_notification.position) === -1) {
	        throw new Error('\'' + _notification.position + '\' is not a valid position.');
	      }

	      // Some preparations
	      _notification.position = _notification.position.toLowerCase();
	      _notification.level = _notification.level.toLowerCase();
	      _notification.autoDismiss = parseInt(_notification.autoDismiss, 10);

	      _notification.uid = _notification.uid || this.uid;
	      _notification.ref = 'notification-' + _notification.uid;
	      this.uid += 1;

	      // do not add if the notification already exists based on supplied uid
	      for (i = 0; i < notifications.length; i += 1) {
	        if (notifications[i].uid === _notification.uid) {
	          return false;
	        }
	      }

	      notifications.push(_notification);

	      if (typeof _notification.onAdd === 'function') {
	        notification.onAdd(_notification);
	      }

	      this.setState({
	        notifications: notifications
	      });

	      return _notification;
	    }

	    return addNotification;
	  }(),

	  getNotificationRef: function () {
	    function getNotificationRef(notification) {
	      var self = this;
	      var foundNotification = null;

	      Object.keys(this.refs).forEach(function (container) {
	        if (container.indexOf('container') > -1) {
	          Object.keys(self.refs[container].refs).forEach(function (_notification) {
	            var uid = notification.uid ? notification.uid : notification;
	            if (_notification === 'notification-' + uid) {
	              // NOTE: Stop iterating further and return the found notification.
	              // Since UIDs are uniques and there won't be another notification found.
	              foundNotification = self.refs[container].refs[_notification];
	            }
	          });
	        }
	      });

	      return foundNotification;
	    }

	    return getNotificationRef;
	  }(),

	  removeNotification: function () {
	    function removeNotification(notification) {
	      var foundNotification = this.getNotificationRef(notification);
	      return foundNotification && foundNotification._hideNotification();
	    }

	    return removeNotification;
	  }(),

	  editNotification: function () {
	    function editNotification(notification, newNotification) {
	      var foundNotification = null;
	      // NOTE: Find state notification to update by using
	      // `setState` and forcing React to re-render the component.
	      var uid = notification.uid ? notification.uid : notification;

	      var newNotifications = this.state.notifications.filter(function (stateNotification) {
	        if (uid === stateNotification.uid) {
	          foundNotification = stateNotification;
	          return false;
	        }

	        return true;
	      });

	      if (!foundNotification) {
	        return;
	      }

	      newNotifications.push(merge({}, foundNotification, newNotification));

	      this.setState({
	        notifications: newNotifications
	      });
	    }

	    return editNotification;
	  }(),

	  clearNotifications: function () {
	    function clearNotifications() {
	      var self = this;
	      Object.keys(this.refs).forEach(function (container) {
	        if (container.indexOf('container') > -1) {
	          Object.keys(self.refs[container].refs).forEach(function (_notification) {
	            self.refs[container].refs[_notification]._hideNotification();
	          });
	        }
	      });
	    }

	    return clearNotifications;
	  }(),

	  componentDidMount: function () {
	    function componentDidMount() {
	      this._getStyles.setOverrideStyle(this.props.style);
	      this._isMounted = true;
	    }

	    return componentDidMount;
	  }(),

	  componentWillUnmount: function () {
	    function componentWillUnmount() {
	      this._isMounted = false;
	    }

	    return componentWillUnmount;
	  }(),

	  render: function () {
	    function render() {
	      var self = this;
	      var containers = null;
	      var notifications = this.state.notifications;

	      if (notifications.length) {
	        containers = Object.keys(Constants.positions).map(function (position) {
	          var _notifications = notifications.filter(function (notification) {
	            return position === notification.position;
	          });

	          if (!_notifications.length) {
	            return null;
	          }

	          return React.createElement(NotificationContainer, {
	            ref: 'container-' + position,
	            key: position,
	            position: position,
	            notifications: _notifications,
	            getStyles: self._getStyles,
	            onRemove: self._didNotificationRemoved,
	            noAnimation: self.props.noAnimation,
	            allowHTML: self.props.allowHTML
	          });
	        });
	      }

	      return React.createElement(
	        'div',
	        { className: 'notifications-wrapper', style: this._getStyles.wrapper() },
	        containers
	      );
	    }

	    return render;
	  }()
	});

	module.exports = NotificationSystem;

/***/ }),
/* 2 */
/***/ (function(module, exports) {

	module.exports = __WEBPACK_EXTERNAL_MODULE_2__;

/***/ }),
/* 3 */
/***/ (function(module, exports, __webpack_require__) {

	/**
	 * Copyright (c) 2013-present, Facebook, Inc.
	 *
	 * This source code is licensed under the MIT license found in the
	 * LICENSE file in the root directory of this source tree.
	 *
	 */

	'use strict';

	var React = __webpack_require__(2);
	var factory = __webpack_require__(4);

	if (typeof React === 'undefined') {
	  throw Error(
	    'create-react-class could not find the React object. If you are using script tags, ' +
	      'make sure that React is being loaded before create-react-class.'
	  );
	}

	// Hack to grab NoopUpdateQueue from isomorphic React
	var ReactNoopUpdateQueue = new React.Component().updater;

	module.exports = factory(
	  React.Component,
	  React.isValidElement,
	  ReactNoopUpdateQueue
	);


/***/ }),
/* 4 */
/***/ (function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(process) {/**
	 * Copyright (c) 2013-present, Facebook, Inc.
	 *
	 * This source code is licensed under the MIT license found in the
	 * LICENSE file in the root directory of this source tree.
	 *
	 */

	'use strict';

	var _assign = __webpack_require__(6);

	var emptyObject = __webpack_require__(7);
	var _invariant = __webpack_require__(8);

	if (process.env.NODE_ENV !== 'production') {
	  var warning = __webpack_require__(9);
	}

	var MIXINS_KEY = 'mixins';

	// Helper function to allow the creation of anonymous functions which do not
	// have .name set to the name of the variable being assigned to.
	function identity(fn) {
	  return fn;
	}

	var ReactPropTypeLocationNames;
	if (process.env.NODE_ENV !== 'production') {
	  ReactPropTypeLocationNames = {
	    prop: 'prop',
	    context: 'context',
	    childContext: 'child context'
	  };
	} else {
	  ReactPropTypeLocationNames = {};
	}

	function factory(ReactComponent, isValidElement, ReactNoopUpdateQueue) {
	  /**
	   * Policies that describe methods in `ReactClassInterface`.
	   */

	  var injectedMixins = [];

	  /**
	   * Composite components are higher-level components that compose other composite
	   * or host components.
	   *
	   * To create a new type of `ReactClass`, pass a specification of
	   * your new class to `React.createClass`. The only requirement of your class
	   * specification is that you implement a `render` method.
	   *
	   *   var MyComponent = React.createClass({
	   *     render: function() {
	   *       return <div>Hello World</div>;
	   *     }
	   *   });
	   *
	   * The class specification supports a specific protocol of methods that have
	   * special meaning (e.g. `render`). See `ReactClassInterface` for
	   * more the comprehensive protocol. Any other properties and methods in the
	   * class specification will be available on the prototype.
	   *
	   * @interface ReactClassInterface
	   * @internal
	   */
	  var ReactClassInterface = {
	    /**
	     * An array of Mixin objects to include when defining your component.
	     *
	     * @type {array}
	     * @optional
	     */
	    mixins: 'DEFINE_MANY',

	    /**
	     * An object containing properties and methods that should be defined on
	     * the component's constructor instead of its prototype (static methods).
	     *
	     * @type {object}
	     * @optional
	     */
	    statics: 'DEFINE_MANY',

	    /**
	     * Definition of prop types for this component.
	     *
	     * @type {object}
	     * @optional
	     */
	    propTypes: 'DEFINE_MANY',

	    /**
	     * Definition of context types for this component.
	     *
	     * @type {object}
	     * @optional
	     */
	    contextTypes: 'DEFINE_MANY',

	    /**
	     * Definition of context types this component sets for its children.
	     *
	     * @type {object}
	     * @optional
	     */
	    childContextTypes: 'DEFINE_MANY',

	    // ==== Definition methods ====

	    /**
	     * Invoked when the component is mounted. Values in the mapping will be set on
	     * `this.props` if that prop is not specified (i.e. using an `in` check).
	     *
	     * This method is invoked before `getInitialState` and therefore cannot rely
	     * on `this.state` or use `this.setState`.
	     *
	     * @return {object}
	     * @optional
	     */
	    getDefaultProps: 'DEFINE_MANY_MERGED',

	    /**
	     * Invoked once before the component is mounted. The return value will be used
	     * as the initial value of `this.state`.
	     *
	     *   getInitialState: function() {
	     *     return {
	     *       isOn: false,
	     *       fooBaz: new BazFoo()
	     *     }
	     *   }
	     *
	     * @return {object}
	     * @optional
	     */
	    getInitialState: 'DEFINE_MANY_MERGED',

	    /**
	     * @return {object}
	     * @optional
	     */
	    getChildContext: 'DEFINE_MANY_MERGED',

	    /**
	     * Uses props from `this.props` and state from `this.state` to render the
	     * structure of the component.
	     *
	     * No guarantees are made about when or how often this method is invoked, so
	     * it must not have side effects.
	     *
	     *   render: function() {
	     *     var name = this.props.name;
	     *     return <div>Hello, {name}!</div>;
	     *   }
	     *
	     * @return {ReactComponent}
	     * @required
	     */
	    render: 'DEFINE_ONCE',

	    // ==== Delegate methods ====

	    /**
	     * Invoked when the component is initially created and about to be mounted.
	     * This may have side effects, but any external subscriptions or data created
	     * by this method must be cleaned up in `componentWillUnmount`.
	     *
	     * @optional
	     */
	    componentWillMount: 'DEFINE_MANY',

	    /**
	     * Invoked when the component has been mounted and has a DOM representation.
	     * However, there is no guarantee that the DOM node is in the document.
	     *
	     * Use this as an opportunity to operate on the DOM when the component has
	     * been mounted (initialized and rendered) for the first time.
	     *
	     * @param {DOMElement} rootNode DOM element representing the component.
	     * @optional
	     */
	    componentDidMount: 'DEFINE_MANY',

	    /**
	     * Invoked before the component receives new props.
	     *
	     * Use this as an opportunity to react to a prop transition by updating the
	     * state using `this.setState`. Current props are accessed via `this.props`.
	     *
	     *   componentWillReceiveProps: function(nextProps, nextContext) {
	     *     this.setState({
	     *       likesIncreasing: nextProps.likeCount > this.props.likeCount
	     *     });
	     *   }
	     *
	     * NOTE: There is no equivalent `componentWillReceiveState`. An incoming prop
	     * transition may cause a state change, but the opposite is not true. If you
	     * need it, you are probably looking for `componentWillUpdate`.
	     *
	     * @param {object} nextProps
	     * @optional
	     */
	    componentWillReceiveProps: 'DEFINE_MANY',

	    /**
	     * Invoked while deciding if the component should be updated as a result of
	     * receiving new props, state and/or context.
	     *
	     * Use this as an opportunity to `return false` when you're certain that the
	     * transition to the new props/state/context will not require a component
	     * update.
	     *
	     *   shouldComponentUpdate: function(nextProps, nextState, nextContext) {
	     *     return !equal(nextProps, this.props) ||
	     *       !equal(nextState, this.state) ||
	     *       !equal(nextContext, this.context);
	     *   }
	     *
	     * @param {object} nextProps
	     * @param {?object} nextState
	     * @param {?object} nextContext
	     * @return {boolean} True if the component should update.
	     * @optional
	     */
	    shouldComponentUpdate: 'DEFINE_ONCE',

	    /**
	     * Invoked when the component is about to update due to a transition from
	     * `this.props`, `this.state` and `this.context` to `nextProps`, `nextState`
	     * and `nextContext`.
	     *
	     * Use this as an opportunity to perform preparation before an update occurs.
	     *
	     * NOTE: You **cannot** use `this.setState()` in this method.
	     *
	     * @param {object} nextProps
	     * @param {?object} nextState
	     * @param {?object} nextContext
	     * @param {ReactReconcileTransaction} transaction
	     * @optional
	     */
	    componentWillUpdate: 'DEFINE_MANY',

	    /**
	     * Invoked when the component's DOM representation has been updated.
	     *
	     * Use this as an opportunity to operate on the DOM when the component has
	     * been updated.
	     *
	     * @param {object} prevProps
	     * @param {?object} prevState
	     * @param {?object} prevContext
	     * @param {DOMElement} rootNode DOM element representing the component.
	     * @optional
	     */
	    componentDidUpdate: 'DEFINE_MANY',

	    /**
	     * Invoked when the component is about to be removed from its parent and have
	     * its DOM representation destroyed.
	     *
	     * Use this as an opportunity to deallocate any external resources.
	     *
	     * NOTE: There is no `componentDidUnmount` since your component will have been
	     * destroyed by that point.
	     *
	     * @optional
	     */
	    componentWillUnmount: 'DEFINE_MANY',

	    // ==== Advanced methods ====

	    /**
	     * Updates the component's currently mounted DOM representation.
	     *
	     * By default, this implements React's rendering and reconciliation algorithm.
	     * Sophisticated clients may wish to override this.
	     *
	     * @param {ReactReconcileTransaction} transaction
	     * @internal
	     * @overridable
	     */
	    updateComponent: 'OVERRIDE_BASE'
	  };

	  /**
	   * Mapping from class specification keys to special processing functions.
	   *
	   * Although these are declared like instance properties in the specification
	   * when defining classes using `React.createClass`, they are actually static
	   * and are accessible on the constructor instead of the prototype. Despite
	   * being static, they must be defined outside of the "statics" key under
	   * which all other static methods are defined.
	   */
	  var RESERVED_SPEC_KEYS = {
	    displayName: function(Constructor, displayName) {
	      Constructor.displayName = displayName;
	    },
	    mixins: function(Constructor, mixins) {
	      if (mixins) {
	        for (var i = 0; i < mixins.length; i++) {
	          mixSpecIntoComponent(Constructor, mixins[i]);
	        }
	      }
	    },
	    childContextTypes: function(Constructor, childContextTypes) {
	      if (process.env.NODE_ENV !== 'production') {
	        validateTypeDef(Constructor, childContextTypes, 'childContext');
	      }
	      Constructor.childContextTypes = _assign(
	        {},
	        Constructor.childContextTypes,
	        childContextTypes
	      );
	    },
	    contextTypes: function(Constructor, contextTypes) {
	      if (process.env.NODE_ENV !== 'production') {
	        validateTypeDef(Constructor, contextTypes, 'context');
	      }
	      Constructor.contextTypes = _assign(
	        {},
	        Constructor.contextTypes,
	        contextTypes
	      );
	    },
	    /**
	     * Special case getDefaultProps which should move into statics but requires
	     * automatic merging.
	     */
	    getDefaultProps: function(Constructor, getDefaultProps) {
	      if (Constructor.getDefaultProps) {
	        Constructor.getDefaultProps = createMergedResultFunction(
	          Constructor.getDefaultProps,
	          getDefaultProps
	        );
	      } else {
	        Constructor.getDefaultProps = getDefaultProps;
	      }
	    },
	    propTypes: function(Constructor, propTypes) {
	      if (process.env.NODE_ENV !== 'production') {
	        validateTypeDef(Constructor, propTypes, 'prop');
	      }
	      Constructor.propTypes = _assign({}, Constructor.propTypes, propTypes);
	    },
	    statics: function(Constructor, statics) {
	      mixStaticSpecIntoComponent(Constructor, statics);
	    },
	    autobind: function() {}
	  };

	  function validateTypeDef(Constructor, typeDef, location) {
	    for (var propName in typeDef) {
	      if (typeDef.hasOwnProperty(propName)) {
	        // use a warning instead of an _invariant so components
	        // don't show up in prod but only in __DEV__
	        if (process.env.NODE_ENV !== 'production') {
	          warning(
	            typeof typeDef[propName] === 'function',
	            '%s: %s type `%s` is invalid; it must be a function, usually from ' +
	              'React.PropTypes.',
	            Constructor.displayName || 'ReactClass',
	            ReactPropTypeLocationNames[location],
	            propName
	          );
	        }
	      }
	    }
	  }

	  function validateMethodOverride(isAlreadyDefined, name) {
	    var specPolicy = ReactClassInterface.hasOwnProperty(name)
	      ? ReactClassInterface[name]
	      : null;

	    // Disallow overriding of base class methods unless explicitly allowed.
	    if (ReactClassMixin.hasOwnProperty(name)) {
	      _invariant(
	        specPolicy === 'OVERRIDE_BASE',
	        'ReactClassInterface: You are attempting to override ' +
	          '`%s` from your class specification. Ensure that your method names ' +
	          'do not overlap with React methods.',
	        name
	      );
	    }

	    // Disallow defining methods more than once unless explicitly allowed.
	    if (isAlreadyDefined) {
	      _invariant(
	        specPolicy === 'DEFINE_MANY' || specPolicy === 'DEFINE_MANY_MERGED',
	        'ReactClassInterface: You are attempting to define ' +
	          '`%s` on your component more than once. This conflict may be due ' +
	          'to a mixin.',
	        name
	      );
	    }
	  }

	  /**
	   * Mixin helper which handles policy validation and reserved
	   * specification keys when building React classes.
	   */
	  function mixSpecIntoComponent(Constructor, spec) {
	    if (!spec) {
	      if (process.env.NODE_ENV !== 'production') {
	        var typeofSpec = typeof spec;
	        var isMixinValid = typeofSpec === 'object' && spec !== null;

	        if (process.env.NODE_ENV !== 'production') {
	          warning(
	            isMixinValid,
	            "%s: You're attempting to include a mixin that is either null " +
	              'or not an object. Check the mixins included by the component, ' +
	              'as well as any mixins they include themselves. ' +
	              'Expected object but got %s.',
	            Constructor.displayName || 'ReactClass',
	            spec === null ? null : typeofSpec
	          );
	        }
	      }

	      return;
	    }

	    _invariant(
	      typeof spec !== 'function',
	      "ReactClass: You're attempting to " +
	        'use a component class or function as a mixin. Instead, just use a ' +
	        'regular object.'
	    );
	    _invariant(
	      !isValidElement(spec),
	      "ReactClass: You're attempting to " +
	        'use a component as a mixin. Instead, just use a regular object.'
	    );

	    var proto = Constructor.prototype;
	    var autoBindPairs = proto.__reactAutoBindPairs;

	    // By handling mixins before any other properties, we ensure the same
	    // chaining order is applied to methods with DEFINE_MANY policy, whether
	    // mixins are listed before or after these methods in the spec.
	    if (spec.hasOwnProperty(MIXINS_KEY)) {
	      RESERVED_SPEC_KEYS.mixins(Constructor, spec.mixins);
	    }

	    for (var name in spec) {
	      if (!spec.hasOwnProperty(name)) {
	        continue;
	      }

	      if (name === MIXINS_KEY) {
	        // We have already handled mixins in a special case above.
	        continue;
	      }

	      var property = spec[name];
	      var isAlreadyDefined = proto.hasOwnProperty(name);
	      validateMethodOverride(isAlreadyDefined, name);

	      if (RESERVED_SPEC_KEYS.hasOwnProperty(name)) {
	        RESERVED_SPEC_KEYS[name](Constructor, property);
	      } else {
	        // Setup methods on prototype:
	        // The following member methods should not be automatically bound:
	        // 1. Expected ReactClass methods (in the "interface").
	        // 2. Overridden methods (that were mixed in).
	        var isReactClassMethod = ReactClassInterface.hasOwnProperty(name);
	        var isFunction = typeof property === 'function';
	        var shouldAutoBind =
	          isFunction &&
	          !isReactClassMethod &&
	          !isAlreadyDefined &&
	          spec.autobind !== false;

	        if (shouldAutoBind) {
	          autoBindPairs.push(name, property);
	          proto[name] = property;
	        } else {
	          if (isAlreadyDefined) {
	            var specPolicy = ReactClassInterface[name];

	            // These cases should already be caught by validateMethodOverride.
	            _invariant(
	              isReactClassMethod &&
	                (specPolicy === 'DEFINE_MANY_MERGED' ||
	                  specPolicy === 'DEFINE_MANY'),
	              'ReactClass: Unexpected spec policy %s for key %s ' +
	                'when mixing in component specs.',
	              specPolicy,
	              name
	            );

	            // For methods which are defined more than once, call the existing
	            // methods before calling the new property, merging if appropriate.
	            if (specPolicy === 'DEFINE_MANY_MERGED') {
	              proto[name] = createMergedResultFunction(proto[name], property);
	            } else if (specPolicy === 'DEFINE_MANY') {
	              proto[name] = createChainedFunction(proto[name], property);
	            }
	          } else {
	            proto[name] = property;
	            if (process.env.NODE_ENV !== 'production') {
	              // Add verbose displayName to the function, which helps when looking
	              // at profiling tools.
	              if (typeof property === 'function' && spec.displayName) {
	                proto[name].displayName = spec.displayName + '_' + name;
	              }
	            }
	          }
	        }
	      }
	    }
	  }

	  function mixStaticSpecIntoComponent(Constructor, statics) {
	    if (!statics) {
	      return;
	    }
	    for (var name in statics) {
	      var property = statics[name];
	      if (!statics.hasOwnProperty(name)) {
	        continue;
	      }

	      var isReserved = name in RESERVED_SPEC_KEYS;
	      _invariant(
	        !isReserved,
	        'ReactClass: You are attempting to define a reserved ' +
	          'property, `%s`, that shouldn\'t be on the "statics" key. Define it ' +
	          'as an instance property instead; it will still be accessible on the ' +
	          'constructor.',
	        name
	      );

	      var isInherited = name in Constructor;
	      _invariant(
	        !isInherited,
	        'ReactClass: You are attempting to define ' +
	          '`%s` on your component more than once. This conflict may be ' +
	          'due to a mixin.',
	        name
	      );
	      Constructor[name] = property;
	    }
	  }

	  /**
	   * Merge two objects, but throw if both contain the same key.
	   *
	   * @param {object} one The first object, which is mutated.
	   * @param {object} two The second object
	   * @return {object} one after it has been mutated to contain everything in two.
	   */
	  function mergeIntoWithNoDuplicateKeys(one, two) {
	    _invariant(
	      one && two && typeof one === 'object' && typeof two === 'object',
	      'mergeIntoWithNoDuplicateKeys(): Cannot merge non-objects.'
	    );

	    for (var key in two) {
	      if (two.hasOwnProperty(key)) {
	        _invariant(
	          one[key] === undefined,
	          'mergeIntoWithNoDuplicateKeys(): ' +
	            'Tried to merge two objects with the same key: `%s`. This conflict ' +
	            'may be due to a mixin; in particular, this may be caused by two ' +
	            'getInitialState() or getDefaultProps() methods returning objects ' +
	            'with clashing keys.',
	          key
	        );
	        one[key] = two[key];
	      }
	    }
	    return one;
	  }

	  /**
	   * Creates a function that invokes two functions and merges their return values.
	   *
	   * @param {function} one Function to invoke first.
	   * @param {function} two Function to invoke second.
	   * @return {function} Function that invokes the two argument functions.
	   * @private
	   */
	  function createMergedResultFunction(one, two) {
	    return function mergedResult() {
	      var a = one.apply(this, arguments);
	      var b = two.apply(this, arguments);
	      if (a == null) {
	        return b;
	      } else if (b == null) {
	        return a;
	      }
	      var c = {};
	      mergeIntoWithNoDuplicateKeys(c, a);
	      mergeIntoWithNoDuplicateKeys(c, b);
	      return c;
	    };
	  }

	  /**
	   * Creates a function that invokes two functions and ignores their return vales.
	   *
	   * @param {function} one Function to invoke first.
	   * @param {function} two Function to invoke second.
	   * @return {function} Function that invokes the two argument functions.
	   * @private
	   */
	  function createChainedFunction(one, two) {
	    return function chainedFunction() {
	      one.apply(this, arguments);
	      two.apply(this, arguments);
	    };
	  }

	  /**
	   * Binds a method to the component.
	   *
	   * @param {object} component Component whose method is going to be bound.
	   * @param {function} method Method to be bound.
	   * @return {function} The bound method.
	   */
	  function bindAutoBindMethod(component, method) {
	    var boundMethod = method.bind(component);
	    if (process.env.NODE_ENV !== 'production') {
	      boundMethod.__reactBoundContext = component;
	      boundMethod.__reactBoundMethod = method;
	      boundMethod.__reactBoundArguments = null;
	      var componentName = component.constructor.displayName;
	      var _bind = boundMethod.bind;
	      boundMethod.bind = function(newThis) {
	        for (
	          var _len = arguments.length,
	            args = Array(_len > 1 ? _len - 1 : 0),
	            _key = 1;
	          _key < _len;
	          _key++
	        ) {
	          args[_key - 1] = arguments[_key];
	        }

	        // User is trying to bind() an autobound method; we effectively will
	        // ignore the value of "this" that the user is trying to use, so
	        // let's warn.
	        if (newThis !== component && newThis !== null) {
	          if (process.env.NODE_ENV !== 'production') {
	            warning(
	              false,
	              'bind(): React component methods may only be bound to the ' +
	                'component instance. See %s',
	              componentName
	            );
	          }
	        } else if (!args.length) {
	          if (process.env.NODE_ENV !== 'production') {
	            warning(
	              false,
	              'bind(): You are binding a component method to the component. ' +
	                'React does this for you automatically in a high-performance ' +
	                'way, so you can safely remove this call. See %s',
	              componentName
	            );
	          }
	          return boundMethod;
	        }
	        var reboundMethod = _bind.apply(boundMethod, arguments);
	        reboundMethod.__reactBoundContext = component;
	        reboundMethod.__reactBoundMethod = method;
	        reboundMethod.__reactBoundArguments = args;
	        return reboundMethod;
	      };
	    }
	    return boundMethod;
	  }

	  /**
	   * Binds all auto-bound methods in a component.
	   *
	   * @param {object} component Component whose method is going to be bound.
	   */
	  function bindAutoBindMethods(component) {
	    var pairs = component.__reactAutoBindPairs;
	    for (var i = 0; i < pairs.length; i += 2) {
	      var autoBindKey = pairs[i];
	      var method = pairs[i + 1];
	      component[autoBindKey] = bindAutoBindMethod(component, method);
	    }
	  }

	  var IsMountedPreMixin = {
	    componentDidMount: function() {
	      this.__isMounted = true;
	    }
	  };

	  var IsMountedPostMixin = {
	    componentWillUnmount: function() {
	      this.__isMounted = false;
	    }
	  };

	  /**
	   * Add more to the ReactClass base class. These are all legacy features and
	   * therefore not already part of the modern ReactComponent.
	   */
	  var ReactClassMixin = {
	    /**
	     * TODO: This will be deprecated because state should always keep a consistent
	     * type signature and the only use case for this, is to avoid that.
	     */
	    replaceState: function(newState, callback) {
	      this.updater.enqueueReplaceState(this, newState, callback);
	    },

	    /**
	     * Checks whether or not this composite component is mounted.
	     * @return {boolean} True if mounted, false otherwise.
	     * @protected
	     * @final
	     */
	    isMounted: function() {
	      if (process.env.NODE_ENV !== 'production') {
	        warning(
	          this.__didWarnIsMounted,
	          '%s: isMounted is deprecated. Instead, make sure to clean up ' +
	            'subscriptions and pending requests in componentWillUnmount to ' +
	            'prevent memory leaks.',
	          (this.constructor && this.constructor.displayName) ||
	            this.name ||
	            'Component'
	        );
	        this.__didWarnIsMounted = true;
	      }
	      return !!this.__isMounted;
	    }
	  };

	  var ReactClassComponent = function() {};
	  _assign(
	    ReactClassComponent.prototype,
	    ReactComponent.prototype,
	    ReactClassMixin
	  );

	  /**
	   * Creates a composite component class given a class specification.
	   * See https://facebook.github.io/react/docs/top-level-api.html#react.createclass
	   *
	   * @param {object} spec Class specification (which must define `render`).
	   * @return {function} Component constructor function.
	   * @public
	   */
	  function createClass(spec) {
	    // To keep our warnings more understandable, we'll use a little hack here to
	    // ensure that Constructor.name !== 'Constructor'. This makes sure we don't
	    // unnecessarily identify a class without displayName as 'Constructor'.
	    var Constructor = identity(function(props, context, updater) {
	      // This constructor gets overridden by mocks. The argument is used
	      // by mocks to assert on what gets mounted.

	      if (process.env.NODE_ENV !== 'production') {
	        warning(
	          this instanceof Constructor,
	          'Something is calling a React component directly. Use a factory or ' +
	            'JSX instead. See: https://fb.me/react-legacyfactory'
	        );
	      }

	      // Wire up auto-binding
	      if (this.__reactAutoBindPairs.length) {
	        bindAutoBindMethods(this);
	      }

	      this.props = props;
	      this.context = context;
	      this.refs = emptyObject;
	      this.updater = updater || ReactNoopUpdateQueue;

	      this.state = null;

	      // ReactClasses doesn't have constructors. Instead, they use the
	      // getInitialState and componentWillMount methods for initialization.

	      var initialState = this.getInitialState ? this.getInitialState() : null;
	      if (process.env.NODE_ENV !== 'production') {
	        // We allow auto-mocks to proceed as if they're returning null.
	        if (
	          initialState === undefined &&
	          this.getInitialState._isMockFunction
	        ) {
	          // This is probably bad practice. Consider warning here and
	          // deprecating this convenience.
	          initialState = null;
	        }
	      }
	      _invariant(
	        typeof initialState === 'object' && !Array.isArray(initialState),
	        '%s.getInitialState(): must return an object or null',
	        Constructor.displayName || 'ReactCompositeComponent'
	      );

	      this.state = initialState;
	    });
	    Constructor.prototype = new ReactClassComponent();
	    Constructor.prototype.constructor = Constructor;
	    Constructor.prototype.__reactAutoBindPairs = [];

	    injectedMixins.forEach(mixSpecIntoComponent.bind(null, Constructor));

	    mixSpecIntoComponent(Constructor, IsMountedPreMixin);
	    mixSpecIntoComponent(Constructor, spec);
	    mixSpecIntoComponent(Constructor, IsMountedPostMixin);

	    // Initialize the defaultProps property after all mixins have been merged.
	    if (Constructor.getDefaultProps) {
	      Constructor.defaultProps = Constructor.getDefaultProps();
	    }

	    if (process.env.NODE_ENV !== 'production') {
	      // This is a tag to indicate that the use of these method names is ok,
	      // since it's used with createClass. If it's not, then it's likely a
	      // mistake so we'll warn you to use the static property, property
	      // initializer or constructor respectively.
	      if (Constructor.getDefaultProps) {
	        Constructor.getDefaultProps.isReactClassApproved = {};
	      }
	      if (Constructor.prototype.getInitialState) {
	        Constructor.prototype.getInitialState.isReactClassApproved = {};
	      }
	    }

	    _invariant(
	      Constructor.prototype.render,
	      'createClass(...): Class specification must implement a `render` method.'
	    );

	    if (process.env.NODE_ENV !== 'production') {
	      warning(
	        !Constructor.prototype.componentShouldUpdate,
	        '%s has a method called ' +
	          'componentShouldUpdate(). Did you mean shouldComponentUpdate()? ' +
	          'The name is phrased as a question because the function is ' +
	          'expected to return a value.',
	        spec.displayName || 'A component'
	      );
	      warning(
	        !Constructor.prototype.componentWillRecieveProps,
	        '%s has a method called ' +
	          'componentWillRecieveProps(). Did you mean componentWillReceiveProps()?',
	        spec.displayName || 'A component'
	      );
	    }

	    // Reduce time spent doing lookups by setting these on the prototype.
	    for (var methodName in ReactClassInterface) {
	      if (!Constructor.prototype[methodName]) {
	        Constructor.prototype[methodName] = null;
	      }
	    }

	    return Constructor;
	  }

	  return createClass;
	}

	module.exports = factory;

	/* WEBPACK VAR INJECTION */}.call(exports, __webpack_require__(5)))

/***/ }),
/* 5 */
/***/ (function(module, exports) {

	// shim for using process in browser
	var process = module.exports = {};

	// cached from whatever global is present so that test runners that stub it
	// don't break things.  But we need to wrap it in a try catch in case it is
	// wrapped in strict mode code which doesn't define any globals.  It's inside a
	// function because try/catches deoptimize in certain engines.

	var cachedSetTimeout;
	var cachedClearTimeout;

	function defaultSetTimout() {
	    throw new Error('setTimeout has not been defined');
	}
	function defaultClearTimeout () {
	    throw new Error('clearTimeout has not been defined');
	}
	(function () {
	    try {
	        if (typeof setTimeout === 'function') {
	            cachedSetTimeout = setTimeout;
	        } else {
	            cachedSetTimeout = defaultSetTimout;
	        }
	    } catch (e) {
	        cachedSetTimeout = defaultSetTimout;
	    }
	    try {
	        if (typeof clearTimeout === 'function') {
	            cachedClearTimeout = clearTimeout;
	        } else {
	            cachedClearTimeout = defaultClearTimeout;
	        }
	    } catch (e) {
	        cachedClearTimeout = defaultClearTimeout;
	    }
	} ())
	function runTimeout(fun) {
	    if (cachedSetTimeout === setTimeout) {
	        //normal enviroments in sane situations
	        return setTimeout(fun, 0);
	    }
	    // if setTimeout wasn't available but was latter defined
	    if ((cachedSetTimeout === defaultSetTimout || !cachedSetTimeout) && setTimeout) {
	        cachedSetTimeout = setTimeout;
	        return setTimeout(fun, 0);
	    }
	    try {
	        // when when somebody has screwed with setTimeout but no I.E. maddness
	        return cachedSetTimeout(fun, 0);
	    } catch(e){
	        try {
	            // When we are in I.E. but the script has been evaled so I.E. doesn't trust the global object when called normally
	            return cachedSetTimeout.call(null, fun, 0);
	        } catch(e){
	            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error
	            return cachedSetTimeout.call(this, fun, 0);
	        }
	    }


	}
	function runClearTimeout(marker) {
	    if (cachedClearTimeout === clearTimeout) {
	        //normal enviroments in sane situations
	        return clearTimeout(marker);
	    }
	    // if clearTimeout wasn't available but was latter defined
	    if ((cachedClearTimeout === defaultClearTimeout || !cachedClearTimeout) && clearTimeout) {
	        cachedClearTimeout = clearTimeout;
	        return clearTimeout(marker);
	    }
	    try {
	        // when when somebody has screwed with setTimeout but no I.E. maddness
	        return cachedClearTimeout(marker);
	    } catch (e){
	        try {
	            // When we are in I.E. but the script has been evaled so I.E. doesn't  trust the global object when called normally
	            return cachedClearTimeout.call(null, marker);
	        } catch (e){
	            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error.
	            // Some versions of I.E. have different rules for clearTimeout vs setTimeout
	            return cachedClearTimeout.call(this, marker);
	        }
	    }



	}
	var queue = [];
	var draining = false;
	var currentQueue;
	var queueIndex = -1;

	function cleanUpNextTick() {
	    if (!draining || !currentQueue) {
	        return;
	    }
	    draining = false;
	    if (currentQueue.length) {
	        queue = currentQueue.concat(queue);
	    } else {
	        queueIndex = -1;
	    }
	    if (queue.length) {
	        drainQueue();
	    }
	}

	function drainQueue() {
	    if (draining) {
	        return;
	    }
	    var timeout = runTimeout(cleanUpNextTick);
	    draining = true;

	    var len = queue.length;
	    while(len) {
	        currentQueue = queue;
	        queue = [];
	        while (++queueIndex < len) {
	            if (currentQueue) {
	                currentQueue[queueIndex].run();
	            }
	        }
	        queueIndex = -1;
	        len = queue.length;
	    }
	    currentQueue = null;
	    draining = false;
	    runClearTimeout(timeout);
	}

	process.nextTick = function (fun) {
	    var args = new Array(arguments.length - 1);
	    if (arguments.length > 1) {
	        for (var i = 1; i < arguments.length; i++) {
	            args[i - 1] = arguments[i];
	        }
	    }
	    queue.push(new Item(fun, args));
	    if (queue.length === 1 && !draining) {
	        runTimeout(drainQueue);
	    }
	};

	// v8 likes predictible objects
	function Item(fun, array) {
	    this.fun = fun;
	    this.array = array;
	}
	Item.prototype.run = function () {
	    this.fun.apply(null, this.array);
	};
	process.title = 'browser';
	process.browser = true;
	process.env = {};
	process.argv = [];
	process.version = ''; // empty string to avoid regexp issues
	process.versions = {};

	function noop() {}

	process.on = noop;
	process.addListener = noop;
	process.once = noop;
	process.off = noop;
	process.removeListener = noop;
	process.removeAllListeners = noop;
	process.emit = noop;
	process.prependListener = noop;
	process.prependOnceListener = noop;

	process.listeners = function (name) { return [] }

	process.binding = function (name) {
	    throw new Error('process.binding is not supported');
	};

	process.cwd = function () { return '/' };
	process.chdir = function (dir) {
	    throw new Error('process.chdir is not supported');
	};
	process.umask = function() { return 0; };


/***/ }),
/* 6 */
/***/ (function(module, exports) {

	/*
	object-assign
	(c) Sindre Sorhus
	@license MIT
	*/

	'use strict';
	/* eslint-disable no-unused-vars */
	var getOwnPropertySymbols = Object.getOwnPropertySymbols;
	var hasOwnProperty = Object.prototype.hasOwnProperty;
	var propIsEnumerable = Object.prototype.propertyIsEnumerable;

	function toObject(val) {
		if (val === null || val === undefined) {
			throw new TypeError('Object.assign cannot be called with null or undefined');
		}

		return Object(val);
	}

	function shouldUseNative() {
		try {
			if (!Object.assign) {
				return false;
			}

			// Detect buggy property enumeration order in older V8 versions.

			// https://bugs.chromium.org/p/v8/issues/detail?id=4118
			var test1 = new String('abc');  // eslint-disable-line no-new-wrappers
			test1[5] = 'de';
			if (Object.getOwnPropertyNames(test1)[0] === '5') {
				return false;
			}

			// https://bugs.chromium.org/p/v8/issues/detail?id=3056
			var test2 = {};
			for (var i = 0; i < 10; i++) {
				test2['_' + String.fromCharCode(i)] = i;
			}
			var order2 = Object.getOwnPropertyNames(test2).map(function (n) {
				return test2[n];
			});
			if (order2.join('') !== '0123456789') {
				return false;
			}

			// https://bugs.chromium.org/p/v8/issues/detail?id=3056
			var test3 = {};
			'abcdefghijklmnopqrst'.split('').forEach(function (letter) {
				test3[letter] = letter;
			});
			if (Object.keys(Object.assign({}, test3)).join('') !==
					'abcdefghijklmnopqrst') {
				return false;
			}

			return true;
		} catch (err) {
			// We don't expect any of the above to throw, but better to be safe.
			return false;
		}
	}

	module.exports = shouldUseNative() ? Object.assign : function (target, source) {
		var from;
		var to = toObject(target);
		var symbols;

		for (var s = 1; s < arguments.length; s++) {
			from = Object(arguments[s]);

			for (var key in from) {
				if (hasOwnProperty.call(from, key)) {
					to[key] = from[key];
				}
			}

			if (getOwnPropertySymbols) {
				symbols = getOwnPropertySymbols(from);
				for (var i = 0; i < symbols.length; i++) {
					if (propIsEnumerable.call(from, symbols[i])) {
						to[symbols[i]] = from[symbols[i]];
					}
				}
			}
		}

		return to;
	};


/***/ }),
/* 7 */
/***/ (function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(process) {/**
	 * Copyright (c) 2013-present, Facebook, Inc.
	 *
	 * This source code is licensed under the MIT license found in the
	 * LICENSE file in the root directory of this source tree.
	 *
	 */

	'use strict';

	var emptyObject = {};

	if (process.env.NODE_ENV !== 'production') {
	  Object.freeze(emptyObject);
	}

	module.exports = emptyObject;
	/* WEBPACK VAR INJECTION */}.call(exports, __webpack_require__(5)))

/***/ }),
/* 8 */
/***/ (function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(process) {/**
	 * Copyright (c) 2013-present, Facebook, Inc.
	 *
	 * This source code is licensed under the MIT license found in the
	 * LICENSE file in the root directory of this source tree.
	 *
	 */

	'use strict';

	/**
	 * Use invariant() to assert state which your program assumes to be true.
	 *
	 * Provide sprintf-style format (only %s is supported) and arguments
	 * to provide information about what broke and what you were
	 * expecting.
	 *
	 * The invariant message will be stripped in production, but the invariant
	 * will remain to ensure logic does not differ in production.
	 */

	var validateFormat = function validateFormat(format) {};

	if (process.env.NODE_ENV !== 'production') {
	  validateFormat = function validateFormat(format) {
	    if (format === undefined) {
	      throw new Error('invariant requires an error message argument');
	    }
	  };
	}

	function invariant(condition, format, a, b, c, d, e, f) {
	  validateFormat(format);

	  if (!condition) {
	    var error;
	    if (format === undefined) {
	      error = new Error('Minified exception occurred; use the non-minified dev environment ' + 'for the full error message and additional helpful warnings.');
	    } else {
	      var args = [a, b, c, d, e, f];
	      var argIndex = 0;
	      error = new Error(format.replace(/%s/g, function () {
	        return args[argIndex++];
	      }));
	      error.name = 'Invariant Violation';
	    }

	    error.framesToPop = 1; // we don't care about invariant's own frame
	    throw error;
	  }
	}

	module.exports = invariant;
	/* WEBPACK VAR INJECTION */}.call(exports, __webpack_require__(5)))

/***/ }),
/* 9 */
/***/ (function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(process) {/**
	 * Copyright (c) 2014-present, Facebook, Inc.
	 *
	 * This source code is licensed under the MIT license found in the
	 * LICENSE file in the root directory of this source tree.
	 *
	 */

	'use strict';

	var emptyFunction = __webpack_require__(10);

	/**
	 * Similar to invariant but only logs a warning if the condition is not met.
	 * This can be used to log issues in development environments in critical
	 * paths. Removing the logging code for production environments will keep the
	 * same logic and follow the same code paths.
	 */

	var warning = emptyFunction;

	if (process.env.NODE_ENV !== 'production') {
	  var printWarning = function printWarning(format) {
	    for (var _len = arguments.length, args = Array(_len > 1 ? _len - 1 : 0), _key = 1; _key < _len; _key++) {
	      args[_key - 1] = arguments[_key];
	    }

	    var argIndex = 0;
	    var message = 'Warning: ' + format.replace(/%s/g, function () {
	      return args[argIndex++];
	    });
	    if (typeof console !== 'undefined') {
	      console.error(message);
	    }
	    try {
	      // --- Welcome to debugging React ---
	      // This error was thrown as a convenience so that you can use this stack
	      // to find the callsite that caused this warning to fire.
	      throw new Error(message);
	    } catch (x) {}
	  };

	  warning = function warning(condition, format) {
	    if (format === undefined) {
	      throw new Error('`warning(condition, format, ...args)` requires a warning ' + 'message argument');
	    }

	    if (format.indexOf('Failed Composite propType: ') === 0) {
	      return; // Ignore CompositeComponent proptype check.
	    }

	    if (!condition) {
	      for (var _len2 = arguments.length, args = Array(_len2 > 2 ? _len2 - 2 : 0), _key2 = 2; _key2 < _len2; _key2++) {
	        args[_key2 - 2] = arguments[_key2];
	      }

	      printWarning.apply(undefined, [format].concat(args));
	    }
	  };
	}

	module.exports = warning;
	/* WEBPACK VAR INJECTION */}.call(exports, __webpack_require__(5)))

/***/ }),
/* 10 */
/***/ (function(module, exports) {

	"use strict";

	/**
	 * Copyright (c) 2013-present, Facebook, Inc.
	 *
	 * This source code is licensed under the MIT license found in the
	 * LICENSE file in the root directory of this source tree.
	 *
	 * 
	 */

	function makeEmptyFunction(arg) {
	  return function () {
	    return arg;
	  };
	}

	/**
	 * This function accepts and discards inputs; it has no side effects. This is
	 * primarily useful idiomatically for overridable function endpoints which
	 * always need to be callable, since JS lacks a null-call idiom ala Cocoa.
	 */
	var emptyFunction = function emptyFunction() {};

	emptyFunction.thatReturns = makeEmptyFunction;
	emptyFunction.thatReturnsFalse = makeEmptyFunction(false);
	emptyFunction.thatReturnsTrue = makeEmptyFunction(true);
	emptyFunction.thatReturnsNull = makeEmptyFunction(null);
	emptyFunction.thatReturnsThis = function () {
	  return this;
	};
	emptyFunction.thatReturnsArgument = function (arg) {
	  return arg;
	};

	module.exports = emptyFunction;

/***/ }),
/* 11 */
/***/ (function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(process) {/**
	 * Copyright (c) 2013-present, Facebook, Inc.
	 *
	 * This source code is licensed under the MIT license found in the
	 * LICENSE file in the root directory of this source tree.
	 */

	if (process.env.NODE_ENV !== 'production') {
	  var REACT_ELEMENT_TYPE = (typeof Symbol === 'function' &&
	    Symbol.for &&
	    Symbol.for('react.element')) ||
	    0xeac7;

	  var isValidElement = function(object) {
	    return typeof object === 'object' &&
	      object !== null &&
	      object.$$typeof === REACT_ELEMENT_TYPE;
	  };

	  // By explicitly using `prop-types` you are opting into new development behavior.
	  // http://fb.me/prop-types-in-prod
	  var throwOnDirectAccess = true;
	  module.exports = __webpack_require__(12)(isValidElement, throwOnDirectAccess);
	} else {
	  // By explicitly using `prop-types` you are opting into new production behavior.
	  // http://fb.me/prop-types-in-prod
	  module.exports = __webpack_require__(15)();
	}

	/* WEBPACK VAR INJECTION */}.call(exports, __webpack_require__(5)))

/***/ }),
/* 12 */
/***/ (function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(process) {/**
	 * Copyright (c) 2013-present, Facebook, Inc.
	 *
	 * This source code is licensed under the MIT license found in the
	 * LICENSE file in the root directory of this source tree.
	 */

	'use strict';

	var emptyFunction = __webpack_require__(10);
	var invariant = __webpack_require__(8);
	var warning = __webpack_require__(9);
	var assign = __webpack_require__(6);

	var ReactPropTypesSecret = __webpack_require__(13);
	var checkPropTypes = __webpack_require__(14);

	module.exports = function(isValidElement, throwOnDirectAccess) {
	  /* global Symbol */
	  var ITERATOR_SYMBOL = typeof Symbol === 'function' && Symbol.iterator;
	  var FAUX_ITERATOR_SYMBOL = '@@iterator'; // Before Symbol spec.

	  /**
	   * Returns the iterator method function contained on the iterable object.
	   *
	   * Be sure to invoke the function with the iterable as context:
	   *
	   *     var iteratorFn = getIteratorFn(myIterable);
	   *     if (iteratorFn) {
	   *       var iterator = iteratorFn.call(myIterable);
	   *       ...
	   *     }
	   *
	   * @param {?object} maybeIterable
	   * @return {?function}
	   */
	  function getIteratorFn(maybeIterable) {
	    var iteratorFn = maybeIterable && (ITERATOR_SYMBOL && maybeIterable[ITERATOR_SYMBOL] || maybeIterable[FAUX_ITERATOR_SYMBOL]);
	    if (typeof iteratorFn === 'function') {
	      return iteratorFn;
	    }
	  }

	  /**
	   * Collection of methods that allow declaration and validation of props that are
	   * supplied to React components. Example usage:
	   *
	   *   var Props = require('ReactPropTypes');
	   *   var MyArticle = React.createClass({
	   *     propTypes: {
	   *       // An optional string prop named "description".
	   *       description: Props.string,
	   *
	   *       // A required enum prop named "category".
	   *       category: Props.oneOf(['News','Photos']).isRequired,
	   *
	   *       // A prop named "dialog" that requires an instance of Dialog.
	   *       dialog: Props.instanceOf(Dialog).isRequired
	   *     },
	   *     render: function() { ... }
	   *   });
	   *
	   * A more formal specification of how these methods are used:
	   *
	   *   type := array|bool|func|object|number|string|oneOf([...])|instanceOf(...)
	   *   decl := ReactPropTypes.{type}(.isRequired)?
	   *
	   * Each and every declaration produces a function with the same signature. This
	   * allows the creation of custom validation functions. For example:
	   *
	   *  var MyLink = React.createClass({
	   *    propTypes: {
	   *      // An optional string or URI prop named "href".
	   *      href: function(props, propName, componentName) {
	   *        var propValue = props[propName];
	   *        if (propValue != null && typeof propValue !== 'string' &&
	   *            !(propValue instanceof URI)) {
	   *          return new Error(
	   *            'Expected a string or an URI for ' + propName + ' in ' +
	   *            componentName
	   *          );
	   *        }
	   *      }
	   *    },
	   *    render: function() {...}
	   *  });
	   *
	   * @internal
	   */

	  var ANONYMOUS = '<<anonymous>>';

	  // Important!
	  // Keep this list in sync with production version in `./factoryWithThrowingShims.js`.
	  var ReactPropTypes = {
	    array: createPrimitiveTypeChecker('array'),
	    bool: createPrimitiveTypeChecker('boolean'),
	    func: createPrimitiveTypeChecker('function'),
	    number: createPrimitiveTypeChecker('number'),
	    object: createPrimitiveTypeChecker('object'),
	    string: createPrimitiveTypeChecker('string'),
	    symbol: createPrimitiveTypeChecker('symbol'),

	    any: createAnyTypeChecker(),
	    arrayOf: createArrayOfTypeChecker,
	    element: createElementTypeChecker(),
	    instanceOf: createInstanceTypeChecker,
	    node: createNodeChecker(),
	    objectOf: createObjectOfTypeChecker,
	    oneOf: createEnumTypeChecker,
	    oneOfType: createUnionTypeChecker,
	    shape: createShapeTypeChecker,
	    exact: createStrictShapeTypeChecker,
	  };

	  /**
	   * inlined Object.is polyfill to avoid requiring consumers ship their own
	   * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/is
	   */
	  /*eslint-disable no-self-compare*/
	  function is(x, y) {
	    // SameValue algorithm
	    if (x === y) {
	      // Steps 1-5, 7-10
	      // Steps 6.b-6.e: +0 != -0
	      return x !== 0 || 1 / x === 1 / y;
	    } else {
	      // Step 6.a: NaN == NaN
	      return x !== x && y !== y;
	    }
	  }
	  /*eslint-enable no-self-compare*/

	  /**
	   * We use an Error-like object for backward compatibility as people may call
	   * PropTypes directly and inspect their output. However, we don't use real
	   * Errors anymore. We don't inspect their stack anyway, and creating them
	   * is prohibitively expensive if they are created too often, such as what
	   * happens in oneOfType() for any type before the one that matched.
	   */
	  function PropTypeError(message) {
	    this.message = message;
	    this.stack = '';
	  }
	  // Make `instanceof Error` still work for returned errors.
	  PropTypeError.prototype = Error.prototype;

	  function createChainableTypeChecker(validate) {
	    if (process.env.NODE_ENV !== 'production') {
	      var manualPropTypeCallCache = {};
	      var manualPropTypeWarningCount = 0;
	    }
	    function checkType(isRequired, props, propName, componentName, location, propFullName, secret) {
	      componentName = componentName || ANONYMOUS;
	      propFullName = propFullName || propName;

	      if (secret !== ReactPropTypesSecret) {
	        if (throwOnDirectAccess) {
	          // New behavior only for users of `prop-types` package
	          invariant(
	            false,
	            'Calling PropTypes validators directly is not supported by the `prop-types` package. ' +
	            'Use `PropTypes.checkPropTypes()` to call them. ' +
	            'Read more at http://fb.me/use-check-prop-types'
	          );
	        } else if (process.env.NODE_ENV !== 'production' && typeof console !== 'undefined') {
	          // Old behavior for people using React.PropTypes
	          var cacheKey = componentName + ':' + propName;
	          if (
	            !manualPropTypeCallCache[cacheKey] &&
	            // Avoid spamming the console because they are often not actionable except for lib authors
	            manualPropTypeWarningCount < 3
	          ) {
	            warning(
	              false,
	              'You are manually calling a React.PropTypes validation ' +
	              'function for the `%s` prop on `%s`. This is deprecated ' +
	              'and will throw in the standalone `prop-types` package. ' +
	              'You may be seeing this warning due to a third-party PropTypes ' +
	              'library. See https://fb.me/react-warning-dont-call-proptypes ' + 'for details.',
	              propFullName,
	              componentName
	            );
	            manualPropTypeCallCache[cacheKey] = true;
	            manualPropTypeWarningCount++;
	          }
	        }
	      }
	      if (props[propName] == null) {
	        if (isRequired) {
	          if (props[propName] === null) {
	            return new PropTypeError('The ' + location + ' `' + propFullName + '` is marked as required ' + ('in `' + componentName + '`, but its value is `null`.'));
	          }
	          return new PropTypeError('The ' + location + ' `' + propFullName + '` is marked as required in ' + ('`' + componentName + '`, but its value is `undefined`.'));
	        }
	        return null;
	      } else {
	        return validate(props, propName, componentName, location, propFullName);
	      }
	    }

	    var chainedCheckType = checkType.bind(null, false);
	    chainedCheckType.isRequired = checkType.bind(null, true);

	    return chainedCheckType;
	  }

	  function createPrimitiveTypeChecker(expectedType) {
	    function validate(props, propName, componentName, location, propFullName, secret) {
	      var propValue = props[propName];
	      var propType = getPropType(propValue);
	      if (propType !== expectedType) {
	        // `propValue` being instance of, say, date/regexp, pass the 'object'
	        // check, but we can offer a more precise error message here rather than
	        // 'of type `object`'.
	        var preciseType = getPreciseType(propValue);

	        return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` of type ' + ('`' + preciseType + '` supplied to `' + componentName + '`, expected ') + ('`' + expectedType + '`.'));
	      }
	      return null;
	    }
	    return createChainableTypeChecker(validate);
	  }

	  function createAnyTypeChecker() {
	    return createChainableTypeChecker(emptyFunction.thatReturnsNull);
	  }

	  function createArrayOfTypeChecker(typeChecker) {
	    function validate(props, propName, componentName, location, propFullName) {
	      if (typeof typeChecker !== 'function') {
	        return new PropTypeError('Property `' + propFullName + '` of component `' + componentName + '` has invalid PropType notation inside arrayOf.');
	      }
	      var propValue = props[propName];
	      if (!Array.isArray(propValue)) {
	        var propType = getPropType(propValue);
	        return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` of type ' + ('`' + propType + '` supplied to `' + componentName + '`, expected an array.'));
	      }
	      for (var i = 0; i < propValue.length; i++) {
	        var error = typeChecker(propValue, i, componentName, location, propFullName + '[' + i + ']', ReactPropTypesSecret);
	        if (error instanceof Error) {
	          return error;
	        }
	      }
	      return null;
	    }
	    return createChainableTypeChecker(validate);
	  }

	  function createElementTypeChecker() {
	    function validate(props, propName, componentName, location, propFullName) {
	      var propValue = props[propName];
	      if (!isValidElement(propValue)) {
	        var propType = getPropType(propValue);
	        return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` of type ' + ('`' + propType + '` supplied to `' + componentName + '`, expected a single ReactElement.'));
	      }
	      return null;
	    }
	    return createChainableTypeChecker(validate);
	  }

	  function createInstanceTypeChecker(expectedClass) {
	    function validate(props, propName, componentName, location, propFullName) {
	      if (!(props[propName] instanceof expectedClass)) {
	        var expectedClassName = expectedClass.name || ANONYMOUS;
	        var actualClassName = getClassName(props[propName]);
	        return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` of type ' + ('`' + actualClassName + '` supplied to `' + componentName + '`, expected ') + ('instance of `' + expectedClassName + '`.'));
	      }
	      return null;
	    }
	    return createChainableTypeChecker(validate);
	  }

	  function createEnumTypeChecker(expectedValues) {
	    if (!Array.isArray(expectedValues)) {
	      process.env.NODE_ENV !== 'production' ? warning(false, 'Invalid argument supplied to oneOf, expected an instance of array.') : void 0;
	      return emptyFunction.thatReturnsNull;
	    }

	    function validate(props, propName, componentName, location, propFullName) {
	      var propValue = props[propName];
	      for (var i = 0; i < expectedValues.length; i++) {
	        if (is(propValue, expectedValues[i])) {
	          return null;
	        }
	      }

	      var valuesString = JSON.stringify(expectedValues);
	      return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` of value `' + propValue + '` ' + ('supplied to `' + componentName + '`, expected one of ' + valuesString + '.'));
	    }
	    return createChainableTypeChecker(validate);
	  }

	  function createObjectOfTypeChecker(typeChecker) {
	    function validate(props, propName, componentName, location, propFullName) {
	      if (typeof typeChecker !== 'function') {
	        return new PropTypeError('Property `' + propFullName + '` of component `' + componentName + '` has invalid PropType notation inside objectOf.');
	      }
	      var propValue = props[propName];
	      var propType = getPropType(propValue);
	      if (propType !== 'object') {
	        return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` of type ' + ('`' + propType + '` supplied to `' + componentName + '`, expected an object.'));
	      }
	      for (var key in propValue) {
	        if (propValue.hasOwnProperty(key)) {
	          var error = typeChecker(propValue, key, componentName, location, propFullName + '.' + key, ReactPropTypesSecret);
	          if (error instanceof Error) {
	            return error;
	          }
	        }
	      }
	      return null;
	    }
	    return createChainableTypeChecker(validate);
	  }

	  function createUnionTypeChecker(arrayOfTypeCheckers) {
	    if (!Array.isArray(arrayOfTypeCheckers)) {
	      process.env.NODE_ENV !== 'production' ? warning(false, 'Invalid argument supplied to oneOfType, expected an instance of array.') : void 0;
	      return emptyFunction.thatReturnsNull;
	    }

	    for (var i = 0; i < arrayOfTypeCheckers.length; i++) {
	      var checker = arrayOfTypeCheckers[i];
	      if (typeof checker !== 'function') {
	        warning(
	          false,
	          'Invalid argument supplied to oneOfType. Expected an array of check functions, but ' +
	          'received %s at index %s.',
	          getPostfixForTypeWarning(checker),
	          i
	        );
	        return emptyFunction.thatReturnsNull;
	      }
	    }

	    function validate(props, propName, componentName, location, propFullName) {
	      for (var i = 0; i < arrayOfTypeCheckers.length; i++) {
	        var checker = arrayOfTypeCheckers[i];
	        if (checker(props, propName, componentName, location, propFullName, ReactPropTypesSecret) == null) {
	          return null;
	        }
	      }

	      return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` supplied to ' + ('`' + componentName + '`.'));
	    }
	    return createChainableTypeChecker(validate);
	  }

	  function createNodeChecker() {
	    function validate(props, propName, componentName, location, propFullName) {
	      if (!isNode(props[propName])) {
	        return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` supplied to ' + ('`' + componentName + '`, expected a ReactNode.'));
	      }
	      return null;
	    }
	    return createChainableTypeChecker(validate);
	  }

	  function createShapeTypeChecker(shapeTypes) {
	    function validate(props, propName, componentName, location, propFullName) {
	      var propValue = props[propName];
	      var propType = getPropType(propValue);
	      if (propType !== 'object') {
	        return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` of type `' + propType + '` ' + ('supplied to `' + componentName + '`, expected `object`.'));
	      }
	      for (var key in shapeTypes) {
	        var checker = shapeTypes[key];
	        if (!checker) {
	          continue;
	        }
	        var error = checker(propValue, key, componentName, location, propFullName + '.' + key, ReactPropTypesSecret);
	        if (error) {
	          return error;
	        }
	      }
	      return null;
	    }
	    return createChainableTypeChecker(validate);
	  }

	  function createStrictShapeTypeChecker(shapeTypes) {
	    function validate(props, propName, componentName, location, propFullName) {
	      var propValue = props[propName];
	      var propType = getPropType(propValue);
	      if (propType !== 'object') {
	        return new PropTypeError('Invalid ' + location + ' `' + propFullName + '` of type `' + propType + '` ' + ('supplied to `' + componentName + '`, expected `object`.'));
	      }
	      // We need to check all keys in case some are required but missing from
	      // props.
	      var allKeys = assign({}, props[propName], shapeTypes);
	      for (var key in allKeys) {
	        var checker = shapeTypes[key];
	        if (!checker) {
	          return new PropTypeError(
	            'Invalid ' + location + ' `' + propFullName + '` key `' + key + '` supplied to `' + componentName + '`.' +
	            '\nBad object: ' + JSON.stringify(props[propName], null, '  ') +
	            '\nValid keys: ' +  JSON.stringify(Object.keys(shapeTypes), null, '  ')
	          );
	        }
	        var error = checker(propValue, key, componentName, location, propFullName + '.' + key, ReactPropTypesSecret);
	        if (error) {
	          return error;
	        }
	      }
	      return null;
	    }

	    return createChainableTypeChecker(validate);
	  }

	  function isNode(propValue) {
	    switch (typeof propValue) {
	      case 'number':
	      case 'string':
	      case 'undefined':
	        return true;
	      case 'boolean':
	        return !propValue;
	      case 'object':
	        if (Array.isArray(propValue)) {
	          return propValue.every(isNode);
	        }
	        if (propValue === null || isValidElement(propValue)) {
	          return true;
	        }

	        var iteratorFn = getIteratorFn(propValue);
	        if (iteratorFn) {
	          var iterator = iteratorFn.call(propValue);
	          var step;
	          if (iteratorFn !== propValue.entries) {
	            while (!(step = iterator.next()).done) {
	              if (!isNode(step.value)) {
	                return false;
	              }
	            }
	          } else {
	            // Iterator will provide entry [k,v] tuples rather than values.
	            while (!(step = iterator.next()).done) {
	              var entry = step.value;
	              if (entry) {
	                if (!isNode(entry[1])) {
	                  return false;
	                }
	              }
	            }
	          }
	        } else {
	          return false;
	        }

	        return true;
	      default:
	        return false;
	    }
	  }

	  function isSymbol(propType, propValue) {
	    // Native Symbol.
	    if (propType === 'symbol') {
	      return true;
	    }

	    // 19.4.3.5 Symbol.prototype[@@toStringTag] === 'Symbol'
	    if (propValue['@@toStringTag'] === 'Symbol') {
	      return true;
	    }

	    // Fallback for non-spec compliant Symbols which are polyfilled.
	    if (typeof Symbol === 'function' && propValue instanceof Symbol) {
	      return true;
	    }

	    return false;
	  }

	  // Equivalent of `typeof` but with special handling for array and regexp.
	  function getPropType(propValue) {
	    var propType = typeof propValue;
	    if (Array.isArray(propValue)) {
	      return 'array';
	    }
	    if (propValue instanceof RegExp) {
	      // Old webkits (at least until Android 4.0) return 'function' rather than
	      // 'object' for typeof a RegExp. We'll normalize this here so that /bla/
	      // passes PropTypes.object.
	      return 'object';
	    }
	    if (isSymbol(propType, propValue)) {
	      return 'symbol';
	    }
	    return propType;
	  }

	  // This handles more types than `getPropType`. Only used for error messages.
	  // See `createPrimitiveTypeChecker`.
	  function getPreciseType(propValue) {
	    if (typeof propValue === 'undefined' || propValue === null) {
	      return '' + propValue;
	    }
	    var propType = getPropType(propValue);
	    if (propType === 'object') {
	      if (propValue instanceof Date) {
	        return 'date';
	      } else if (propValue instanceof RegExp) {
	        return 'regexp';
	      }
	    }
	    return propType;
	  }

	  // Returns a string that is postfixed to a warning about an invalid type.
	  // For example, "undefined" or "of type array"
	  function getPostfixForTypeWarning(value) {
	    var type = getPreciseType(value);
	    switch (type) {
	      case 'array':
	      case 'object':
	        return 'an ' + type;
	      case 'boolean':
	      case 'date':
	      case 'regexp':
	        return 'a ' + type;
	      default:
	        return type;
	    }
	  }

	  // Returns class name of the object, if any.
	  function getClassName(propValue) {
	    if (!propValue.constructor || !propValue.constructor.name) {
	      return ANONYMOUS;
	    }
	    return propValue.constructor.name;
	  }

	  ReactPropTypes.checkPropTypes = checkPropTypes;
	  ReactPropTypes.PropTypes = ReactPropTypes;

	  return ReactPropTypes;
	};

	/* WEBPACK VAR INJECTION */}.call(exports, __webpack_require__(5)))

/***/ }),
/* 13 */
/***/ (function(module, exports) {

	/**
	 * Copyright (c) 2013-present, Facebook, Inc.
	 *
	 * This source code is licensed under the MIT license found in the
	 * LICENSE file in the root directory of this source tree.
	 */

	'use strict';

	var ReactPropTypesSecret = 'SECRET_DO_NOT_PASS_THIS_OR_YOU_WILL_BE_FIRED';

	module.exports = ReactPropTypesSecret;


/***/ }),
/* 14 */
/***/ (function(module, exports, __webpack_require__) {

	/* WEBPACK VAR INJECTION */(function(process) {/**
	 * Copyright (c) 2013-present, Facebook, Inc.
	 *
	 * This source code is licensed under the MIT license found in the
	 * LICENSE file in the root directory of this source tree.
	 */

	'use strict';

	if (process.env.NODE_ENV !== 'production') {
	  var invariant = __webpack_require__(8);
	  var warning = __webpack_require__(9);
	  var ReactPropTypesSecret = __webpack_require__(13);
	  var loggedTypeFailures = {};
	}

	/**
	 * Assert that the values match with the type specs.
	 * Error messages are memorized and will only be shown once.
	 *
	 * @param {object} typeSpecs Map of name to a ReactPropType
	 * @param {object} values Runtime values that need to be type-checked
	 * @param {string} location e.g. "prop", "context", "child context"
	 * @param {string} componentName Name of the component for error messages.
	 * @param {?Function} getStack Returns the component stack.
	 * @private
	 */
	function checkPropTypes(typeSpecs, values, location, componentName, getStack) {
	  if (process.env.NODE_ENV !== 'production') {
	    for (var typeSpecName in typeSpecs) {
	      if (typeSpecs.hasOwnProperty(typeSpecName)) {
	        var error;
	        // Prop type validation may throw. In case they do, we don't want to
	        // fail the render phase where it didn't fail before. So we log it.
	        // After these have been cleaned up, we'll let them throw.
	        try {
	          // This is intentionally an invariant that gets caught. It's the same
	          // behavior as without this statement except with a better message.
	          invariant(typeof typeSpecs[typeSpecName] === 'function', '%s: %s type `%s` is invalid; it must be a function, usually from ' + 'the `prop-types` package, but received `%s`.', componentName || 'React class', location, typeSpecName, typeof typeSpecs[typeSpecName]);
	          error = typeSpecs[typeSpecName](values, typeSpecName, componentName, location, null, ReactPropTypesSecret);
	        } catch (ex) {
	          error = ex;
	        }
	        warning(!error || error instanceof Error, '%s: type specification of %s `%s` is invalid; the type checker ' + 'function must return `null` or an `Error` but returned a %s. ' + 'You may have forgotten to pass an argument to the type checker ' + 'creator (arrayOf, instanceOf, objectOf, oneOf, oneOfType, and ' + 'shape all require an argument).', componentName || 'React class', location, typeSpecName, typeof error);
	        if (error instanceof Error && !(error.message in loggedTypeFailures)) {
	          // Only monitor this failure once because there tends to be a lot of the
	          // same error.
	          loggedTypeFailures[error.message] = true;

	          var stack = getStack ? getStack() : '';

	          warning(false, 'Failed %s type: %s%s', location, error.message, stack != null ? stack : '');
	        }
	      }
	    }
	  }
	}

	module.exports = checkPropTypes;

	/* WEBPACK VAR INJECTION */}.call(exports, __webpack_require__(5)))

/***/ }),
/* 15 */
/***/ (function(module, exports, __webpack_require__) {

	/**
	 * Copyright (c) 2013-present, Facebook, Inc.
	 *
	 * This source code is licensed under the MIT license found in the
	 * LICENSE file in the root directory of this source tree.
	 */

	'use strict';

	var emptyFunction = __webpack_require__(10);
	var invariant = __webpack_require__(8);
	var ReactPropTypesSecret = __webpack_require__(13);

	module.exports = function() {
	  function shim(props, propName, componentName, location, propFullName, secret) {
	    if (secret === ReactPropTypesSecret) {
	      // It is still safe when called from React.
	      return;
	    }
	    invariant(
	      false,
	      'Calling PropTypes validators directly is not supported by the `prop-types` package. ' +
	      'Use PropTypes.checkPropTypes() to call them. ' +
	      'Read more at http://fb.me/use-check-prop-types'
	    );
	  };
	  shim.isRequired = shim;
	  function getShim() {
	    return shim;
	  };
	  // Important!
	  // Keep this list in sync with production version in `./factoryWithTypeCheckers.js`.
	  var ReactPropTypes = {
	    array: shim,
	    bool: shim,
	    func: shim,
	    number: shim,
	    object: shim,
	    string: shim,
	    symbol: shim,

	    any: shim,
	    arrayOf: getShim,
	    element: shim,
	    instanceOf: getShim,
	    node: shim,
	    objectOf: getShim,
	    oneOf: getShim,
	    oneOfType: getShim,
	    shape: getShim,
	    exact: getShim
	  };

	  ReactPropTypes.checkPropTypes = emptyFunction;
	  ReactPropTypes.PropTypes = ReactPropTypes;

	  return ReactPropTypes;
	};


/***/ }),
/* 16 */
/***/ (function(module, exports, __webpack_require__) {

	var React = __webpack_require__(2);
	var createReactClass = __webpack_require__(3);
	var PropTypes = __webpack_require__(11);
	var NotificationItem = __webpack_require__(17);
	var Constants = __webpack_require__(19);

	var NotificationContainer = createReactClass({
	  displayName: 'NotificationContainer',


	  propTypes: {
	    position: PropTypes.string.isRequired,
	    notifications: PropTypes.array.isRequired,
	    getStyles: PropTypes.object
	  },

	  _style: {},

	  componentWillMount: function () {
	    function componentWillMount() {
	      // Fix position if width is overrided
	      this._style = this.props.getStyles.container(this.props.position);

	      if (this.props.getStyles.overrideWidth && (this.props.position === Constants.positions.tc || this.props.position === Constants.positions.bc)) {
	        this._style.marginLeft = -(this.props.getStyles.overrideWidth / 2);
	      }
	    }

	    return componentWillMount;
	  }(),

	  render: function () {
	    function render() {
	      var self = this;
	      var notifications;

	      if ([Constants.positions.bl, Constants.positions.br, Constants.positions.bc].indexOf(this.props.position) > -1) {
	        this.props.notifications.reverse();
	      }

	      notifications = this.props.notifications.map(function (notification) {
	        return React.createElement(NotificationItem, {
	          ref: 'notification-' + notification.uid,
	          key: notification.uid,
	          notification: notification,
	          getStyles: self.props.getStyles,
	          onRemove: self.props.onRemove,
	          noAnimation: self.props.noAnimation,
	          allowHTML: self.props.allowHTML,
	          children: self.props.children
	        });
	      });

	      return React.createElement(
	        'div',
	        { className: 'notifications-' + this.props.position, style: this._style },
	        notifications
	      );
	    }

	    return render;
	  }()
	});

	module.exports = NotificationContainer;

/***/ }),
/* 17 */
/***/ (function(module, exports, __webpack_require__) {

	var React = __webpack_require__(2);
	var createReactClass = __webpack_require__(3);
	var PropTypes = __webpack_require__(11);
	var ReactDOM = __webpack_require__(18);
	var Constants = __webpack_require__(19);
	var Helpers = __webpack_require__(20);
	var merge = __webpack_require__(6);

	/* From Modernizr */
	var whichTransitionEvent = function whichTransitionEvent() {
	  var el = document.createElement('fakeelement');
	  var transition;
	  var transitions = {
	    transition: 'transitionend',
	    OTransition: 'oTransitionEnd',
	    MozTransition: 'transitionend',
	    WebkitTransition: 'webkitTransitionEnd'
	  };

	  Object.keys(transitions).forEach(function (transitionKey) {
	    if (el.style[transitionKey] !== undefined) {
	      transition = transitions[transitionKey];
	    }
	  });

	  return transition;
	};

	var NotificationItem = createReactClass({
	  displayName: 'NotificationItem',


	  propTypes: {
	    notification: PropTypes.object,
	    getStyles: PropTypes.object,
	    onRemove: PropTypes.func,
	    allowHTML: PropTypes.bool,
	    noAnimation: PropTypes.bool,
	    children: PropTypes.oneOfType([PropTypes.string, PropTypes.element])
	  },

	  getDefaultProps: function () {
	    function getDefaultProps() {
	      return {
	        noAnimation: false,
	        onRemove: function () {
	          function onRemove() {}

	          return onRemove;
	        }(),
	        allowHTML: false
	      };
	    }

	    return getDefaultProps;
	  }(),

	  getInitialState: function () {
	    function getInitialState() {
	      return {
	        visible: undefined,
	        removed: false
	      };
	    }

	    return getInitialState;
	  }(),

	  componentWillMount: function () {
	    function componentWillMount() {
	      var getStyles = this.props.getStyles;
	      var level = this.props.notification.level;

	      this._noAnimation = this.props.noAnimation;

	      this._styles = {
	        notification: getStyles.byElement('notification')(level),
	        title: getStyles.byElement('title')(level),
	        dismiss: getStyles.byElement('dismiss')(level),
	        messageWrapper: getStyles.byElement('messageWrapper')(level),
	        actionWrapper: getStyles.byElement('actionWrapper')(level),
	        action: getStyles.byElement('action')(level)
	      };

	      if (!this.props.notification.dismissible) {
	        this._styles.notification.cursor = 'default';
	      }
	    }

	    return componentWillMount;
	  }(),

	  _styles: {},

	  _notificationTimer: null,

	  _height: 0,

	  _noAnimation: null,

	  _isMounted: false,

	  _removeCount: 0,

	  _getCssPropertyByPosition: function () {
	    function _getCssPropertyByPosition() {
	      var position = this.props.notification.position;
	      var css = {};

	      switch (position) {
	        case Constants.positions.tl:
	        case Constants.positions.bl:
	          css = {
	            property: 'left',
	            value: -200
	          };
	          break;

	        case Constants.positions.tr:
	        case Constants.positions.br:
	          css = {
	            property: 'right',
	            value: -200
	          };
	          break;

	        case Constants.positions.tc:
	          css = {
	            property: 'top',
	            value: -100
	          };
	          break;

	        case Constants.positions.bc:
	          css = {
	            property: 'bottom',
	            value: -100
	          };
	          break;

	        default:
	      }

	      return css;
	    }

	    return _getCssPropertyByPosition;
	  }(),

	  _defaultAction: function () {
	    function _defaultAction(event) {
	      var notification = this.props.notification;

	      event.preventDefault();
	      this._hideNotification();
	      if (typeof notification.action.callback === 'function') {
	        notification.action.callback();
	      }
	    }

	    return _defaultAction;
	  }(),

	  _hideNotification: function () {
	    function _hideNotification() {
	      if (this._notificationTimer) {
	        this._notificationTimer.clear();
	      }

	      if (this._isMounted) {
	        this.setState({
	          visible: false,
	          removed: true
	        });
	      }

	      if (this._noAnimation) {
	        this._removeNotification();
	      }
	    }

	    return _hideNotification;
	  }(),

	  _removeNotification: function () {
	    function _removeNotification() {
	      this.props.onRemove(this.props.notification.uid);
	    }

	    return _removeNotification;
	  }(),

	  _dismiss: function () {
	    function _dismiss() {
	      if (!this.props.notification.dismissible) {
	        return;
	      }

	      this._hideNotification();
	    }

	    return _dismiss;
	  }(),

	  _showNotification: function () {
	    function _showNotification() {
	      var self = this;
	      setTimeout(function () {
	        if (self._isMounted) {
	          self.setState({
	            visible: true
	          });
	        }
	      }, 50);
	    }

	    return _showNotification;
	  }(),

	  _onTransitionEnd: function () {
	    function _onTransitionEnd() {
	      if (this._removeCount > 0) return;
	      if (this.state.removed) {
	        this._removeCount += 1;
	        this._removeNotification();
	      }
	    }

	    return _onTransitionEnd;
	  }(),

	  componentDidMount: function () {
	    function componentDidMount() {
	      var self = this;
	      var transitionEvent = whichTransitionEvent();
	      var notification = this.props.notification;
	      var element = ReactDOM.findDOMNode(this);

	      this._height = element.offsetHeight;

	      this._isMounted = true;

	      // Watch for transition end
	      if (!this._noAnimation) {
	        if (transitionEvent) {
	          element.addEventListener(transitionEvent, this._onTransitionEnd);
	        } else {
	          this._noAnimation = true;
	        }
	      }

	      if (notification.autoDismiss) {
	        this._notificationTimer = new Helpers.Timer(function () {
	          self._hideNotification();
	        }, notification.autoDismiss * 1000);
	      }

	      this._showNotification();
	    }

	    return componentDidMount;
	  }(),

	  _handleMouseEnter: function () {
	    function _handleMouseEnter() {
	      var notification = this.props.notification;
	      if (notification.autoDismiss) {
	        this._notificationTimer.pause();
	      }
	    }

	    return _handleMouseEnter;
	  }(),

	  _handleMouseLeave: function () {
	    function _handleMouseLeave() {
	      var notification = this.props.notification;
	      if (notification.autoDismiss) {
	        this._notificationTimer.resume();
	      }
	    }

	    return _handleMouseLeave;
	  }(),

	  componentWillUnmount: function () {
	    function componentWillUnmount() {
	      var element = ReactDOM.findDOMNode(this);
	      var transitionEvent = whichTransitionEvent();
	      element.removeEventListener(transitionEvent, this._onTransitionEnd);
	      this._isMounted = false;
	    }

	    return componentWillUnmount;
	  }(),

	  _allowHTML: function () {
	    function _allowHTML(string) {
	      return { __html: string };
	    }

	    return _allowHTML;
	  }(),

	  render: function () {
	    function render() {
	      var notification = this.props.notification;
	      var className = 'notification notification-' + notification.level;
	      var notificationStyle = merge({}, this._styles.notification);
	      var cssByPos = this._getCssPropertyByPosition();
	      var dismiss = null;
	      var actionButton = null;
	      var title = null;
	      var message = null;

	      if (this.state.visible) {
	        className += ' notification-visible';
	      } else if (this.state.visible === false) {
	        className += ' notification-hidden';
	      }

	      if (!notification.dismissible) {
	        className += ' notification-not-dismissible';
	      }

	      if (this.props.getStyles.overrideStyle) {
	        if (!this.state.visible && !this.state.removed) {
	          notificationStyle[cssByPos.property] = cssByPos.value;
	        }

	        if (this.state.visible && !this.state.removed) {
	          notificationStyle.height = this._height;
	          notificationStyle[cssByPos.property] = 0;
	        }

	        if (this.state.removed) {
	          notificationStyle.overlay = 'hidden';
	          notificationStyle.height = 0;
	          notificationStyle.marginTop = 0;
	          notificationStyle.paddingTop = 0;
	          notificationStyle.paddingBottom = 0;
	        }
	        notificationStyle.opacity = this.state.visible ? this._styles.notification.isVisible.opacity : this._styles.notification.isHidden.opacity;
	      }

	      if (notification.title) {
	        title = React.createElement(
	          'h4',
	          { className: 'notification-title', style: this._styles.title },
	          notification.title
	        );
	      }

	      if (notification.message) {
	        if (this.props.allowHTML) {
	          message = React.createElement('div', { className: 'notification-message', style: this._styles.messageWrapper, dangerouslySetInnerHTML: this._allowHTML(notification.message) });
	        } else {
	          message = React.createElement(
	            'div',
	            { className: 'notification-message', style: this._styles.messageWrapper },
	            notification.message
	          );
	        }
	      }

	      if (notification.dismissible) {
	        dismiss = React.createElement(
	          'span',
	          { className: 'notification-dismiss', style: this._styles.dismiss },
	          '\xD7'
	        );
	      }

	      if (notification.action) {
	        actionButton = React.createElement(
	          'div',
	          { className: 'notification-action-wrapper', style: this._styles.actionWrapper },
	          React.createElement(
	            'button',
	            { className: 'notification-action-button',
	              onClick: this._defaultAction,
	              style: this._styles.action },
	            notification.action.label
	          )
	        );
	      }

	      if (notification.children) {
	        actionButton = notification.children;
	      }

	      return React.createElement(
	        'div',
	        { className: className, onClick: this._dismiss, onMouseEnter: this._handleMouseEnter, onMouseLeave: this._handleMouseLeave, style: notificationStyle },
	        title,
	        message,
	        dismiss,
	        actionButton
	      );
	    }

	    return render;
	  }()

	});

	module.exports = NotificationItem;

/***/ }),
/* 18 */
/***/ (function(module, exports) {

	module.exports = __WEBPACK_EXTERNAL_MODULE_18__;

/***/ }),
/* 19 */
/***/ (function(module, exports) {

	var CONSTANTS = {

	  // Positions
	  positions: {
	    tl: 'tl',
	    tr: 'tr',
	    tc: 'tc',
	    bl: 'bl',
	    br: 'br',
	    bc: 'bc'
	  },

	  // Levels
	  levels: {
	    success: 'success',
	    error: 'error',
	    warning: 'warning',
	    info: 'info'
	  },

	  // Notification defaults
	  notification: {
	    title: null,
	    message: null,
	    level: null,
	    position: 'tr',
	    autoDismiss: 5,
	    dismissible: true,
	    action: null
	  }
	};

	module.exports = CONSTANTS;

/***/ }),
/* 20 */
/***/ (function(module, exports) {

	var Helpers = {
	  Timer: function () {
	    function Timer(callback, delay) {
	      var timerId;
	      var start;
	      var remaining = delay;

	      this.pause = function () {
	        clearTimeout(timerId);
	        remaining -= new Date() - start;
	      };

	      this.resume = function () {
	        start = new Date();
	        clearTimeout(timerId);
	        timerId = setTimeout(callback, remaining);
	      };

	      this.clear = function () {
	        clearTimeout(timerId);
	      };

	      this.resume();
	    }

	    return Timer;
	  }()
	};

	module.exports = Helpers;

/***/ }),
/* 21 */
/***/ (function(module, exports) {

	// Used for calculations
	var defaultWidth = 320;
	var defaultColors = {
	  success: {
	    rgb: '94, 164, 0',
	    hex: '#5ea400'
	  },
	  error: {
	    rgb: '236, 61, 61',
	    hex: '#ec3d3d'
	  },
	  warning: {
	    rgb: '235, 173, 23',
	    hex: '#ebad1a'
	  },
	  info: {
	    rgb: '54, 156, 199',
	    hex: '#369cc7'
	  }
	};
	var defaultShadowOpacity = '0.9';

	var STYLES = {

	  Wrapper: {},
	  Containers: {
	    DefaultStyle: {
	      fontFamily: 'inherit',
	      position: 'fixed',
	      width: defaultWidth,
	      padding: '0 10px 10px 10px',
	      zIndex: 9998,
	      WebkitBoxSizing: 'border-box',
	      MozBoxSizing: 'border-box',
	      boxSizing: 'border-box',
	      height: 'auto'
	    },

	    tl: {
	      top: '0px',
	      bottom: 'auto',
	      left: '0px',
	      right: 'auto'
	    },

	    tr: {
	      top: '0px',
	      bottom: 'auto',
	      left: 'auto',
	      right: '0px'
	    },

	    tc: {
	      top: '0px',
	      bottom: 'auto',
	      margin: '0 auto',
	      left: '50%',
	      marginLeft: -(defaultWidth / 2)
	    },

	    bl: {
	      top: 'auto',
	      bottom: '0px',
	      left: '0px',
	      right: 'auto'
	    },

	    br: {
	      top: 'auto',
	      bottom: '0px',
	      left: 'auto',
	      right: '0px'
	    },

	    bc: {
	      top: 'auto',
	      bottom: '0px',
	      margin: '0 auto',
	      left: '50%',
	      marginLeft: -(defaultWidth / 2)
	    }

	  },

	  NotificationItem: {
	    DefaultStyle: {
	      position: 'relative',
	      width: '100%',
	      cursor: 'pointer',
	      borderRadius: '2px',
	      fontSize: '13px',
	      margin: '10px 0 0',
	      padding: '10px',
	      display: 'block',
	      WebkitBoxSizing: 'border-box',
	      MozBoxSizing: 'border-box',
	      boxSizing: 'border-box',
	      opacity: 0,
	      transition: '0.3s ease-in-out',
	      WebkitTransform: 'translate3d(0, 0, 0)',
	      transform: 'translate3d(0, 0, 0)',
	      willChange: 'transform, opacity',

	      isHidden: {
	        opacity: 0
	      },

	      isVisible: {
	        opacity: 1
	      }
	    },

	    success: {
	      borderTop: '2px solid ' + defaultColors.success.hex,
	      backgroundColor: '#f0f5ea',
	      color: '#4b583a',
	      WebkitBoxShadow: '0 0 1px rgba(' + defaultColors.success.rgb + ',' + defaultShadowOpacity + ')',
	      MozBoxShadow: '0 0 1px rgba(' + defaultColors.success.rgb + ',' + defaultShadowOpacity + ')',
	      boxShadow: '0 0 1px rgba(' + defaultColors.success.rgb + ',' + defaultShadowOpacity + ')'
	    },

	    error: {
	      borderTop: '2px solid ' + defaultColors.error.hex,
	      backgroundColor: '#f4e9e9',
	      color: '#412f2f',
	      WebkitBoxShadow: '0 0 1px rgba(' + defaultColors.error.rgb + ',' + defaultShadowOpacity + ')',
	      MozBoxShadow: '0 0 1px rgba(' + defaultColors.error.rgb + ',' + defaultShadowOpacity + ')',
	      boxShadow: '0 0 1px rgba(' + defaultColors.error.rgb + ',' + defaultShadowOpacity + ')'
	    },

	    warning: {
	      borderTop: '2px solid ' + defaultColors.warning.hex,
	      backgroundColor: '#f9f6f0',
	      color: '#5a5343',
	      WebkitBoxShadow: '0 0 1px rgba(' + defaultColors.warning.rgb + ',' + defaultShadowOpacity + ')',
	      MozBoxShadow: '0 0 1px rgba(' + defaultColors.warning.rgb + ',' + defaultShadowOpacity + ')',
	      boxShadow: '0 0 1px rgba(' + defaultColors.warning.rgb + ',' + defaultShadowOpacity + ')'
	    },

	    info: {
	      borderTop: '2px solid ' + defaultColors.info.hex,
	      backgroundColor: '#e8f0f4',
	      color: '#41555d',
	      WebkitBoxShadow: '0 0 1px rgba(' + defaultColors.info.rgb + ',' + defaultShadowOpacity + ')',
	      MozBoxShadow: '0 0 1px rgba(' + defaultColors.info.rgb + ',' + defaultShadowOpacity + ')',
	      boxShadow: '0 0 1px rgba(' + defaultColors.info.rgb + ',' + defaultShadowOpacity + ')'
	    }
	  },

	  Title: {
	    DefaultStyle: {
	      fontSize: '14px',
	      margin: '0 0 5px 0',
	      padding: 0,
	      fontWeight: 'bold'
	    },

	    success: {
	      color: defaultColors.success.hex
	    },

	    error: {
	      color: defaultColors.error.hex
	    },

	    warning: {
	      color: defaultColors.warning.hex
	    },

	    info: {
	      color: defaultColors.info.hex
	    }

	  },

	  MessageWrapper: {
	    DefaultStyle: {
	      margin: 0,
	      padding: 0
	    }
	  },

	  Dismiss: {
	    DefaultStyle: {
	      fontFamily: 'Arial',
	      fontSize: '17px',
	      position: 'absolute',
	      top: '4px',
	      right: '5px',
	      lineHeight: '15px',
	      backgroundColor: '#dededf',
	      color: '#ffffff',
	      borderRadius: '50%',
	      width: '14px',
	      height: '14px',
	      fontWeight: 'bold',
	      textAlign: 'center'
	    },

	    success: {
	      color: '#f0f5ea',
	      backgroundColor: '#b0ca92'
	    },

	    error: {
	      color: '#f4e9e9',
	      backgroundColor: '#e4bebe'
	    },

	    warning: {
	      color: '#f9f6f0',
	      backgroundColor: '#e1cfac'
	    },

	    info: {
	      color: '#e8f0f4',
	      backgroundColor: '#a4becb'
	    }
	  },

	  Action: {
	    DefaultStyle: {
	      background: '#ffffff',
	      borderRadius: '2px',
	      padding: '6px 20px',
	      fontWeight: 'bold',
	      margin: '10px 0 0 0',
	      border: 0
	    },

	    success: {
	      backgroundColor: defaultColors.success.hex,
	      color: '#ffffff'
	    },

	    error: {
	      backgroundColor: defaultColors.error.hex,
	      color: '#ffffff'
	    },

	    warning: {
	      backgroundColor: defaultColors.warning.hex,
	      color: '#ffffff'
	    },

	    info: {
	      backgroundColor: defaultColors.info.hex,
	      color: '#ffffff'
	    }
	  },

	  ActionWrapper: {
	    DefaultStyle: {
	      margin: 0,
	      padding: 0
	    }
	  }
	};

	module.exports = STYLES;

/***/ })
/******/ ])
});
;