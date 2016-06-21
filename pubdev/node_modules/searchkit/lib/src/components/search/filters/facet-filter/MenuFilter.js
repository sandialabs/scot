"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var ui_1 = require('../../../ui');
var FacetFilter_1 = require("./FacetFilter");
var defaults = require("lodash/defaults");
var map = require("lodash/map");
var concat = require("lodash/concat");
var isUndefined = require("lodash/isUndefined");
var FacetFilterProps_1 = require("./FacetFilterProps");
var allItem = {
    key: "$all", label: "All"
};
var MenuFilter = (function (_super) {
    __extends(MenuFilter, _super);
    function MenuFilter() {
        _super.apply(this, arguments);
    }
    MenuFilter.prototype.toggleFilter = function (option) {
        if (option === allItem.key || this.accessor.state.contains(option)) {
            this.accessor.state = this.accessor.state.clear();
        }
        else {
            this.accessor.state = this.accessor.state.setValue([option]);
        }
        this.searchkit.performSearch();
    };
    MenuFilter.prototype.setFilters = function (options) {
        this.toggleFilter(options[0]);
    };
    MenuFilter.prototype.getSelectedItems = function () {
        var selectedValue = this.accessor.state.getValue()[0];
        return [!isUndefined(selectedValue) ? selectedValue : allItem.key];
    };
    MenuFilter.prototype.getItems = function () {
        var all = {
            key: allItem.key,
            label: allItem.label,
            doc_count: this.accessor.getDocCount()
        };
        return concat([all], this.accessor.getBuckets());
    };
    MenuFilter.propTypes = defaults({}, FacetFilterProps_1.FacetFilterPropTypes.propTypes);
    MenuFilter.defaultProps = defaults({
        listComponent: ui_1.ItemList,
        operator: "OR"
    }, FacetFilter_1.FacetFilter.defaultProps);
    return MenuFilter;
}(FacetFilter_1.FacetFilter));
exports.MenuFilter = MenuFilter;
//# sourceMappingURL=MenuFilter.js.map