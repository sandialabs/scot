"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var _1 = require("./");
var each = require("lodash/each");
var ResetSearchAccessor = (function (_super) {
    __extends(ResetSearchAccessor, _super);
    function ResetSearchAccessor(options) {
        if (options === void 0) { options = { query: true, filter: true, pagination: true }; }
        _super.call(this);
        this.options = options;
    }
    ResetSearchAccessor.prototype.canReset = function () {
        var query = this.searchkit.query;
        var options = this.options;
        return ((options.pagination && query.getFrom() > 0) ||
            (options.query && query.getQueryString().length > 0) ||
            (options.filter && query.getSelectedFilters().length > 0));
    };
    ResetSearchAccessor.prototype.performReset = function () {
        var query = this.searchkit.query;
        if (this.options.query) {
            this.searchkit.getQueryAccessor().resetState();
        }
        if (this.options.filter) {
            var filters = this.searchkit.getAccessorsByType(_1.FilterBasedAccessor);
            each(filters, function (accessor) { return accessor.resetState(); });
            each(query.getSelectedFilters() || [], function (f) { return f.remove(); });
        }
        var paginationAccessor = this.searchkit.getAccessorByType(_1.PaginationAccessor);
        if (this.options.pagination && paginationAccessor) {
            paginationAccessor.resetState();
        }
    };
    return ResetSearchAccessor;
}(_1.Accessor));
exports.ResetSearchAccessor = ResetSearchAccessor;
//# sourceMappingURL=ResetSearchAccessor.js.map