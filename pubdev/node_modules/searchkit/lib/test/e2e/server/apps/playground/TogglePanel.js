"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var React = require("react");
var bemBlock = require('bem-cn');
var TogglePanel = (function (_super) {
    __extends(TogglePanel, _super);
    function TogglePanel(props) {
        _super.call(this, props);
        this.state = {
            collapsed: props.collapsable
        };
    }
    TogglePanel.prototype.toggleCollapsed = function () {
        this.setState({
            collapsed: !this.state.collapsed
        });
    };
    TogglePanel.prototype.componentDidMount = function () {
        console.log('componentDidMount');
    };
    TogglePanel.prototype.componentWillUnmount = function () {
        console.log('componentWillUnmount');
    };
    TogglePanel.prototype.render = function () {
        var _a = this.props, title = _a.title, mod = _a.mod, className = _a.className, disabled = _a.disabled, children = _a.children, collapsable = _a.collapsable, rightComponent = _a.rightComponent;
        var collapsed = this.state.collapsed;
        var bemBlocks = {
            container: bemBlock(mod)
        };
        var block = bemBlocks.container;
        var containerClass = block()
            .mix(className)
            .state({ disabled: disabled });
        var titleDiv;
        if (collapsable) {
            var arrowClass = collapsed ? 'sk-arrow-right' : 'sk-arrow-down';
            titleDiv = (React.createElement("div", {className: block("header").state({ collapsable: collapsable }), onClick: this.toggleCollapsed.bind(this)}, rightComponent ? React.createElement("div", {style: { float: 'right' }}, rightComponent) : undefined, React.createElement("span", {className: arrowClass}), " ", title));
        }
        else {
            titleDiv = (React.createElement("div", {className: block("header")}, rightComponent ? React.createElement("div", {style: { float: 'right' }}, rightComponent) : undefined, title));
        }
        return (React.createElement("div", {className: containerClass}, titleDiv, React.createElement("div", {className: block("content").state({ collapsed: collapsed })}, children)));
    };
    TogglePanel.propTypes = {
        title: React.PropTypes.string,
        disabled: React.PropTypes.bool,
        mod: React.PropTypes.string,
        className: React.PropTypes.string,
        collapsable: React.PropTypes.bool,
    };
    TogglePanel.defaultProps = {
        disabled: false,
        collapsable: false,
        mod: "sk-panel"
    };
    return TogglePanel;
}(React.Component));
exports.TogglePanel = TogglePanel;
//# sourceMappingURL=TogglePanel.js.map