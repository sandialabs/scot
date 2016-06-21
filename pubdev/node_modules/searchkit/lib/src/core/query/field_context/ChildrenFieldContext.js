"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var FieldContext_1 = require('./FieldContext');
var query_dsl_1 = require("../query_dsl");
var get = require("lodash/get");
var ChildrenFieldContext = (function (_super) {
    __extends(ChildrenFieldContext, _super);
    function ChildrenFieldContext(fieldOptions) {
        _super.call(this, fieldOptions);
        if (!get(this.fieldOptions, "options.childType")) {
            throw new Error("fieldOptions type:children requires options.childType");
        }
    }
    ChildrenFieldContext.prototype.getAggregationPath = function () {
        return "inner";
    };
    ChildrenFieldContext.prototype.wrapAggregations = function () {
        var aggregations = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            aggregations[_i - 0] = arguments[_i];
        }
        return [query_dsl_1.ChildrenBucket.apply(void 0, ["inner", this.fieldOptions.options.childType].concat(aggregations))];
    };
    ChildrenFieldContext.prototype.wrapFilter = function (filter) {
        return query_dsl_1.HasChildQuery(this.fieldOptions.options.childType, filter, this.fieldOptions.options);
    };
    return ChildrenFieldContext;
}(FieldContext_1.FieldContext));
exports.ChildrenFieldContext = ChildrenFieldContext;
//# sourceMappingURL=ChildrenFieldContext.js.map