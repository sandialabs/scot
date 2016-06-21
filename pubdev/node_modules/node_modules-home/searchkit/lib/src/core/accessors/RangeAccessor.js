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
var RangeAccessor = (function (_super) {
    __extends(RangeAccessor, _super);
    function RangeAccessor(key, options) {
        _super.call(this, key, options.id);
        this.state = new state_1.ObjectState({});
        this.options = options;
        this.options.fieldOptions = this.options.fieldOptions || { type: "embedded" };
        this.options.fieldOptions.field = this.options.field;
        this.fieldContext = query_1.FieldContextFactory(this.options.fieldOptions);
    }
    RangeAccessor.prototype.buildSharedQuery = function (query) {
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
    RangeAccessor.prototype.getBuckets = function () {
        return this.getAggregations([
            this.key,
            this.fieldContext.getAggregationPath(),
            this.key, "buckets"], []);
    };
    RangeAccessor.prototype.isDisabled = function () {
        if (this.options.loadHistogram) {
            var maxValue = get(maxBy(this.getBuckets(), "doc_count"), "doc_count", 0);
            return maxValue === 0;
        }
        else {
            return this.getAggregations([
                this.key,
                this.fieldContext.getAggregationPath(),
                this.key, "value"], 0) === 0;
        }
    };
    RangeAccessor.prototype.getInterval = function () {
        if (this.options.interval) {
            return this.options.interval;
        }
        return Math.ceil((this.options.max - this.options.min) / 20);
    };
    RangeAccessor.prototype.buildOwnQuery = function (query) {
        var otherFilters = query.getFiltersWithoutKeys(this.key);
        var filters = query_1.BoolMust([
            otherFilters,
            this.fieldContext.wrapFilter(query_1.RangeQuery(this.options.field, {
                gte: this.options.min, lte: this.options.max
            }))
        ]);
        var metric;
        if (this.options.loadHistogram) {
            metric = query_1.HistogramBucket(this.key, this.options.field, {
                "interval": this.getInterval(),
                "min_doc_count": 0,
                "extended_bounds": {
                    "min": this.options.min,
                    "max": this.options.max
                }
            });
        }
        else {
            metric = query_1.CardinalityMetric(this.key, this.options.field);
        }
        return query.setAggs(query_1.FilterBucket.apply(void 0, [this.key, filters].concat(this.fieldContext.wrapAggregations(metric))));
    };
    return RangeAccessor;
}(FilterBasedAccessor_1.FilterBasedAccessor));
exports.RangeAccessor = RangeAccessor;
//# sourceMappingURL=RangeAccessor.js.map