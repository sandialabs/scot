import _extends from 'babel-runtime/helpers/extends';
import _classCallCheck from 'babel-runtime/helpers/classCallCheck';
import _createClass from 'babel-runtime/helpers/createClass';
import _possibleConstructorReturn from 'babel-runtime/helpers/possibleConstructorReturn';
import _inherits from 'babel-runtime/helpers/inherits';
import _difference from 'lodash/difference';
import _isUndefined from 'lodash/isUndefined';
import _startsWith from 'lodash/startsWith';
import _filter from 'lodash/filter';
import _isEmpty from 'lodash/isEmpty';
import _keys from 'lodash/keys';
import _intersection from 'lodash/intersection';
import _has from 'lodash/has';
import _each from 'lodash/each'; /* eslint-disable no-console */
/**
 * Why choose inheritance over a HOC?  Multiple advantages for this particular use case.
 * In short, we need identical functionality to setState(), unless there is a prop defined
 * for the state key.  Also:
 *
 * 1. Single Renders
 *    Calling trySetState() in constructor(), componentWillMount(), or componentWillReceiveProps()
 *    does not cause two renders. Consumers and tests do not have to wait two renders to get state.
 *    See www.react.run/4kJFdKoxb/27 for an example of this issue.
 *
 * 2. Simple Testing
 *    Using a HOC means you must either test the undecorated component or test through the decorator.
 *    Testing the undecorated component means you must mock the decorator functionality.
 *    Testing through the HOC means you can not simply shallow render your component.
 *
 * 3. Statics
 *    HOC wrap instances, so statics are no longer accessible.  They can be hoisted, but this is more
 *    looping over properties and storing references.  We rely heavily on statics for testing and sub
 *    components.
 *
 * 4. Instance Methods
 *    Some instance methods may be exposed to users via refs.  Again, these are lost with HOC unless
 *    hoisted and exposed by the HOC.
 */

import { Component } from 'react';

var getDefaultPropName = function getDefaultPropName(prop) {
  return 'default' + (prop[0].toUpperCase() + prop.slice(1));
};

/**
 * Return the auto controlled state value for a give prop. The initial value is chosen in this order:
 *  - regular props
 *  - then, default props
 *  - then, initial state
 *  - then, `checked` defaults to false
 *  - then, `value` defaults to '' or [] if props.multiple
 *  - else, undefined
 *
 *  @param {string} propName A prop name
 *  @param {object} [props] A props object
 *  @param {object} [state] A state object
 *  @param {boolean} [includeDefaults=false] Whether or not to heed the default props or initial state
 */
export var getAutoControlledStateValue = function getAutoControlledStateValue(propName, props, state) {
  var includeDefaults = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : false;

  // regular props
  var propValue = props[propName];
  if (propValue !== undefined) return propValue;

  if (includeDefaults) {
    // defaultProps
    var defaultProp = props[getDefaultPropName(propName)];
    if (defaultProp !== undefined) return defaultProp;

    // initial state - state may be null or undefined
    if (state) {
      var initialState = state[propName];
      if (initialState !== undefined) return initialState;
    }
  }

  // React doesn't allow changing from uncontrolled to controlled components,
  // default checked/value if they were not present.
  if (propName === 'checked') return false;
  if (propName === 'value') return props.multiple ? [] : '';

  // otherwise, undefined
};

