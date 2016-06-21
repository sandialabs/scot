"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var React = require("react");
var core_1 = require("../../../../core");
var ui_1 = require("../../../ui");
var bemBlock = require('bem-cn');
var defaults = require('lodash/defaults');
var groupBy = require('lodash/groupBy');
var size = require('lodash/size');
var toArray = require('lodash/toArray');
var forEach = require('lodash/forEach');
var map = require('lodash/map');
var GroupedSelectedFilters = (function (_super) {
    __extends(GroupedSelectedFilters, _super);
    function GroupedSelectedFilters(props) {
        _super.call(this, props);
        this.translate = this.translate.bind(this);
        this.removeFilter = this.removeFilter.bind(this);
        this.removeFilters = this.removeFilters.bind(this);
    }
    GroupedSelectedFilters.prototype.defineBEMBlocks = function () {
        var blockName = (this.props.mod || "sk-filter-groups");
        return {
            container: blockName
        };
    };
    GroupedSelectedFilters.prototype.getFilters = function () {
        return this.getQuery().getSelectedFilters();
    };
    GroupedSelectedFilters.prototype.getGroupedFilters = function () {
        var filters = this.getFilters();
        var groupedFilters = [];
        return toArray(groupBy(filters, 'id'));
    };
    GroupedSelectedFilters.prototype.hasFilters = function () {
        return size(this.getFilters()) > 0;
    };
    GroupedSelectedFilters.prototype.removeFilter = function (filter) {
        filter.remove();
        this.searchkit.performSearch();
    };
    GroupedSelectedFilters.prototype.removeFilters = function (filters) {
        forEach(filters, function (filter) { return filter.remove(); });
        this.searchkit.performSearch();
    };
    GroupedSelectedFilters.prototype.render = function () {
        var _this = this;
        var groupComponent = this.props.groupComponent;
        if (!this.hasFilters()) {
            return null;
        }
        return (React.createElement("div", {className: this.bemBlocks.container()}, map(this.getGroupedFilters(), function (filters) {
            return React.createElement(groupComponent, {
                key: filters[0].id,
                className: filters[0].id ? "filter-group-" + filters[0].id : undefined,
                title: _this.translate(filters[0].name),
                filters: filters,
                translate: _this.translate,
                removeFilter: _this.removeFilter,
                removeFilters: _this.removeFilters
            });
        })));
    };
    GroupedSelectedFilters.propTypes = defaults({}, core_1.SearchkitComponent.propTypes);
    GroupedSelectedFilters.defaultProps = {
        groupComponent: ui_1.FilterGroup
    };
    return GroupedSelectedFilters;
}(core_1.SearchkitComponent));
exports.GroupedSelectedFilters = GroupedSelectedFilters;
//# sourceMappingURL=GroupedSelectedFilters.js.map