"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var React = require("react");
var core_1 = require("../../../../../core");
var defaults = require("lodash/defaults");
var map = require("lodash/map");
var identity = require("lodash/identity");
var HierarchicalMenuFilter = (function (_super) {
    __extends(HierarchicalMenuFilter, _super);
    function HierarchicalMenuFilter() {
        _super.apply(this, arguments);
    }
    HierarchicalMenuFilter.prototype.defineBEMBlocks = function () {
        var blockClass = this.props.mod || "sk-hierarchical-menu";
        return {
            container: blockClass + "-list",
            option: blockClass + "-option"
        };
    };
    HierarchicalMenuFilter.prototype.defineAccessor = function () {
        var _a = this.props, id = _a.id, title = _a.title, fields = _a.fields, _b = _a.size, size = _b === void 0 ? 0 : _b, orderKey = _a.orderKey, orderDirection = _a.orderDirection;
        return new core_1.HierarchicalFacetAccessor(id, {
            id: id, title: title, fields: fields, size: size, orderKey: orderKey, orderDirection: orderDirection
        });
    };
    HierarchicalMenuFilter.prototype.addFilter = function (option, level) {
        this.accessor.state = this.accessor.state.toggleLevel(level, option.key);
        this.searchkit.performSearch();
    };
    HierarchicalMenuFilter.prototype.renderOption = function (level, option) {
        var _this = this;
        var block = this.bemBlocks.option;
        var countFormatter = this.props.countFormatter;
        var className = block().state({
            selected: this.accessor.state.contains(level, option.key)
        });
        return (React.createElement("div", {key: option.key}, React.createElement(core_1.FastClick, {handler: this.addFilter.bind(this, option, level)}, React.createElement("div", {className: className}, React.createElement("div", {className: block("text")}, this.translate(option.key)), React.createElement("div", {className: block("count")}, countFormatter(option.doc_count)))), (function () {
            if (_this.accessor.resultsState.contains(level, option.key)) {
                return _this.renderOptions(level + 1);
            }
        })()));
    };
    HierarchicalMenuFilter.prototype.renderOptions = function (level) {
        var block = this.bemBlocks.container;
        return (React.createElement("div", {className: block("hierarchical-options")}, map(this.accessor.getBuckets(level), this.renderOption.bind(this, level))));
    };
    HierarchicalMenuFilter.prototype.render = function () {
        var block = this.bemBlocks.container;
        var classname = block()
            .mix("filter--" + this.props.id)
            .state({
            disabled: this.accessor.getBuckets(0).length == 0
        });
        return (React.createElement("div", {className: classname}, React.createElement("div", {className: block("header")}, this.props.title), React.createElement("div", {className: block("root")}, this.renderOptions(0))));
    };
    HierarchicalMenuFilter.defaultProps = {
        countFormatter: identity
    };
    HierarchicalMenuFilter.propTypes = defaults({
        id: React.PropTypes.string.isRequired,
        fields: React.PropTypes.arrayOf(React.PropTypes.string).isRequired,
        title: React.PropTypes.string.isRequired,
        orderKey: React.PropTypes.string,
        orderDirection: React.PropTypes.oneOf(["asc", "desc"]),
        countFormatter: React.PropTypes.func
    }, core_1.SearchkitComponent.propTypes);
    return HierarchicalMenuFilter;
}(core_1.SearchkitComponent));
exports.HierarchicalMenuFilter = HierarchicalMenuFilter;
//# sourceMappingURL=HierarchicalMenuFilter.js.map