"use strict";
var query_1 = require("./query");
var accessors_1 = require("./accessors");
var AccessorManager_1 = require("./AccessorManager");
var history_1 = require("./history");
var transport_1 = require("./transport");
var SearchRequest_1 = require("./SearchRequest");
var support_1 = require("./support");
var SearchkitVersion_1 = require("./SearchkitVersion");
var defaults = require("lodash/defaults");
var constant = require("lodash/constant");
var identity = require("lodash/identity");
var map = require("lodash/map");
var isEqual = require("lodash/isEqual");
var get = require("lodash/get");
var qs = require("qs");
require('es6-promise').polyfill();
var after = require("lodash/after");
var SearchkitManager = (function () {
    function SearchkitManager(host, options) {
        var _this = this;
        if (options === void 0) { options = {}; }
        this.VERSION = SearchkitVersion_1.VERSION;
        this.options = defaults(options, {
            useHistory: true,
            httpHeaders: {},
            searchOnLoad: true
        });
        this.host = host;
        this.transport = this.options.transport || new transport_1.AxiosESTransport(host, {
            headers: this.options.httpHeaders,
            basicAuth: this.options.basicAuth,
            searchUrlPath: this.options.searchUrlPath
        });
        this.accessors = new AccessorManager_1.AccessorManager();
        this.registrationCompleted = new Promise(function (resolve) {
            _this.completeRegistration = resolve;
        });
        this.translateFunction = constant(undefined);
        this.queryProcessor = identity;
        // this.primarySearcher = this.createSearcher()
        this.query = new query_1.ImmutableQuery();
        this.emitter = new support_1.EventEmitter();
        this.resultsEmitter = new support_1.EventEmitter();
    }
    SearchkitManager.mock = function () {
        var searchkit = new SearchkitManager("/", {
            useHistory: false,
            transport: new transport_1.MockESTransport()
        });
        searchkit.setupListeners();
        return searchkit;
    };
    SearchkitManager.prototype.setupListeners = function () {
        this.initialLoading = true;
        if (this.options.useHistory) {
            this.unlistenHistory();
            this.history = history_1.createHistory();
            this.listenToHistory();
        }
        else {
            this.runInitialSearch();
        }
    };
    SearchkitManager.prototype.addAccessor = function (accessor) {
        accessor.setSearchkitManager(this);
        return this.accessors.add(accessor);
    };
    SearchkitManager.prototype.removeAccessor = function (accessor) {
        this.accessors.remove(accessor);
    };
    SearchkitManager.prototype.addDefaultQuery = function (fn) {
        return this.addAccessor(new accessors_1.AnonymousAccessor(fn));
    };
    SearchkitManager.prototype.setQueryProcessor = function (fn) {
        this.queryProcessor = fn;
    };
    SearchkitManager.prototype.translate = function (key) {
        return this.translateFunction(key);
    };
    SearchkitManager.prototype.buildQuery = function () {
        return this.accessors.buildQuery();
    };
    SearchkitManager.prototype.resetState = function () {
        this.accessors.resetState();
    };
    SearchkitManager.prototype.addResultsListener = function (fn) {
        return this.resultsEmitter.addListener(fn);
    };
    SearchkitManager.prototype.unlistenHistory = function () {
        if (this.options.useHistory && this._unlistenHistory) {
            this._unlistenHistory();
        }
    };
    SearchkitManager.prototype.listenToHistory = function () {
        var _this = this;
        var callsBeforeListen = (this.options.searchOnLoad) ? 1 : 2;
        this._unlistenHistory = this.history.listen(after(callsBeforeListen, function (location) {
            //action is POP when the browser modified
            if (location.action === "POP") {
                _this.registrationCompleted.then(function () {
                    _this.searchFromUrlQuery(location.query);
                }).catch(function (e) {
                    console.error(e.stack);
                });
            }
        }));
    };
    SearchkitManager.prototype.runInitialSearch = function () {
        var _this = this;
        if (this.options.searchOnLoad) {
            this.registrationCompleted.then(function () {
                _this._search();
            });
        }
    };
    SearchkitManager.prototype.searchFromUrlQuery = function (query) {
        this.accessors.setState(query);
        this._search();
    };
    SearchkitManager.prototype.performSearch = function (replaceState, notifyState) {
        if (replaceState === void 0) { replaceState = false; }
        if (notifyState === void 0) { notifyState = true; }
        if (notifyState && !isEqual(this.accessors.getState(), this.state)) {
            this.accessors.notifyStateChange(this.state);
        }
        this._search();
        if (this.options.useHistory) {
            var historyMethod = (replaceState) ?
                this.history.replace : this.history.push;
            historyMethod({ pathname: window.location.pathname, query: this.state });
        }
    };
    SearchkitManager.prototype.buildSearchUrl = function (extraParams) {
        if (extraParams === void 0) { extraParams = {}; }
        var params = defaults(extraParams, this.state || this.accessors.getState());
        var queryString = qs.stringify(params, { encode: true });
        return window.location.pathname + '?' + queryString;
    };
    SearchkitManager.prototype.reloadSearch = function () {
        delete this.query;
        this.performSearch();
    };
    SearchkitManager.prototype.search = function (replaceState) {
        if (replaceState === void 0) { replaceState = false; }
        this.performSearch(replaceState);
    };
    SearchkitManager.prototype._search = function () {
        this.state = this.accessors.getState();
        var query = this.buildQuery();
        if (this.query && isEqual(query.getJSON(), this.query.getJSON())) {
            return;
        }
        this.query = query;
        this.loading = true;
        this.emitter.trigger();
        var queryObject = this.queryProcessor(this.query.getJSON());
        this.currentSearchRequest && this.currentSearchRequest.deactivate();
        this.currentSearchRequest = new SearchRequest_1.SearchRequest(this.transport, queryObject, this);
        this.currentSearchRequest.run();
    };
    SearchkitManager.prototype.setResults = function (results) {
        this.compareResults(this.results, results);
        this.results = results;
        this.error = null;
        this.accessors.setResults(results);
        this.onResponseChange();
        this.resultsEmitter.trigger(this.results);
    };
    SearchkitManager.prototype.compareResults = function (previousResults, results) {
        var ids = map(get(results, ["hits", "hits"], []), "_id").join(",");
        var previousIds = get(previousResults, ["hits", "ids"], "");
        if (results.hits) {
            results.hits.ids = ids;
            results.hits.hasChanged = !(ids && ids === previousIds);
        }
    };
    SearchkitManager.prototype.getHits = function () {
        return get(this.results, ["hits", "hits"], []);
    };
    SearchkitManager.prototype.getHitsCount = function () {
        return get(this.results, ["hits", "total"], 0);
    };
    SearchkitManager.prototype.getTime = function () {
        return get(this.results, "took", 0);
    };
    SearchkitManager.prototype.getSuggestions = function () {
        return get(this.results, ["suggest", "suggestions"], {});
    };
    SearchkitManager.prototype.getQueryAccessor = function () {
        return this.accessors.queryAccessor;
    };
    SearchkitManager.prototype.getAccessorsByType = function (type) {
        return this.accessors.getAccessorsByType(type);
    };
    SearchkitManager.prototype.getAccessorByType = function (type) {
        return this.accessors.getAccessorByType(type);
    };
    SearchkitManager.prototype.hasHits = function () {
        return this.getHitsCount() > 0;
    };
    SearchkitManager.prototype.hasHitsChanged = function () {
        return get(this.results, ["hits", "hasChanged"], true);
    };
    SearchkitManager.prototype.setError = function (error) {
        this.error = error;
        console.error(this.error);
        this.results = null;
        this.accessors.setResults(null);
        this.onResponseChange();
    };
    SearchkitManager.prototype.onResponseChange = function () {
        this.loading = false;
        this.initialLoading = false;
        this.emitter.trigger();
    };
    SearchkitManager.VERSION = SearchkitVersion_1.VERSION;
    return SearchkitManager;
}());
exports.SearchkitManager = SearchkitManager;
//# sourceMappingURL=SearchkitManager.js.map