"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var _a = require("../../../../../src"), SearchkitManager = _a.SearchkitManager, SearchkitProvider = _a.SearchkitProvider, SearchBox = _a.SearchBox, Hits = _a.Hits, RefinementListFilter = _a.RefinementListFilter, Pagination = _a.Pagination, HierarchicalMenuFilter = _a.HierarchicalMenuFilter, HitsStats = _a.HitsStats, SortingSelector = _a.SortingSelector, NoHits = _a.NoHits, SelectedFilters = _a.SelectedFilters, ResetFilters = _a.ResetFilters, RangeFilter = _a.RangeFilter, NumericRefinementListFilter = _a.NumericRefinementListFilter, ViewSwitcherHits = _a.ViewSwitcherHits, ViewSwitcherToggle = _a.ViewSwitcherToggle, DynamicRangeFilter = _a.DynamicRangeFilter, InputFilter = _a.InputFilter, GroupedSelectedFilters = _a.GroupedSelectedFilters;
var _b = require("../../../../../src"), Layout = _b.Layout, TopBar = _b.TopBar, LayoutBody = _b.LayoutBody, LayoutResults = _b.LayoutResults, ActionBar = _b.ActionBar, ActionBarRow = _b.ActionBarRow, SideBar = _b.SideBar;
var host = "http://demo.searchkit.co/api/movies";
var ReactDOM = require("react-dom");
var React = require("react");
var searchkit = new SearchkitManager(host);
var _ = require("lodash");
require("./styles.scss");
var MovieHitsGridItem = function (props) {
    var bemBlocks = props.bemBlocks, result = props.result;
    var url = "http://www.imdb.com/title/" + result._source.imdbId;
    var source = _.extend({}, result._source, result.highlight);
    return (React.createElement("div", {className: bemBlocks.item().mix(bemBlocks.container("item")), "data-qa": "hit"}, React.createElement("a", {href: url, target: "_blank"}, React.createElement("img", {"data-qa": "poster", className: bemBlocks.item("poster"), src: result._source.poster, width: "170", height: "240"}), React.createElement("div", {"data-qa": "title", className: bemBlocks.item("title"), dangerouslySetInnerHTML: { __html: source.title }}))));
};
var MovieHitsListItem = function (props) {
    var bemBlocks = props.bemBlocks, result = props.result;
    var url = "http://www.imdb.com/title/" + result._source.imdbId;
    var source = _.extend({}, result._source, result.highlight);
    return (React.createElement("div", {className: bemBlocks.item().mix(bemBlocks.container("item")), "data-qa": "hit"}, React.createElement("div", {className: bemBlocks.item("poster")}, React.createElement("img", {"data-qa": "poster", src: result._source.poster})), React.createElement("div", {className: bemBlocks.item("details")}, React.createElement("a", {href: url, target: "_blank"}, React.createElement("h2", {className: bemBlocks.item("title"), dangerouslySetInnerHTML: { __html: source.title }})), React.createElement("h3", {className: bemBlocks.item("subtitle")}, "Released in ", source.year, ", rated ", source.imdbRating, "/10"), React.createElement("div", {className: bemBlocks.item("text"), dangerouslySetInnerHTML: { __html: source.plot }}))));
};
var App = (function (_super) {
    __extends(App, _super);
    function App() {
        _super.apply(this, arguments);
    }
    App.prototype.render = function () {
        return (React.createElement(SearchkitProvider, {searchkit: searchkit}, React.createElement(Layout, null, React.createElement(TopBar, null, React.createElement("div", {className: "my-logo"}, "Searchkit Acme co"), React.createElement(SearchBox, {autofocus: true, searchOnChange: true, prefixQueryFields: ["actors^1", "type^2", "languages", "title^10"]})), React.createElement(LayoutBody, null, React.createElement(SideBar, null, React.createElement(HierarchicalMenuFilter, {fields: ["type.raw", "genres.raw"], title: "Categories", id: "categories"}), React.createElement(DynamicRangeFilter, {field: "metaScore", id: "metascore", title: "Metascore"}), React.createElement(RangeFilter, {min: 0, max: 10, field: "imdbRating", id: "imdbRating", title: "IMDB Rating", showHistogram: true}), React.createElement(InputFilter, {id: "writers", searchThrottleTime: 500, title: "Writers", placeholder: "Search writers", searchOnChange: true, queryFields: ["writers"]}), React.createElement(RefinementListFilter, {id: "actors", title: "Actors", field: "actors.raw", size: 10}), React.createElement(RefinementListFilter, {translations: { "facets.view_more": "View more writers" }, id: "writers", title: "Writers", field: "writers.raw", operator: "OR", size: 10}), React.createElement(RefinementListFilter, {id: "countries", title: "Countries", field: "countries.raw", operator: "OR", size: 10}), React.createElement(NumericRefinementListFilter, {id: "runtimeMinutes", title: "Length", field: "runtimeMinutes", options: [
            { title: "All" },
            { title: "up to 20", from: 0, to: 20 },
            { title: "21 to 60", from: 21, to: 60 },
            { title: "60 or more", from: 61, to: 1000 }
        ]})), React.createElement(LayoutResults, null, React.createElement(ActionBar, null, React.createElement(ActionBarRow, null, React.createElement(HitsStats, {translations: {
            "hitstats.results_found": "{hitCount} results found"
        }}), React.createElement(ViewSwitcherToggle, null), React.createElement(SortingSelector, {options: [
            { label: "Relevance", field: "_score", order: "desc" },
            { label: "Latest Releases", field: "released", order: "desc" },
            { label: "Earliest Releases", field: "released", order: "asc" }
        ]})), React.createElement(ActionBarRow, null, React.createElement(SelectedFilters, null), React.createElement(GroupedSelectedFilters, null), React.createElement(ResetFilters, null))), React.createElement(ViewSwitcherHits, {hitsPerPage: 12, highlightFields: ["title", "plot"], sourceFilter: ["plot", "title", "poster", "imdbId", "imdbRating", "year"], hitComponents: [
            { key: "grid", title: "Grid", itemComponent: MovieHitsGridItem, defaultOption: true },
            { key: "list", title: "List", itemComponent: MovieHitsListItem }
        ], scrollTo: "body"}), React.createElement(NoHits, {suggestionsField: "title"}), React.createElement(Pagination, {showNumbers: true}))))));
    };
    return App;
}(React.Component));
ReactDOM.render(React.createElement(App, null), document.getElementById("root"));
//# sourceMappingURL=index.js.map