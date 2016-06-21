"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var FieldContext_1 = require("./FieldContext");
var EmbeddedFieldContext = (function (_super) {
    __extends(EmbeddedFieldContext, _super);
    function EmbeddedFieldContext() {
        _super.apply(this, arguments);
    }
    EmbeddedFieldContext.prototype.getAggregationPath = function () {
        return undefined;
    };
    EmbeddedFieldContext.prototype.wrapAggregations = function () {
        var aggregations = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            aggregations[_i - 0] = arguments[_i];
        }
        return aggregations;
    };
    EmbeddedFieldContext.prototype.wrapFilter = function (filter) {
        return filter;
    };
    return EmbeddedFieldContext;
}(FieldContext_1.FieldContext));
exports.EmbeddedFieldContext = EmbeddedFieldContext;
//# sourceMappingURL=EmbeddedFieldContext.js.map