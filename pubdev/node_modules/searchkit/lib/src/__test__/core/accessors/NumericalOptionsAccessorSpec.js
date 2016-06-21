"use strict";
var _this = this;
var _1 = require("../../../");
var _ = require("lodash");
describe("NumericOptionsAccessor", function () {
    beforeEach(function () {
        _this.searchkit = _1.SearchkitManager.mock();
        _this.options = {
            field: "price",
            id: "price_id",
            title: "”Price",
            options: [
                { title: "All" },
                { title: "Cheap", from: 1, to: 11 },
                { title: "Affordable", from: 11, to: 21 },
                { title: "Pricey", from: 21, to: 101 }
            ]
        };
        _this.accessor = new _1.NumericOptionsAccessor("categories", _this.options);
        _this.accessor.uuid = "9999";
        _this.searchkit.addAccessor(_this.accessor);
        spyOn(_this.searchkit, "performSearch");
        _this.query = new _1.ImmutableQuery();
        _this.toPlainObject = function (ob) {
            return JSON.parse(JSON.stringify(ob));
        };
    });
    it("constructor()", function () {
        expect(_this.accessor.key).toBe("categories");
        expect(_this.accessor.options.options).toEqual([
            { title: 'All', key: 'all' },
            { title: 'Cheap', from: 1, to: 11, key: '1_11' },
            { title: 'Affordable', from: 11, to: 21, key: '11_21' },
            { title: 'Pricey', from: 21, to: 101, key: '21_101' }
        ]);
    });
    it("getBuckets()", function () {
        _this.accessor.results = {
            aggregations: {
                "9999": {
                    categories: {
                        buckets: [
                            { key: 1, doc_count: 1 },
                            { key: 2, doc_count: 2 },
                            { key: 3, doc_count: 3 },
                            { key: 4, doc_count: 0 }
                        ]
                    }
                }
            }
        };
        expect(_.map(_this.accessor.getBuckets(), "key"))
            .toEqual([1, 2, 3]);
    });
    it("getDefaultOption()", function () {
        expect(_this.accessor.getDefaultOption()).toEqual(_this.options.options[0]);
    });
    it("getSelectedOptions(), getSelectedOrDefaultOptions()", function () {
        expect(_this.accessor.getSelectedOptions()).toEqual([]);
        expect(_this.accessor.getSelectedOrDefaultOptions())
            .toEqual([_this.options.options[0]]);
        _this.accessor.state = new _1.ArrayState(["all", "21_101"]);
        var expectedSelected = [
            _this.options.options[0],
            _this.options.options[3]
        ];
        expect(_this.accessor.getSelectedOptions()).toEqual(expectedSelected);
        _this.accessor.state = new _1.ArrayState([]);
        // test no default code path
        _this.options.options[0].from = 10;
        expect(_this.accessor.getSelectedOrDefaultOptions()).toEqual([]);
    });
    it("setOptions()", function () {
        expect(_this.accessor.state.getValue()).toEqual([]);
        _this.accessor.setOptions(["Affordable", "Pricey"]);
        expect(_this.accessor.state.getValue()).toEqual(["11_21", "21_101"]);
        expect(_this.searchkit.performSearch).toHaveBeenCalled();
    });
    it("setOption(), single key", function () {
        expect(_this.accessor.state.getValue()).toEqual([]);
        _this.accessor.setOptions(["Affordable"]);
        expect(_this.accessor.state.getValue()).toEqual(["11_21"]);
        expect(_this.searchkit.performSearch).toHaveBeenCalled();
        _this.accessor.setOptions(["All"]);
        expect(_this.accessor.state.getValue()).toEqual([]);
    });
    describe("toggleOption()", function () {
        it("no option found", function () {
            _this.accessor.toggleOption("none");
            expect(_this.searchkit.performSearch).not.toHaveBeenCalled();
            expect(_this.accessor.state.getValue()).toEqual([]);
        });
        it("defaultOption", function () {
            _this.accessor.toggleOption("All");
            expect(_this.searchkit.performSearch).toHaveBeenCalled();
            expect(_this.accessor.state.getValue()).toEqual([]);
        });
        it("multiple select", function () {
            _this.options.multiselect = true;
            _this.accessor.state = new _1.ArrayState(["21_101"]);
            _this.accessor.toggleOption("Affordable");
            expect(_this.searchkit.performSearch).toHaveBeenCalled();
            expect(_this.accessor.state.getValue()).toEqual(["21_101", "11_21"]);
        });
        it("single select", function () {
            _this.options.multiselect = false;
            _this.accessor.state = new _1.ArrayState(["21_101"]);
            _this.accessor.toggleOption("Affordable");
            expect(_this.searchkit.performSearch).toHaveBeenCalled();
            expect(_this.accessor.state.getValue()).toEqual(["11_21"]);
        });
    });
    it("getRanges()", function () {
        expect(_this.accessor.getRanges()).toEqual([
            { key: 'All' },
            { key: 'Cheap', from: 1, to: 11 },
            { key: 'Affordable', from: 11, to: 21 },
            { key: 'Pricey', from: 21, to: 101 }
        ]);
    });
    it("buildSharedQuery()", function () {
        _this.accessor.state = new _1.ArrayState(["11_21", "21_101"]);
        var query = _this.accessor.buildSharedQuery(_this.query);
        var expected = _1.BoolMust([
            _1.BoolShould([
                _1.RangeQuery("price", { gte: 11, lt: 21 }),
                _1.RangeQuery("price", { gte: 21, lt: 101 })
            ])
        ]);
        expect(query.query.filter).toEqual(expected);
        expect(_.keys(query.index.filtersMap))
            .toEqual(["9999"]);
        var selectedFilters = query.getSelectedFilters();
        expect(selectedFilters.length).toEqual(2);
        expect(_this.toPlainObject(selectedFilters[0])).toEqual({
            name: '”Price', value: 'Affordable', id: 'price_id',
        });
        expect(_this.toPlainObject(selectedFilters[1])).toEqual({
            name: '”Price', value: 'Pricey', id: 'price_id',
        });
        expect(_this.accessor.state.getValue()).toEqual(["11_21", "21_101"]);
        selectedFilters[0].remove();
        expect(_this.accessor.state.getValue()).toEqual(["21_101"]);
    });
    it("buildOwnQuery()", function () {
        _this.query = _this.query.addFilter("other", _1.BoolShould(["foo"]));
        var query = _this.accessor.buildSharedQuery(_this.query);
        query = _this.accessor.buildOwnQuery(query);
        expect(query.query.aggs).toEqual(_1.FilterBucket("9999", _1.BoolMust([_1.BoolShould(["foo"])]), _1.RangeBucket("categories", "price", [
            {
                "key": "All"
            },
            {
                "key": "Cheap",
                "from": 1,
                "to": 11
            },
            {
                "key": "Affordable",
                "from": 11,
                "to": 21
            },
            {
                "key": "Pricey",
                "from": 21,
                "to": 101
            }
        ])));
    });
    describe("Nested usecase", function () {
        beforeEach(function () {
            _this.options = {
                field: "price",
                id: "price_id",
                title: "”Price",
                options: [
                    { title: "All" },
                    { title: "Cheap", from: 1, to: 11 },
                    { title: "Affordable", from: 11, to: 21 },
                    { title: "Pricey", from: 21, to: 101 }
                ],
                fieldOptions: {
                    type: "nested",
                    options: {
                        path: "nestedPrice"
                    }
                }
            };
            _this.accessor = new _1.NumericOptionsAccessor("categories", _this.options);
            _this.accessor.uuid = "9999";
        });
        it("buildSharedQuery()", function () {
            _this.accessor.state = new _1.ArrayState(["11_21", "21_101"]);
            var query = _this.accessor.buildSharedQuery(_this.query);
            var expected = _1.BoolMust([
                _1.BoolShould([
                    _1.NestedQuery("nestedPrice", _1.RangeQuery("price", { gte: 11, lt: 21 })),
                    _1.NestedQuery("nestedPrice", _1.RangeQuery("price", { gte: 21, lt: 101 }))
                ])
            ]);
            expect(query.query.filter).toEqual(expected);
        });
        it("buildOwnQuery()", function () {
            _this.query = _this.query.addFilter("other", _1.BoolShould(["foo"]));
            var query = _this.accessor.buildSharedQuery(_this.query);
            query = _this.accessor.buildOwnQuery(query);
            expect(query.query.aggs).toEqual(_1.FilterBucket("9999", _1.BoolMust([_1.BoolShould(["foo"])]), _1.NestedBucket("inner", "nestedPrice", _1.RangeBucket("categories", "price", [
                {
                    "key": "All"
                },
                {
                    "key": "Cheap",
                    "from": 1,
                    "to": 11
                },
                {
                    "key": "Affordable",
                    "from": 11,
                    "to": 21
                },
                {
                    "key": "Pricey",
                    "from": 21,
                    "to": 101
                }
            ]))));
        });
        it("getBuckets()", function () {
            _this.accessor.results = {
                aggregations: {
                    "9999": {
                        inner: {
                            categories: {
                                buckets: [
                                    { key: 1, doc_count: 1 },
                                    { key: 2, doc_count: 2 },
                                    { key: 3, doc_count: 3 },
                                    { key: 4, doc_count: 0 }
                                ]
                            }
                        }
                    }
                }
            };
            expect(_.map(_this.accessor.getBuckets(), "key"))
                .toEqual([1, 2, 3]);
        });
    });
});
//# sourceMappingURL=NumericalOptionsAccessorSpec.js.map