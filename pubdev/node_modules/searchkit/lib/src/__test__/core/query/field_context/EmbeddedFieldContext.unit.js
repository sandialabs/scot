"use strict";
var _this = this;
var _1 = require("../../../../");
describe("EmbeddedFieldContext", function () {
    beforeEach(function () {
        _this.fieldContext = _1.FieldContextFactory({
            type: "embedded"
        });
    });
    it("should be instance of EmbeddedFieldContext", function () {
        expect(_this.fieldContext).toEqual(jasmine.any(_1.EmbeddedFieldContext));
    });
    it("getAggregationPath()", function () {
        expect(_this.fieldContext.getAggregationPath())
            .toBe(undefined);
    });
    it("wrapAggregations()", function () {
        expect(_this.fieldContext.wrapAggregations(1, 2))
            .toEqual([1, 2]);
    });
    it("wrapFilter()", function () {
        expect(_this.fieldContext.wrapFilter("aFilter"))
            .toBe("aFilter");
    });
});
//# sourceMappingURL=EmbeddedFieldContext.unit.js.map