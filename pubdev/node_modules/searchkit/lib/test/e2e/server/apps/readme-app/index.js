"use strict";
var _a = require("../../../../../src"), SearchkitManager = _a.SearchkitManager, SearchkitProvider = _a.SearchkitProvider, SearchBox = _a.SearchBox, Hits = _a.Hits, RefinementListFilter = _a.RefinementListFilter, Pagination = _a.Pagination, HierarchicalMenuFilter = _a.HierarchicalMenuFilter, HitsStats = _a.HitsStats, SortingSelector = _a.SortingSelector, NoHits = _a.NoHits, SelectedFilters = _a.SelectedFilters, ResetFilters = _a.ResetFilters, RangeFilter = _a.RangeFilter, NumericRefinementListFilter = _a.NumericRefinementListFilter, ViewSwitcherHits = _a.ViewSwitcherHits, ViewSwitcherToggle = _a.ViewSwitcherToggle;
var _ = require("lodash");
var _b = require("../../../../../src"), Layout = _b.Layout, TopBar = _b.TopBar, LayoutBody = _b.LayoutBody, LayoutResults = _b.LayoutResults, ActionBar = _b.ActionBar, ActionBarRow = _b.ActionBarRow, SideBar = _b.SideBar;
var ReactDOM = require("react-dom");
var React = require("react");
require("../../../../../theming/theme.scss");
var MovieHitsGridItem = function (props) {
    var bemBlocks = props.bemBlocks, result = props.result;
    var url = "http://www.imdb.com/title/" + result._source.imdbId;
    var source = _.extend({}, result._source, result.highlight);
    return (React.createElement("div", {className: bemBlocks.item().mix(bemBlocks.container("item")), "data-qa": "hit"}, React.createElement("a", {href: url, target: "_blank"}, React.createElement("img", {"data-qa": "poster", className: bemBlocks.item("poster"), src: result._source.poster, width: "170", height: "240"}), React.createElement("div", {"data-qa": "title", className: bemBlocks.item("title"), dangerouslySetInnerHTML: { __html: source.title }}))));
};
var searchkit = new SearchkitManager("http://demo.searchkit.co/api/movies/");
var App = function () { return (React.createElement(SearchkitProvider, {searchkit: searchkit}, React.createElement(Layout, null, React.createElement(TopBar, null, React.createElement(SearchBox, {autofocus: true, searchOnChange: true, prefixQueryFields: ["actors^1", "type^2", "languages", "title^10"]})), React.createElement(LayoutBody, null, React.createElement(SideBar, null, React.createElement(HierarchicalMenuFilter, {fields: ["type.raw", "genres.raw"], title: "Categories", id: "categories"}), React.createElement(RefinementListFilter, {id: "actors", title: "Actors", field: "actors.raw", operator: "AND", size: 10})), React.createElement(LayoutResults, null, React.createElement(ActionBar, null, React.createElement(ActionBarRow, null, React.createElement(HitsStats, null)), React.createElement(ActionBarRow, null, React.createElement(SelectedFilters, null), React.createElement(ResetFilters, null))), React.createElement(Hits, {mod: "sk-hits-grid", hitsPerPage: 10, itemComponent: MovieHitsGridItem, sourceFilter: ["title", "poster", "imdbId"]}), React.createElement(NoHits, null)))))); };
ReactDOM.render(React.createElement(App, null), document.getElementById('root'));
//# sourceMappingURL=index.js.map