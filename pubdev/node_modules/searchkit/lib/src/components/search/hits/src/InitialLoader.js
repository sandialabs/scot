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
var core_1 = require("../../../../core");
var defaults = require("lodash/defaults");
var InitialViewDisplay = (function (_super) {
    __extends(InitialViewDisplay, _super);
    function InitialViewDisplay() {
        _super.apply(this, arguments);
    }
    InitialViewDisplay.prototype.render = function () {
        return (React.createElement("div", {className: this.props.bemBlocks.container()}, React.createElement("div", {"data-qa": "initial-loading", className: this.props.bemBlocks.container("initial-loading")})));
    };
    InitialViewDisplay = __decorate([
        core_1.PureRender, 
        __metadata('design:paramtypes', [])
    ], InitialViewDisplay);
    return InitialViewDisplay;
}(React.Component));
exports.InitialViewDisplay = InitialViewDisplay;
var InitialLoader = (function (_super) {
    __extends(InitialLoader, _super);
    function InitialLoader() {
        _super.apply(this, arguments);
    }
    InitialLoader.prototype.defineBEMBlocks = function () {
        var block = (this.props.mod || "sk-initial-loader");
        return {
            container: block
        };
    };
    InitialLoader.prototype.render = function () {
        if (this.isInitialLoading()) {
            return React.createElement(this.props.component, {
                bemBlocks: this.bemBlocks
            });
        }
        return null;
    };
    InitialLoader.defaultProps = {
        component: InitialViewDisplay
    };
    InitialLoader.propTypes = defaults({
        component: React.PropTypes.func
    }, core_1.SearchkitComponent.propTypes);
    return InitialLoader;
}(core_1.SearchkitComponent));
exports.InitialLoader = InitialLoader;
//# sourceMappingURL=InitialLoader.js.map