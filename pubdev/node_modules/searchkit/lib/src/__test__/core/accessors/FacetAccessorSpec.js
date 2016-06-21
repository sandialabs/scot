"use strict";
var _this = this;
var _1 = require("../../../");
describe("FacetAccessor", function () {
    beforeEach(function () {
        _1.Utils.guidCounter = 0;
        _this.options = {
            operator: "OR",
            title: "Genres",
            id: "GenreId",
            size: 20,
            orderKey: "_term",
            orderDirection: "asc",
            translations: {
                "facets.view_more": "View more genres"
            }
        };
        _this.accessor = new _1.FacetAccessor("genre", _this.options);
    });
    it("constructor()", function () {
        expect(_this.accessor.options).toBe(_this.options);
        expect(_this.accessor.urlKey).toBe("GenreId");
        expect(_this.accessor.key).toBe("genre");
    });
    it("getBuckets()", function () {
        expect(_this.accessor.getBuckets()).toEqual([]);
        _this.accessor.results = {
            aggregations: {
                genre1: {
                    genre: { buckets: [
                            { key: "a", doc_count: 1 },
                            { key: "b", doc_count: 2 }
                        ] }
                }
            }
        };
        expect(_this.accessor.getBuckets())
            .toEqual([
            { key: "a", doc_count: 1 },
            { key: "b", doc_count: 2 }
        ]);
        // test raw buckets referential equality
        expect(_this.accessor.getBuckets())
            .toBe(_this.accessor.getRawBuckets());
        _this.accessor.state = _this.accessor.state.setValue(["a", "c"]);
        expect(_this.accessor.getBuckets())
            .toEqual([
            { key: "c", missing: true, selected: true },
            { key: "a", doc_count: 1, selected: true },
            { key: "b", doc_count: 2 }
        ]);
    });
    it("getCount()", function () {
        expect(_this.accessor.getCount()).toEqual(0);
        _this.accessor.results = {
            aggregations: {
                genre1: {
                    genre_count: {
                        value: 99
                    }
                }
            }
        };
        expect(_this.accessor.getCount())
            .toEqual(99);
    });
    it("getDocCount()", function () {
        expect(_this.accessor.getDocCount()).toEqual(0);
        _this.accessor.results = {
            aggregations: {
                genre1: {
                    genre_count: {
                        value: 99
                    },
                    doc_count: 50
                }
            }
        };
        expect(_this.accessor.getDocCount())
            .toEqual(50);
    });
    it("isOrOperator()", function () {
        expect(_this.accessor.isOrOperator())
            .toBe(true);
        _this.options.operator = "AND";
        expect(_this.accessor.isOrOperator())
            .toBe(false);
    });
    it("getBoolBuilder()", function () {
        expect(_this.accessor.getBoolBuilder())
            .toBe(_1.BoolShould);
        _this.options.operator = "AND";
        expect(_this.accessor.getBoolBuilder())
            .toBe(_1.BoolMust);
    });
    describe("view more options", function () {
        it("setViewMoreOption", function () {
            _this.accessor.setViewMoreOption({ size: 30 });
            expect(_this.accessor.size).toBe(30);
        });
        it("getMoreSizeOption - view more", function () {
            _this.accessor.getCount = function () {
                return 100;
            };
            expect(_this.accessor.getMoreSizeOption()).toEqual({ size: 70, label: "View more genres" });
        });
        it("getMoreSizeOption - view all", function () {
            _this.accessor.getCount = function () {
                return 30;
            };
            expect(_this.accessor.getMoreSizeOption()).toEqual({ size: 30, label: "View all" });
        });
        it("getMoreSizeOption - view all page size equals total", function () {
            _this.accessor.getCount = function () {
                return 70;
            };
            expect(_this.accessor.getMoreSizeOption()).toEqual({ size: 70, label: "View all" });
        });
        it("getMoreSizeOption - view less", function () {
            _this.accessor.getCount = function () {
                return 30;
            };
            _this.accessor.size = 30;
            expect(_this.accessor.getMoreSizeOption()).toEqual({ size: 20, label: "View less" });
        });
        it("getMoreSizeOption - no option", function () {
            _this.accessor.getCount = function () {
                return 15;
            };
            _this.accessor.size = 20;
            expect(_this.accessor.getMoreSizeOption()).toEqual(null);
        });
    });
    describe("buildSharedQuery", function () {
        beforeEach(function () {
            _this.accessor.translate = function (key) {
                return {
                    "1": "Games", "2": "Action",
                    "3": "Comedy", "4": "Horror"
                }[key];
            };
            _this.toPlainObject = function (ob) {
                return JSON.parse(JSON.stringify(ob));
            };
            _this.accessor.state = new _1.ArrayState([
                "1", "2"
            ]);
            _this.query = new _1.ImmutableQuery();
        });
        it("filter test", function () {
            _this.query = _this.accessor.buildSharedQuery(_this.query);
            var filters = _this.query.getFilters().bool.should;
            expect(_this.toPlainObject(filters)).toEqual([
                {
                    "term": {
                        "genre": "1"
                    }
                },
                {
                    "term": {
                        "genre": "2"
                    }
                }
            ]);
            var selectedFilters = _this.query.getSelectedFilters();
            expect(selectedFilters.length).toEqual(2);
            //
            expect(_this.accessor.state.getValue()).toEqual(["1", "2"]);
            selectedFilters[0].remove();
            expect(_this.accessor.state.getValue()).toEqual(["2"]);
            selectedFilters[1].remove();
            expect(_this.accessor.state.getValue()).toEqual([]);
        });
        it("AND filter", function () {
            _this.options.operator = "AND";
            _this.query = _this.accessor.buildSharedQuery(_this.query);
            expect(_this.query.getFilters().bool.should).toBeFalsy();
            expect(_this.query.getFilters().bool.must).toBeTruthy();
        });
        it("Empty state", function () {
            _this.accessor.state = new _1.ArrayState([]);
            var query = _this.accessor.buildSharedQuery(_this.query);
            expect(query).toBe(_this.query);
        });
    });
    describe("buildOwnQuery", function () {
        beforeEach(function () {
            _this.accessor.state = new _1.ArrayState([
                "1", "2"
            ]);
            _this.query = new _1.ImmutableQuery()
                .addFilter("rating_uuid", _1.BoolShould(["PG"]));
            _this.query = _this.accessor.buildSharedQuery(_this.query);
        });
        it("build own query - or", function () {
            var query = _this.accessor.buildOwnQuery(_this.query);
            expect(query.query.aggs).toEqual(_1.FilterBucket("genre1", _1.BoolMust([
                _1.BoolShould(["PG"])
            ]), _1.TermsBucket("genre", "genre", { size: 20, order: { _term: "asc" } }), _1.CardinalityMetric("genre_count", "genre")));
        });
        it("build own query - and", function () {
            _this.options.operator = "AND";
            var query = _this.accessor.buildOwnQuery(_this.query);
            expect(query.query.aggs).toEqual(_1.FilterBucket("genre1", _1.BoolMust([
                _1.BoolShould(["PG"]),
                _1.BoolShould([
                    _1.TermQuery("genre", "1"),
                    _1.TermQuery("genre", "2")
                ])
            ]), _1.TermsBucket("genre", "genre", { size: 20, order: { _term: "asc" } }), _1.CardinalityMetric("genre_count", "genre")));
        });
        it("build own query - include/exclude/min_doc_count", function () {
            _this.options.operator = "AND";
            _this.options.include = ["one", "two"];
            _this.options.exclude = ["three"];
            _this.options.min_doc_count = 0;
            var query = _this.accessor.buildOwnQuery(_this.query);
            expect(query.query.aggs).toEqual(_1.FilterBucket("genre1", _1.BoolMust([
                _1.BoolShould(["PG"]),
                _1.BoolShould([
                    _1.TermQuery("genre", "1"),
                    _1.TermQuery("genre", "2")
                ])
            ]), _1.TermsBucket("genre", "genre", {
                size: 20,
                include: ["one", "two"],
                exclude: ["three"],
                min_doc_count: 0,
                order: { _term: "asc" }
            }), _1.CardinalityMetric("genre_count", "genre")));
        });
        describe("NestedFieldContext", function () {
            beforeEach(function () {
                _this.options = {
                    operator: "OR",
                    title: "Genres",
                    id: "GenreId",
                    size: 20,
                    fieldOptions: {
                        type: "nested",
                        options: { path: "tags" }
                    }
                };
                _this.accessor = new _1.FacetAccessor("genre", _this.options);
                _this.accessor.results = {
                    aggregations: {
                        genre2: {
                            inner: {
                                genre: { buckets: [1, 2] }
                            }
                        }
                    }
                };
            });
            it("constructor", function () {
                expect(_this.accessor.fieldContext)
                    .toEqual(jasmine.any(_1.NestedFieldContext));
            });
            it("buildSharedQuery", function () {
                _this.accessor.state = new _1.ArrayState([
                    "1", "2"
                ]);
                _this.query = new _1.ImmutableQuery()
                    .addFilter("rating_uuid", _1.BoolShould(["PG"]));
                _this.query = _this.accessor.buildSharedQuery(_this.query);
                expect(_this.query.index.filtersMap["genre2"]).toEqual(_1.BoolShould([
                    _1.NestedQuery("tags", _1.TermQuery("genre", "1")),
                    _1.NestedQuery("tags", _1.TermQuery("genre", "2"))
                ]));
            });
            it("buildOwnQuery", function () {
                _this.accessor.state = new _1.ArrayState([
                    "1", "2"
                ]);
                _this.query = new _1.ImmutableQuery()
                    .addFilter("rating_uuid", _1.BoolShould(["PG"]));
                _this.query = _this.accessor.buildOwnQuery(_this.query);
                expect(_this.query.query.aggs).toEqual(_1.FilterBucket("genre2", _1.BoolShould(["PG"]), _1.NestedBucket("inner", "tags", _1.TermsBucket("genre", "genre", { size: 20 }), _1.CardinalityMetric("genre_count", "genre"))));
            });
            it("getBuckets()", function () {
                expect(_this.accessor.getBuckets()).toEqual([1, 2]);
            });
        });
    });
});
//# sourceMappingURL=FacetAccessorSpec.js.map