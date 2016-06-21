"use strict";
var _this = this;
var _1 = require("../../../");
describe("ResetSearchAccessor", function () {
    beforeEach(function () {
        _this.searchkit = _1.SearchkitManager.mock();
        _this.accessor = new _1.ResetSearchAccessor();
        _this.searchkit.addAccessor(_this.accessor);
        _this.query = new _1.ImmutableQuery();
    });
    it("constructor()", function () {
        expect(_this.accessor.options).toEqual({
            query: true, filter: true, pagination: true
        });
        var accessor = new _1.ResetSearchAccessor({ query: true });
        expect(accessor.options).toEqual({
            query: true
        });
    });
    it("canReset()", function () {
        var options = { query: true, filter: true, pagination: true };
        _this.accessor.options = options;
        _this.searchkit.query = new _1.ImmutableQuery();
        expect(_this.accessor.canReset()).toBe(false);
        _this.searchkit.query = new _1.ImmutableQuery().setQueryString("foo");
        expect(_this.accessor.canReset()).toBe(true);
        options.query = false;
        expect(_this.accessor.canReset()).toBe(false);
        _this.searchkit.query = new _1.ImmutableQuery().addSelectedFilter({
            id: "foo", name: "fooname", value: "foovalue", remove: function () { }
        });
        expect(_this.accessor.canReset()).toBe(true);
        options.filter = false;
        expect(_this.accessor.canReset()).toBe(false);
        _this.searchkit.query = new _1.ImmutableQuery().setFrom(10);
        expect(_this.accessor.canReset()).toBe(true);
        options.pagination = false;
        expect(_this.accessor.canReset()).toBe(false);
    });
    it("performReset()", function () {
        var queryAccessor = _this.searchkit.getQueryAccessor();
        spyOn(queryAccessor, "resetState");
        var filterAccessor1 = new _1.FilterBasedAccessor("f1");
        spyOn(filterAccessor1, "resetState");
        var filterAccessor2 = new _1.FilterBasedAccessor("f2");
        spyOn(filterAccessor2, "resetState");
        var searchInputAccessor = new _1.QueryAccessor("s", { addToFilters: true });
        searchInputAccessor.state = searchInputAccessor.state.setValue("foo");
        var paginationAccessor = new _1.PaginationAccessor("p");
        spyOn(paginationAccessor, "resetState");
        _this.searchkit.addAccessor(filterAccessor1);
        _this.searchkit.addAccessor(filterAccessor2);
        _this.searchkit.addAccessor(searchInputAccessor);
        _this.searchkit.addAccessor(paginationAccessor);
        _this.searchkit.query = _this.searchkit.buildQuery();
        _this.accessor.options = { query: false, filter: false };
        _this.accessor.performReset();
        expect(queryAccessor.resetState).not.toHaveBeenCalled();
        expect(filterAccessor1.resetState).not.toHaveBeenCalled();
        expect(filterAccessor2.resetState).not.toHaveBeenCalled();
        expect(searchInputAccessor.state.getValue()).toBe("foo");
        _this.accessor.options = { query: true, filter: false };
        _this.accessor.performReset();
        expect(queryAccessor.resetState).toHaveBeenCalled();
        expect(filterAccessor1.resetState).not.toHaveBeenCalled();
        expect(filterAccessor2.resetState).not.toHaveBeenCalled();
        expect(searchInputAccessor.state.getValue()).toBe("foo");
        _this.accessor.options = { query: true, filter: true };
        _this.accessor.performReset();
        expect(filterAccessor1.resetState).toHaveBeenCalled();
        expect(filterAccessor2.resetState).toHaveBeenCalled();
        expect(paginationAccessor.resetState).not.toHaveBeenCalled();
        expect(searchInputAccessor.state.getValue()).toBe(null);
        _this.accessor.options = { query: true, filter: true, pagination: true };
        _this.accessor.performReset();
        expect(paginationAccessor.resetState).toHaveBeenCalled();
    });
});
//# sourceMappingURL=ResetSearchAccessorSpec.js.map