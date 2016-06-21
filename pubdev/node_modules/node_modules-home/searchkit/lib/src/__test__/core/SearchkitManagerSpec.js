"use strict";
var _this = this;
var _1 = require("../../");
var _ = require("lodash");
describe("SearchkitManager", function () {
    beforeEach(function () {
        _this.host = "http://localhost:9200";
        spyOn(_1.SearchkitManager.prototype, "runInitialSearch").and.callThrough();
        _this.searchkit = new _1.SearchkitManager(_this.host, {
            useHistory: false,
            httpHeaders: {
                "Content-Type": "application/json"
            },
            basicAuth: "key:val",
            searchUrlPath: "/search",
            searchOnLoad: false
        });
        _this.searchkit.setupListeners();
        _this.emitterSpy = jasmine.createSpy("emitter");
        _this.searchkit.emitter.addListener(_this.emitterSpy);
        _this.accessors = _this.searchkit.accessors;
        expect(_this.searchkit.transport.options.searchUrlPath)
            .toBe("/search");
        expect(_1.SearchkitManager.prototype.runInitialSearch)
            .toHaveBeenCalled();
    });
    it("constructor()", function () {
        var semverRegex = /^\d+\.\d+\.\d+-?\w*$/;
        expect(_this.searchkit.VERSION).toMatch(semverRegex);
        expect(_1.SearchkitManager.VERSION).toMatch(semverRegex);
        expect(_this.searchkit.host).toBe(_this.host);
        expect(_this.searchkit.accessors)
            .toEqual(jasmine.any(_1.AccessorManager));
        expect(_this.searchkit.registrationCompleted).toEqual(jasmine.any(Promise));
        expect(_this.searchkit.translateFunction)
            .toEqual(jasmine.any(Function));
        expect(_this.searchkit.transport)
            .toEqual(jasmine.any(_1.AxiosESTransport));
        expect(_this.searchkit.transport.options.headers).toEqual(jasmine.objectContaining({
            "Content-Type": "application/json",
            "Authorization": jasmine.any(String)
        }));
        expect(_this.searchkit.query).toEqual(new _1.ImmutableQuery());
        expect(_this.searchkit.emitter).toEqual(jasmine.any(_1.EventEmitter));
        expect(_this.searchkit.options.searchOnLoad).toBe(false);
        expect(_this.searchkit.initialLoading).toBe(true);
        //check queryProcessor is an identity function
        expect(_this.searchkit.queryProcessor("query")).toBe("query");
    });
    it("SearchkitManager.mock()", function () {
        var searchkit = _1.SearchkitManager.mock();
        expect(searchkit.host).toBe("/");
        expect(searchkit.options.useHistory).toBe(false);
        expect(searchkit.options.transport).toEqual(jasmine.any(_1.MockESTransport));
    });
    it("addAccessor(), removeAddAccessor()", function () {
        var accessor = new _1.PageSizeAccessor(10);
        _this.searchkit.addAccessor(accessor);
        expect(_this.searchkit.accessors.accessors).toEqual([
            accessor
        ]);
        _this.searchkit.removeAccessor(accessor);
        expect(_this.searchkit.accessors.accessors)
            .toEqual([]);
    });
    it("addDefaultQuery()", function () {
        var queryFn = function (query) {
            return query.setSize(11);
        };
        _this.searchkit.addDefaultQuery(queryFn);
        var anonymousAccessor = _this.searchkit.accessors.accessors[0];
        expect(_this.searchkit.buildQuery().getSize()).toBe(11);
    });
    it("translate()", function () {
        spyOn(_this.searchkit, "translateFunction")
            .and.callThrough();
        expect(_this.searchkit.translate("foo")).toBe(undefined);
        expect(_this.searchkit.translateFunction)
            .toHaveBeenCalledWith("foo");
    });
    it("buildQuery()", function () {
        var defaultQueryFn = function (query) {
            return query.setFrom(20);
        };
        _this.searchkit.addDefaultQuery(defaultQueryFn);
        _this.searchkit.addAccessor(new _1.PageSizeAccessor(10));
        var query = _this.searchkit.buildQuery();
        expect(query.getSize()).toBe(10);
        expect(query.getFrom()).toBe(20);
    });
    it("resetState()", function () {
        spyOn(_this.accessors, "resetState");
        _this.searchkit.resetState();
        expect(_this.accessors.resetState)
            .toHaveBeenCalled();
    });
    it("listenToHistory()", function (done) {
        var history = _1.createHistory();
        history.push({ pathname: window.location.pathname, query: {
                q: "foo"
            } });
        _1.SearchkitManager.prototype.unlistenHistory = jasmine.createSpy("unlisten");
        var searchkit = new _1.SearchkitManager("/", {
            useHistory: true
        });
        searchkit.setupListeners();
        expect(_1.SearchkitManager.prototype.unlistenHistory)
            .toHaveBeenCalled();
        spyOn(searchkit.accessors, "setState");
        spyOn(searchkit, "_search");
        searchkit.completeRegistration();
        setTimeout(function () {
            expect(searchkit._search).toHaveBeenCalled();
            expect(searchkit.accessors.setState)
                .toHaveBeenCalledWith({ q: "foo" });
            searchkit.unlistenHistory();
            done();
        }, 0);
    });
    it("listenToHistory() - searchOnLoad false", function (done) {
        var history = _1.createHistory();
        history.push({ pathname: window.location.pathname, query: {
                q: "foo-previous"
            } });
        var searchkit = new _1.SearchkitManager("/", {
            useHistory: true,
            searchOnLoad: false
        });
        searchkit.setupListeners();
        spyOn(searchkit.accessors, "setState");
        spyOn(searchkit, "_search");
        searchkit.completeRegistration();
        setTimeout(function () {
            expect(searchkit._search).not.toHaveBeenCalled();
            history.goBack();
            setTimeout(function () {
                expect(searchkit._search).toHaveBeenCalled();
                searchkit.unlistenHistory();
                done();
            }, 0);
        }, 0);
    });
    it("listenToHistory() - handle error", function (done) {
        var history = _1.createHistory();
        history.push({ pathname: window.location.pathname, query: {
                q: "foo"
            } });
        var searchkit = new _1.SearchkitManager("/", {
            useHistory: true
        });
        searchkit.setupListeners();
        searchkit.searchFromUrlQuery = function (query) {
            throw new Error("oh no");
        };
        spyOn(console, "error");
        searchkit.completeRegistration();
        setTimeout(function () {
            expect(console.error["calls"].argsFor(0)[0])
                .toContain("searchFromUrlQuery");
            searchkit.unlistenHistory();
            done();
        }, 0);
    });
    it("performSearch()", function () {
        var searchkit = new _1.SearchkitManager("/", {
            useHistory: true
        });
        searchkit.setupListeners();
        searchkit.state = {
            q: "foo"
        };
        spyOn(searchkit.accessors, "notifyStateChange");
        spyOn(searchkit, "_search").and.returnValue(true);
        spyOn(searchkit.history, "push");
        searchkit.performSearch();
        expect(searchkit.history.push).toHaveBeenCalledWith({ pathname: "/context.html", query: { q: "foo" } });
        expect(searchkit.accessors.notifyStateChange)
            .toHaveBeenCalledWith(searchkit.state);
        searchkit.unlistenHistory();
    });
    it("run initial search", function (done) {
        var searchkit = new _1.SearchkitManager(_this.host, {
            useHistory: false, searchOnLoad: false
        });
        spyOn(searchkit, "_search");
        expect(_1.SearchkitManager.prototype.runInitialSearch)
            .toHaveBeenCalled();
        searchkit.completeRegistration();
        setTimeout(function () {
            expect(searchkit._search).not.toHaveBeenCalled();
            searchkit.options.searchOnLoad = true;
            searchkit.runInitialSearch();
            setTimeout(function () {
                expect(searchkit._search).toHaveBeenCalled();
                done();
            });
        });
    });
    it("performSearch() - same state + replaceState", function () {
        var searchkit = new _1.SearchkitManager("/", {
            useHistory: true
        });
        searchkit.setupListeners();
        searchkit.state = {
            q: "foo"
        };
        searchkit.accessors.getState = function () {
            return { q: "foo" };
        };
        spyOn(searchkit.accessors, "notifyStateChange");
        spyOn(searchkit, "_search").and.returnValue(true);
        spyOn(searchkit.history, "replace");
        searchkit.performSearch(true);
        expect(searchkit.history.replace)
            .toHaveBeenCalled();
        expect(searchkit.accessors.notifyStateChange)
            .not.toHaveBeenCalled();
        searchkit.unlistenHistory();
        searchkit.state = { q: "bar" };
        searchkit.performSearch(true, false);
        expect(searchkit.accessors.notifyStateChange)
            .not.toHaveBeenCalled();
        searchkit.performSearch(true, true);
        expect(searchkit.accessors.notifyStateChange)
            .toHaveBeenCalled();
    });
    it("search()", function () {
        spyOn(_this.searchkit, "performSearch");
        _this.searchkit.search();
        expect(_this.searchkit.performSearch)
            .toHaveBeenCalled();
    });
    it("_search()", function () {
        spyOn(_1.SearchRequest.prototype, "run");
        _this.accessor = new _1.PageSizeAccessor(10);
        _this.searchkit.setQueryProcessor(function (query) {
            query.source = true;
            return query;
        });
        var initialSearchRequest = _this.searchkit.currentSearchRequest = new _1.SearchRequest(_this.host, null, _this.searchkit);
        _this.searchkit.addAccessor(_this.accessor);
        _this.searchkit._search();
        expect(initialSearchRequest.active).toBe(false);
        expect(_this.searchkit.currentSearchRequest.transport.host)
            .toBe(_this.host);
        expect(_this.searchkit.currentSearchRequest.query).toEqual({
            size: 10, source: true
        });
        expect(_this.searchkit.currentSearchRequest.run)
            .toHaveBeenCalled();
        expect(_this.searchkit.loading).toBe(true);
    });
    it("_search() should not search with same query", function () {
        spyOn(_1.SearchRequest.prototype, "run");
        _this.searchkit.query = new _1.ImmutableQuery().setSize(20).setSort([{ "created": "desc" }]);
        _this.searchkit.buildQuery = function () { return new _1.ImmutableQuery().setSize(20).setSort([{ "created": "desc" }]); };
        _this.searchkit._search();
        expect(_1.SearchRequest.prototype.run)
            .not.toHaveBeenCalled();
        _this.searchkit.query = new _1.ImmutableQuery().setSize(21);
        _this.searchkit._search();
        expect(_1.SearchRequest.prototype.run)
            .toHaveBeenCalled();
    });
    it("reloadSearch()", function () {
        spyOn(_1.SearchRequest.prototype, "run");
        _this.searchkit.query = new _1.ImmutableQuery().setSize(20).setSort([{ "created": "desc" }]);
        _this.searchkit.buildQuery = function () { return new _1.ImmutableQuery().setSize(20).setSort([{ "created": "desc" }]); };
        _this.searchkit._search();
        expect(_1.SearchRequest.prototype.run)
            .not.toHaveBeenCalled();
        _this.searchkit.reloadSearch();
        expect(_1.SearchRequest.prototype.run)
            .toHaveBeenCalled();
    });
    it("setResults()", function () {
        spyOn(_this.accessors, "setResults");
        spyOn(_this.searchkit, "onResponseChange");
        expect(_this.searchkit.results).toBe(undefined);
        var resultsSpy = jasmine.createSpy("results");
        var removalFn = _this.searchkit.addResultsListener(resultsSpy);
        expect(removalFn).toEqual(jasmine.any(Function));
        _this.searchkit.setResults("foo");
        expect(_this.searchkit.results).toBe("foo");
        expect(_this.accessors.setResults)
            .toHaveBeenCalledWith("foo");
        expect(_this.searchkit.onResponseChange)
            .toHaveBeenCalled();
        expect(resultsSpy).toHaveBeenCalledWith("foo");
    });
    it("setResults() - error", function () {
        spyOn(_this.searchkit, "onResponseChange");
        spyOn(_this.accessors, "setResults");
        spyOn(console, "error");
        expect(_this.searchkit.results).toBe(undefined);
        var error = new Error("oh no");
        _this.searchkit.setError(error);
        expect(_this.searchkit.error).toBe(error);
        expect(console.error).toHaveBeenCalledWith(error);
        expect(_this.searchkit.results).toBe(null);
        expect(_this.accessors.setResults)
            .toHaveBeenCalledWith(null);
        expect(_this.searchkit.onResponseChange)
            .toHaveBeenCalled();
    });
    it("setResults() - change detection", function () {
        spyOn(_this.accessors, "setResults");
        spyOn(_this.searchkit, "onResponseChange");
        var results = {
            hits: {
                total: 2,
                hits: [
                    { _id: 1, _source: { title: "Doc1" } },
                    { _id: 2, _source: { title: "Doc2" } }
                ]
            }
        };
        _this.searchkit.setResults(_.cloneDeep(results));
        expect(_this.searchkit.results.hits.ids).toBe("1,2");
        expect(_this.searchkit.results.hits.hasChanged).toBe(true);
        expect(_this.searchkit.hasHitsChanged()).toBe(true);
        _this.searchkit.setResults(_.cloneDeep(results));
        expect(_this.searchkit.hasHitsChanged()).toBe(false);
        results.hits.hits.push({ _id: 3, _source: { title: "Doc3" } });
        _this.searchkit.setResults(_.cloneDeep(results));
        expect(_this.searchkit.results.hits.ids).toBe("1,2,3");
        expect(_this.searchkit.hasHitsChanged()).toBe(true);
    });
    it("getHits()", function () {
        expect(_this.searchkit.getHits()).toEqual([]);
        _this.searchkit.results = {
            hits: {
                hits: [1, 2, 3, 4]
            }
        };
        expect(_this.searchkit.getHits()).toEqual([1, 2, 3, 4]);
    });
    it("getHitsCount(), hasHits()", function () {
        expect(_this.searchkit.getHitsCount()).toEqual(0);
        expect(_this.searchkit.hasHits()).toBe(false);
        _this.searchkit.results = {
            hits: {
                total: 99
            },
            took: 1
        };
        expect(_this.searchkit.getHitsCount()).toBe(99);
        expect(_this.searchkit.getTime()).toBe(1);
        expect(_this.searchkit.hasHits()).toBe(true);
    });
    it("getQueryAccessor()", function () {
        var queryAccessor = new _1.QueryAccessor("q");
        _this.searchkit.addAccessor(queryAccessor);
        expect(_this.searchkit.getQueryAccessor()).toBe(queryAccessor);
    });
    it("getAccessorsByType(), getAccessorByType()", function () {
        var queryAccessor = new _1.QueryAccessor("q");
        _this.searchkit.addAccessor(queryAccessor);
        expect(_this.searchkit.getAccessorsByType(_1.QueryAccessor))
            .toEqual([queryAccessor]);
        expect(_this.searchkit.getAccessorByType(_1.QueryAccessor))
            .toEqual(queryAccessor);
    });
    it("onResponseChange()", function () {
        _this.searchkit.loading = true;
        _this.searchkit.initialLoading = true;
        _this.searchkit.onResponseChange();
        expect(_this.searchkit.loading).toBe(false);
        expect(_this.searchkit.initialLoading).toBe(false);
        expect(_this.emitterSpy).toHaveBeenCalled();
    });
});
//# sourceMappingURL=SearchkitManagerSpec.js.map