"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var state_1 = require("../state");
var FilterBasedAccessor_1 = require("./FilterBasedAccessor");
var query_1 = require("../query");
var assign = require('lodash/assign');
var CheckboxFilterAccessor = (function (_super) {
    __extends(CheckboxFilterAccessor, _super);
    function CheckboxFilterAccessor(key, options) {
        _super.call(this, key, options.id);
        this.state = new state_1.State(false);
        this.options = options;
        this.filter = options.filter;
        this.state = this.state.create(options.defaultValue);
        this.translations = assign({}, options.translations);
    }
    CheckboxFilterAccessor.prototype.getDocCount = function () {
        return this.getAggregations([this.uuid, "doc_count"], 0);
    };
    CheckboxFilterAccessor.prototype.buildSharedQuery = function (query) {
        var _this = this;
        if (this.state.getValue()) {
            query = query.addFilter(this.uuid, this.filter)
                .addSelectedFilter({
                name: this.options.title || this.translate(this.key),
                value: this.options.label || this.translate("checkbox.on"),
                id: this.options.id,
                remove: function () { return _this.state = _this.state.setValue(false); }
            });
        }
        return query;
    };
    CheckboxFilterAccessor.prototype.buildOwnQuery = function (query) {
        var filters = query.getFilters();
        if (!this.state.getValue()) {
            if (filters)
                filters = query_1.BoolMust([filters, this.filter]);
            else
                filters = this.filter;
        }
        return query
            .setAggs(query_1.FilterBucket(this.uuid, filters));
    };
    CheckboxFilterAccessor.translations = {
        "checkbox.on": "active"
    };
    return CheckboxFilterAccessor;
}(FilterBasedAccessor_1.FilterBasedAccessor));
exports.CheckboxFilterAccessor = CheckboxFilterAccessor;
//# sourceMappingURL=CheckboxFilterAccessor.js.map