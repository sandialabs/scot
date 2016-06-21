"use strict";
var _this = this;
var _1 = require("../../../../");
describe("ChildrenFieldContext", function () {
    beforeEach(function () {
        _this.fieldContext = _1.FieldContextFactory({
            type: "children",
            options: {
                childType: "tags",
                score_mode: "sum"
            }
        });
    });
    it("should be instance of ChildrenFieldContext", function () {
        expect(_this.fieldContext).toEqual(jasmine.any(_1.ChildrenFieldContext));
    });
    it("should validate missing childType", function () {
        expect(function () {
            return _1.FieldContextFactory({ type: "children" });
        }).toThrowError("fieldOptions type:children requires options.childType");
    });
    it("getAggregationPath()", function () {
        expect(_this.fieldContext.getAggregationPath())
            .toBe("inner");
    });
    it("wrapAggregations()", function () {
        var agg1 = _1.TermsBucket("terms", "name");
        var agg2 = _1.TermsBucket("terms", "color");
        expect(_this.fieldContext.wrapAggregations(agg1, agg2))
            .toEqual([_1.ChildrenBucket("inner", "tags", agg1, agg2)]);
    });
    it("wrapFilter()", function () {
        var termFilter = _1.TermQuery("color", "red");
        expect(_this.fieldContext.wrapFilter(termFilter))
            .toEqual(_1.HasChildQuery("tags", termFilter, { score_mode: 'sum' }));
    });
});
//# sourceMappingURL=ChildrenFieldContext.unit.js.map