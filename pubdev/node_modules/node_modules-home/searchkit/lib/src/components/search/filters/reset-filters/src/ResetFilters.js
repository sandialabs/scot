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
var core_1 = require("../../../../../core");
var defaults = require("lodash/defaults");
var ResetFiltersDisplay = (function (_super) {
    __extends(ResetFiltersDisplay, _super);
    function ResetFiltersDisplay() {
        _super.apply(this, arguments);
    }
    ResetFiltersDisplay.prototype.render = function () {
        var _a = this.props, bemBlock = _a.bemBlock, hasFilters = _a.hasFilters, translate = _a.translate, resetFilters = _a.resetFilters, clearAllLabel = _a.clearAllLabel;
        return (React.createElement("div", null, React.createElement(core_1.FastClick, {handler: resetFilters}, React.createElement("div", {className: bemBlock().state({ disabled: !hasFilters })}, React.createElement("div", {className: bemBlock("reset")}, clearAllLabel)))));
    };
    ResetFiltersDisplay = __decorate([
        core_1.PureRender, 
        __metadata('design:paramtypes', [])
    ], ResetFiltersDisplay);
    return ResetFiltersDisplay;
}(React.Component));
exports.ResetFiltersDisplay = ResetFiltersDisplay;
var ResetFilters = (function (_super) {
    __extends(ResetFilters, _super);
    function ResetFilters(props) {
        _super.call(this, props);
        this.translations = ResetFilters.translations;
        this.resetFilters = this.resetFilters.bind(this);
    }
    ResetFilters.prototype.defineBEMBlocks = function () {
        return {
            container: (this.props.mod || "sk-reset-filters")
        };
    };
    ResetFilters.prototype.defineAccessor = function () {
        return new core_1.ResetSearchAccessor(this.props.options);
    };
    ResetFilters.prototype.resetFilters = function () {
        this.accessor.performReset();
        this.searchkit.performSearch();
    };
    ResetFilters.prototype.render = function () {
        var props = {
            bemBlock: this.bemBlocks.container,
            resetFilters: this.resetFilters,
            hasFilters: this.accessor.canReset(),
            translate: this.translate,
            clearAllLabel: this.translate("reset.clear_all")
        };
        return React.createElement(this.props.component, props);
    };
    ResetFilters.translations = {
        "reset.clear_all": "Clear all filters"
    };
    ResetFilters.propTypes = defaults({
        translations: core_1.SearchkitComponent.translationsPropType(ResetFilters.translations),
        component: React.PropTypes.func,
        options: React.PropTypes.object
    }, core_1.SearchkitComponent.propTypes);
    ResetFilters.defaultProps = {
        component: ResetFiltersDisplay
    };
    return ResetFilters;
}(core_1.SearchkitComponent));
exports.ResetFilters = ResetFilters;
//# sourceMappingURL=ResetFilters.js.map