"use strict";
var _this = this;
var _1 = require("../../../../");
describe("NestedFieldContext", function () {
    beforeEach(function () {
        _this.fieldContext = _1.FieldContextFactory({
            type: "nested",
            options: {
                path: "tags",
                score_mode: "sum"
            }
        });
    });
    it("should be instance of NestedFieldContext", function () {
        expect(_this.fieldContext).toEqual(jasmine.any(_1.NestedFieldContext));
    });
    it("should validate missing path", function () {
        expect(function () {
            return _1.FieldContextFactory({ type: "nested" });
        }).toThrowError("fieldOptions type:nested requires options.path");
    });
    it("getAggregationPath()", function () {
        expect(_this.fieldContext.getAggregationPath())
            .toBe("inner");
    });
    it("wrapAggregations()", function () {
        var agg1 = _1.TermsBucket("terms", "name");
        var agg2 = _1.TermsBucket("terms", "color");
        expect(_this.fieldContext.wrapAggregations(agg1, agg2))
            .toEqual([_1.NestedBucket("inner", "tags", agg1, agg2)]);
    });
    it("wrapFilter()", function () {
        var termFilter = _1.TermQuery("color", "red");
        expect(_this.fieldContext.wrapFilter(termFilter))
            .toEqual(_1.NestedQuery("tags", termFilter, { score_mode: 'sum' }));
    });
});
//# sourceMappingURL=NestedFieldContext.unit.js.map