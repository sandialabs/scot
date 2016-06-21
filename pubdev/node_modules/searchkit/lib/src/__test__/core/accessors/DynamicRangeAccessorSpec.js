"use strict";
var _this = this;
var _1 = require("../../../");
describe("DynamicRangeAccessor", function () {
    beforeEach(function () {
        _this.accessor = new _1.DynamicRangeAccessor("metascore", {
            title: "Metascore",
            id: "metascore",
            field: "metaScore"
        });
    });
    it("getStat()", function () {
        _this.accessor.results = {
            aggregations: {
                metascore: {
                    metascore: {
                        min: 0,
                        max: 100
                    }
                }
            }
        };
        expect(_this.accessor.getStat("max"))
            .toEqual(100);
        expect(_this.accessor.getStat("dd"))
            .toEqual(0);
    });
    it("isDisabled()", function () {
        _this.accessor.results = {
            aggregations: {
                metascore: {
                    metascore: {
                        min: 0,
                        max: 100,
                        count: 100
                    }
                }
            }
        };
        expect(_this.accessor.isDisabled()).toEqual(false);
        _this.accessor.results = {
            aggregations: {
                metascore: {
                    metascore: {
                        min: 100,
                        max: 100,
                        count: 100
                    }
                }
            }
        };
        expect(_this.accessor.isDisabled()).toEqual(true);
        _this.accessor.results = {
            aggregations: {
                metascore: {
                    metascore: {
                        min: 0,
                        max: 0,
                        count: 0
                    }
                }
            }
        };
        expect(_this.accessor.isDisabled()).toEqual(true);
    });
    describe("build query", function () {
        it("buildSharedQuery()", function () {
            var query = new _1.ImmutableQuery();
            _this.accessor.state = new _1.ObjectState({ min: 20, max: 70 });
            query = _this.accessor.buildSharedQuery(query);
            expect(query.query.filter).toEqual(_1.RangeQuery("metaScore", { gte: 20, lte: 70 }));
            var selectedFilter = query.getSelectedFilters()[0];
            expect(selectedFilter).toEqual(jasmine.objectContaining({
                name: "Metascore", value: "20 - 70", id: "metascore"
            }));
            selectedFilter.remove();
            expect(_this.accessor.state.getValue()).toEqual({});
        });
        it("buildSharedQuery() - empty", function () {
            _this.accessor.state = new _1.ObjectState();
            var query = new _1.ImmutableQuery();
            var newQuery = _this.accessor.buildSharedQuery(query);
            expect(newQuery).toBe(query);
        });
    });
    describe("buildOwnQuery", function () {
        beforeEach(function () {
            _this.accessor.state = new _1.ObjectState({ min: 20, max: 70 });
            _this.query = new _1.ImmutableQuery()
                .addFilter("rating_uuid", _1.BoolShould(["PG"]));
            _this.query = _this.accessor.buildSharedQuery(_this.query);
        });
        it("build own query", function () {
            var query = _this.accessor.buildOwnQuery(_this.query);
            expect(query.query.aggs).toEqual(_1.FilterBucket("metascore", _1.BoolMust([
                _1.BoolShould(["PG"])
            ]), _1.StatsMetric("metascore", "metaScore")));
        });
    });
    describe("Nested support", function () {
        beforeEach(function () {
            _this.accessor = new _1.DynamicRangeAccessor("metascore", {
                title: "Metascore",
                id: "metascore",
                field: "metaScore",
                fieldOptions: {
                    type: 'nested',
                    options: { path: "nestedField" }
                }
            });
        });
        it("getStats()", function () {
            _this.accessor.results = {
                aggregations: {
                    metascore: {
                        inner: {
                            metascore: {
                                min: 0,
                                max: 100
                            }
                        }
                    }
                }
            };
            expect(_this.accessor.getStat("max"))
                .toEqual(100);
            expect(_this.accessor.getStat("dd"))
                .toEqual(0);
        });
        it("buildSharedQuery()", function () {
            var query = new _1.ImmutableQuery();
            _this.accessor.state = new _1.ObjectState({ min: 20, max: 70 });
            query = _this.accessor.buildSharedQuery(query);
            expect(query.query.filter).toEqual(_1.NestedQuery("nestedField", _1.RangeQuery("metaScore", { gte: 20, lte: 70 })));
        });
        it("build own query", function () {
            _this.accessor.state = new _1.ObjectState({ min: 20, max: 70 });
            _this.query = new _1.ImmutableQuery()
                .addFilter("rating_uuid", _1.BoolShould(["PG"]));
            _this.query = _this.accessor.buildSharedQuery(_this.query);
            var query = _this.accessor.buildOwnQuery(_this.query);
            expect(query.query.aggs).toEqual(_1.FilterBucket("metascore", _1.BoolMust([
                _1.BoolShould(["PG"])
            ]), _1.NestedBucket("inner", "nestedField", _1.StatsMetric("metascore", "metaScore"))));
        });
    });
});
//# sourceMappingURL=DynamicRangeAccessorSpec.js.map