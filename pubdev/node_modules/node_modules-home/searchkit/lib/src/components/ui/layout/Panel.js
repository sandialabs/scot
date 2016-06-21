"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var React = require("react");
var bemBlock = require('bem-cn');
var core_1 = require("../../../core");
var Panel = (function (_super) {
    __extends(Panel, _super);
    function Panel(props) {
        _super.call(this, props);
        this.state = {
            collapsed: props.defaultCollapsed
        };
    }
    Panel.prototype.componentWillReceiveProps = function (nextProps) {
        if (nextProps.defaultCollapsed != this.props.defaultCollapsed) {
            this.setState({
                collapsed: nextProps.defaultCollapsed
            });
        }
    };
    Panel.prototype.toggleCollapsed = function () {
        this.setState({
            collapsed: !this.state.collapsed
        });
    };
    Panel.prototype.render = function () {
        var _a = this.props, title = _a.title, mod = _a.mod, className = _a.className, disabled = _a.disabled, children = _a.children, collapsable = _a.collapsable;
        var collapsed = collapsable && this.state.collapsed;
        var bemBlocks = {
            container: bemBlock(mod)
        };
        var block = bemBlocks.container;
        var containerClass = block()
            .mix(className)
            .state({ disabled: disabled });
        var titleDiv;
        if (collapsable) {
            titleDiv = (React.createElement("div", {className: block("header").state({ collapsable: collapsable, collapsed: collapsed }), onClick: this.toggleCollapsed.bind(this)}, title));
        }
        else {
            titleDiv = React.createElement("div", {className: block("header")}, title);
        }
        return (React.createElement("div", {className: containerClass}, titleDiv, React.createElement("div", {className: block("content").state({ collapsed: collapsed })}, children)));
    };
    Panel.propTypes = {
        title: React.PropTypes.string,
        disabled: React.PropTypes.bool,
        mod: React.PropTypes.string,
        className: React.PropTypes.string,
        collapsable: React.PropTypes.bool,
        defaultCollapsed: React.PropTypes.bool
    };
    Panel.defaultProps = {
        disabled: false,
        collapsable: false,
        defaultCollapsed: true,
        mod: "sk-panel"
    };
    Panel = __decorate([
        core_1.PureRender, 
        __metadata('design:paramtypes', [Object])
    ], Panel);
    return Panel;
}(React.Component));
exports.Panel = Panel;
//# sourceMappingURL=Panel.js.map