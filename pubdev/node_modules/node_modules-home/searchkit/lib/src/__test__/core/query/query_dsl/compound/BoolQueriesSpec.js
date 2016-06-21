"use strict";
var _this = this;
var _1 = require("../../../../../");
describe("BoolQueries", function () {
    beforeEach(function () {
        _this.testBool = function (boolFn, operator) {
            expect(boolFn([])).toEqual({});
            expect(boolFn(["filter"])).toEqual("filter");
            expect(boolFn(["filter1", "filter2"])).toEqual({
                bool: (_a = {}, _a[operator] = ["filter1", "filter2"], _a)
            });
            var _a;
        };
    });
    it("BoolMust", function () {
        _this.testBool(_1.BoolMust, "must");
    });
    it("BoolShould", function () {
        _this.testBool(_1.BoolShould, "should");
    });
    it("BoolMustNot", function () {
        expect(_1.BoolMustNot([])).toEqual({});
        expect(_1.BoolMustNot(["filter"])).toEqual({ bool: { must_not: "filter" } });
        expect(_1.BoolMustNot(["filter1", "filter2"])).toEqual({
            bool: { must_not: ["filter1", "filter2"] }
        });
    });
    it("should flatten BoolMust", function () {
        var query = _1.BoolMust([
            "filter1",
            _1.BoolMust(["filter2", "filter3"]),
            "filter4",
            _1.BoolMust(["filter5", "filter6"]),
        ]);
        expect(query).toEqual({
            bool: {
                must: ["filter1", "filter2", "filter3", "filter4", "filter5", "filter6"]
            }
        });
    });
    it("should flatten BoolShould", function () {
        var query = _1.BoolShould([
            "filter1",
            _1.BoolShould(["filter2", "filter3"]),
            "filter4"
        ]);
        expect(query).toEqual({
            bool: {
                should: ["filter1", "filter2", "filter3", "filter4"]
            }
        });
    });
    it("should not flatten BoolShould in BoolMust", function () {
        var query = _1.BoolMust([
            "filter1",
            _1.BoolShould(["filter2", "filter3"]),
            "filter4",
            _1.BoolMust(["filter5", "filter6"]),
        ]);
        expect(query).toEqual({
            bool: {
                must: [
                    "filter1",
                    { bool: { should: ["filter2", "filter3"] } },
                    "filter4", "filter5", "filter6"
                ]
            }
        });
    });
    it("should not flatten BoolMustNot", function () {
        var query = _1.BoolMustNot([
            "filter1",
            _1.BoolMustNot(["filter2", "filter3"]),
            "filter4"
        ]);
        expect(query).toEqual({
            bool: {
                must_not: [
                    "filter1",
                    { bool: { must_not: ["filter2", "filter3"] } },
                    "filter4"
                ]
            }
        });
    });
    it("should remove empty filters", function () {
        var query = _1.BoolMust([
            {},
            "filter4"
        ]);
        expect(query).toEqual("filter4");
    });
});
//# sourceMappingURL=BoolQueriesSpec.js.map