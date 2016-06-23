"use strict";
var React = require('react');
var omitBy = require('lodash/omitBy');
var isUndefined = require('lodash/isUndefined');
var defaults = require('lodash/defaults');
exports.RenderComponentPropType = React.PropTypes.oneOfType([
    function (props, propName, componentName) {
        return isUndefined(props[propName]) || (props[propName]["prototype"] instanceof React.Component);
    },
    React.PropTypes.element,
    React.PropTypes.func,
]);
function renderComponent(component, props, children) {
    if (props === void 0) { props = {}; }
    if (children === void 0) { children = null; }
    var isReactComponent = (component["prototype"] instanceof React.Component ||
        (component["prototype"] && component["prototype"].isReactComponent) ||
        typeof component === 'function');
    if (isReactComponent) {
        return React.createElement(component, props, children);
    }
    else if (React.isValidElement(component)) {
        return React.cloneElement(component, omitBy(props, isUndefined), children);
    }
    console.warn("Invalid component", component);
    return null;
}
exports.renderComponent = renderComponent;
//# sourceMappingURL=RenderComponent.js.map