"use strict";
var _this = this;
var _1 = require("../../../");
function toPlainObject(ob) {
    return JSON.parse(JSON.stringify(ob));
}
describe("CheckboxFilterAccessor", function () {
    beforeEach(function () {
        _1.Utils.guidCounter = 0;
        _this.options = {
            id: "movie-filter",
            filter: _1.TermQuery("type", "movie"),
            title: "Type",
            label: "Movie"
        };
        _this.accessor = new _1.CheckboxFilterAccessor("movie-filter-key", _this.options);
    });
    it("constructor()", function () {
        expect(_this.accessor.options).toBe(_this.options);
        expect(_this.accessor.urlKey).toBe("movie-filter");
        expect(_this.accessor.key).toBe("movie-filter-key");
    });
    it("getDocCount()", function () {
        expect(_this.accessor.getDocCount()).toEqual(0);
        _this.accessor.results = {
            aggregations: {
                "movie-filter-key1": {
                    doc_count: 50
                }
            }
        };
        expect(_this.accessor.getDocCount())
            .toEqual(50);
    });
    it("buildSharedQuery", function () {
        var query = new _1.ImmutableQuery();
        query = _this.accessor.buildSharedQuery(query);
        var filters = query.getFilters();
        expect(toPlainObject(filters)).toEqual({});
        _this.accessor.state = _this.accessor.state.create(true);
        query = new _1.ImmutableQuery();
        query = _this.accessor.buildSharedQuery(query);
        filters = query.getFilters();
        expect(toPlainObject(filters)).toEqual({
            "term": {
                type: "movie"
            }
        });
        var selectedFilters = query.getSelectedFilters();
        expect(selectedFilters.length).toEqual(1);
        expect(_this.accessor.state.getValue()).toEqual(true);
        selectedFilters[0].remove();
        expect(_this.accessor.state.getValue()).toEqual(false);
    });
    it("buildOwnQuery", function () {
        var query = new _1.ImmutableQuery();
        query = _this.accessor.buildOwnQuery(query);
        expect(query.query.aggs).toEqual(_1.FilterBucket("movie-filter-key1", _1.TermQuery("type", "movie")));
    });
});
//# sourceMappingURL=CheckboxFilterAccessorSpec.js.map