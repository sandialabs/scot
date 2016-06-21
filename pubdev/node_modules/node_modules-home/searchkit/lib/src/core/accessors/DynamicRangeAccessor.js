"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var FilterBasedAccessor_1 = require("./FilterBasedAccessor");
var state_1 = require("../state");
var query_1 = require("../query");
var maxBy = require("lodash/maxBy");
var get = require("lodash/get");
var DynamicRangeAccessor = (function (_super) {
    __extends(DynamicRangeAccessor, _super);
    function DynamicRangeAccessor(key, options) {
        _super.call(this, key, options.id);
        this.state = new state_1.ObjectState({});
        this.options = options;
        this.options.fieldOptions = this.options.fieldOptions || { type: "embedded" };
        this.options.fieldOptions.field = this.options.field;
        this.fieldContext = query_1.FieldContextFactory(this.options.fieldOptions);
    }
    DynamicRangeAccessor.prototype.buildSharedQuery = function (query) {
        var _this = this;
        if (this.state.hasValue()) {
            var val = this.state.getValue();
            var rangeFilter = this.fieldContext.wrapFilter(query_1.RangeQuery(this.options.field, {
                gte: val.min, lte: val.max
            }));
            var selectedFilter = {
                name: this.translate(this.options.title),
                value: val.min + " - " + val.max,
                id: this.options.id,
                remove: function () {
                    _this.state = _this.state.clear();
                }
            };
            return query
                .addFilter(this.key, rangeFilter)
                .addSelectedFilter(selectedFilter);
        }
        return query;
    };
    DynamicRangeAccessor.prototype.getStat = function (stat) {
        return this.getAggregations([
            this.key,
            this.fieldContext.getAggregationPath(),
            this.key, stat], 0);
    };
    DynamicRangeAccessor.prototype.isDisabled = function () {
        return (this.getStat("count") === 0) || (this.getStat("min") === this.getStat("max"));
    };
    DynamicRangeAccessor.prototype.buildOwnQuery = function (query) {
        var otherFilters = query.getFiltersWithoutKeys(this.key);
        return query.setAggs(query_1.FilterBucket.apply(void 0, [this.key, otherFilters].concat(this.fieldContext.wrapAggregations(query_1.StatsMetric(this.key, this.options.field)))));
    };
    return DynamicRangeAccessor;
}(FilterBasedAccessor_1.FilterBasedAccessor));
exports.DynamicRangeAccessor = DynamicRangeAccessor;
//# sourceMappingURL=DynamicRangeAccessor.js.map