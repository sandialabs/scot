"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var FieldContext_1 = require('./FieldContext');
var query_dsl_1 = require("../query_dsl");
var get = require("lodash/get");
var NestedFieldContext = (function (_super) {
    __extends(NestedFieldContext, _super);
    function NestedFieldContext(fieldOptions) {
        _super.call(this, fieldOptions);
        if (!get(this.fieldOptions, "options.path")) {
            throw new Error("fieldOptions type:nested requires options.path");
        }
    }
    NestedFieldContext.prototype.getAggregationPath = function () {
        return "inner";
    };
    NestedFieldContext.prototype.wrapAggregations = function () {
        var aggregations = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            aggregations[_i - 0] = arguments[_i];
        }
        return [query_dsl_1.NestedBucket.apply(void 0, ["inner", this.fieldOptions.options.path].concat(aggregations))];
    };
    NestedFieldContext.prototype.wrapFilter = function (filter) {
        return query_dsl_1.NestedQuery(this.fieldOptions.options.path, filter, this.fieldOptions.options);
    };
    return NestedFieldContext;
}(FieldContext_1.FieldContext));
exports.NestedFieldContext = NestedFieldContext;
//# sourceMappingURL=NestedFieldContext.js.map