var AutoControlledComponent = function (_Component) {
  _inherits(AutoControlledComponent, _Component);

  function AutoControlledComponent() {
    var _ref;

    var _temp, _this, _ret;

    _classCallCheck(this, AutoControlledComponent);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = _possibleConstructorReturn(this, (_ref = AutoControlledComponent.__proto__ || Object.getPrototypeOf(AutoControlledComponent)).call.apply(_ref, [this].concat(args))), _this), _this.trySetState = function (maybeState, state) {
      var autoControlledProps = _this.constructor.autoControlledProps;

      if (process.env.NODE_ENV !== 'production') {
        var name = _this.constructor.name;
        // warn about failed attempts to setState for keys not listed in autoControlledProps

        var illegalKeys = _difference(_keys(maybeState), autoControlledProps);
        if (!_isEmpty(illegalKeys)) {
          console.error([name + ' called trySetState() with controlled props: "' + illegalKeys + '".', 'State will not be set.', 'Only props in static autoControlledProps will be set on state.'].join(' '));
        }
      }

      var newState = Object.keys(maybeState).reduce(function (acc, prop) {
        // ignore props defined by the parent
        if (_this.props[prop] !== undefined) return acc;

        // ignore props not listed in auto controlled props
        if (autoControlledProps.indexOf(prop) === -1) return acc;

        acc[prop] = maybeState[prop];
        return acc;
      }, {});

      if (state) newState = _extends({}, newState, state);

      if (Object.keys(newState).length > 0) _this.setState(newState);
    }, _temp), _possibleConstructorReturn(_this, _ret);
  }

  _createClass(AutoControlledComponent, [{
    key: 'componentWillMount',
    value: function componentWillMount() {
      var _this2 = this;

      var autoControlledProps = this.constructor.autoControlledProps;


      if (process.env.NODE_ENV !== 'production') {
        var _constructor = this.constructor,
            defaultProps = _constructor.defaultProps,
            name = _constructor.name,
            propTypes = _constructor.propTypes;
        // require static autoControlledProps

        if (!autoControlledProps) {
          console.error('Auto controlled ' + name + ' must specify a static autoControlledProps array.');
        }

        // require propTypes
        _each(autoControlledProps, function (prop) {
          var defaultProp = getDefaultPropName(prop);
          // regular prop
          if (!_has(propTypes, defaultProp)) {
            console.error(name + ' is missing "' + defaultProp + '" propTypes validation for auto controlled prop "' + prop + '".');
          }
          // its default prop
          if (!_has(propTypes, prop)) {
            console.error(name + ' is missing propTypes validation for auto controlled prop "' + prop + '".');
          }
        });

        // prevent autoControlledProps in defaultProps
        //
        // When setting state, auto controlled props values always win (so the parent can manage them).
        // It is not reasonable to decipher the difference between props from the parent and defaultProps.
        // Allowing defaultProps results in trySetState always deferring to the defaultProp value.
        // Auto controlled props also listed in defaultProps can never be updated.
        //
        // To set defaults for an AutoControlled prop, you can set the initial state in the
        // constructor or by using an ES7 property initializer:
        // https://babeljs.io/blog/2015/06/07/react-on-es6-plus#property-initializers
        var illegalDefaults = _intersection(autoControlledProps, _keys(defaultProps));
        if (!_isEmpty(illegalDefaults)) {
          console.error(['Do not set defaultProps for autoControlledProps. You can set defaults by', 'setting state in the constructor or using an ES7 property initializer', '(https://babeljs.io/blog/2015/06/07/react-on-es6-plus#property-initializers)', 'See ' + name + ' props: "' + illegalDefaults + '".'].join(' '));
        }

        // prevent listing defaultProps in autoControlledProps
        //
        // Default props are automatically handled.
        // Listing defaults in autoControlledProps would result in allowing defaultDefaultValue props.
        var illegalAutoControlled = _filter(autoControlledProps, function (prop) {
          return _startsWith(prop, 'default');
        });
        if (!_isEmpty(illegalAutoControlled)) {
          console.error(['Do not add default props to autoControlledProps.', 'Default props are automatically handled.', 'See ' + name + ' autoControlledProps: "' + illegalAutoControlled + '".'].join(' '));
        }
      }

      // Auto controlled props are copied to state.
      // Set initial state by copying auto controlled props to state.
      // Also look for the default prop for any auto controlled props (foo => defaultFoo)
      // so we can set initial values from defaults.
      var initialAutoControlledState = autoControlledProps.reduce(function (acc, prop) {
        acc[prop] = getAutoControlledStateValue(prop, _this2.props, _this2.state, true);

        if (process.env.NODE_ENV !== 'production') {
          var defaultPropName = getDefaultPropName(prop);
          var _name = _this2.constructor.name;
          // prevent defaultFoo={} along side foo={}

          if (defaultPropName in _this2.props && prop in _this2.props) {
            console.error(_name + ' prop "' + prop + '" is auto controlled. Specify either ' + defaultPropName + ' or ' + prop + ', but not both.');
          }
        }

        return acc;
      }, {});

      this.state = _extends({}, this.state, initialAutoControlledState);
    }
  }, {
    key: 'componentWillReceiveProps',
    value: function componentWillReceiveProps(nextProps) {
      var _this3 = this;

      var autoControlledProps = this.constructor.autoControlledProps;

      // Solve the next state for autoControlledProps

      var newState = autoControlledProps.reduce(function (acc, prop) {
        var isNextUndefined = _isUndefined(nextProps[prop]);
        var propWasRemoved = !_isUndefined(_this3.props[prop]) && isNextUndefined;

        // if next is defined then use its value
        if (!isNextUndefined) acc[prop] = nextProps[prop];

        // reinitialize state for props just removed / set undefined
        else if (propWasRemoved) acc[prop] = getAutoControlledStateValue(prop, nextProps);

        return acc;
      }, {});

      if (Object.keys(newState).length > 0) this.setState(newState);
    }

    /**
     * Safely attempt to set state for props that might be controlled by the user.
     * Second argument is a state object that is always passed to setState.
     * @param {object} maybeState State that corresponds to controlled props.
     * @param {object} [state] Actual state, useful when you also need to setState.
     */

  }]);

  return AutoControlledComponent;
}(Component);

export default AutoControlledComponent;