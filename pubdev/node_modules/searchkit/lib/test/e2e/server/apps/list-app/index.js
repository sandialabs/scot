"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var _a = require("../../../../../src"), SearchkitManager = _a.SearchkitManager, SearchkitProvider = _a.SearchkitProvider, SearchBox = _a.SearchBox, Hits = _a.Hits, RefinementListFilter = _a.RefinementListFilter, Pagination = _a.Pagination, MenuFilter = _a.MenuFilter, HitsStats = _a.HitsStats, SortingSelector = _a.SortingSelector, NoHits = _a.NoHits, ItemList = _a.ItemList, CheckboxItemList = _a.CheckboxItemList, ItemHistogramList = _a.ItemHistogramList, Tabs = _a.Tabs, TagCloud = _a.TagCloud, Toggle = _a.Toggle, Select = _a.Select;
var host = "http://demo.searchkit.co/api/movies";
var ReactDOM = require("react-dom");
var React = require("react");
var react_router_1 = require('react-router');
var _ = require("lodash");
require("../../../../../theming/theme.scss");
require("./customisations.scss");
var MovieHitsListItem = function (props) {
    var bemBlocks = props.bemBlocks, result = props.result;
    var url = "http://www.imdb.com/title/" + result._source.imdbId;
    var source = _.extend({}, result._source, result.highlight);
    return (React.createElement("div", {className: bemBlocks.item().mix(bemBlocks.container("item")), "data-qa": "hit"}, React.createElement("div", {className: bemBlocks.item("poster")}, React.createElement("img", {"data-qa": "poster", src: result._source.poster})), React.createElement("div", {className: bemBlocks.item("details")}, React.createElement(react_router_1.Link, {to: "/list-app/view/" + result._source.imdbId}, React.createElement("h2", {className: bemBlocks.item("title"), dangerouslySetInnerHTML: { __html: source.title }})), React.createElement("h3", {className: bemBlocks.item("subtitle")}, "Released in ", source.year, ", rated ", source.imdbRating, "/10"), React.createElement("div", {className: bemBlocks.item("text"), dangerouslySetInnerHTML: { __html: source.plot }}))));
};
var searchkit = new SearchkitManager(host);
var App = (function (_super) {
    __extends(App, _super);
    function App() {
        _super.apply(this, arguments);
    }
    App.prototype.render = function () {
        return (React.createElement(SearchkitProvider, {searchkit: searchkit}, React.createElement("div", {className: "sk-layout list-app"}, React.createElement("div", {className: "sk-layout__top-bar sk-top-bar"}, React.createElement("div", {className: "sk-top-bar__content"}, React.createElement("div", {className: "my-logo"}, "Filter list components"), React.createElement(SearchBox, {autofocus: true, searchOnChange: true, prefixQueryFields: ["actors^1", "type^2", "languages", "title^10"]}))), React.createElement("div", {className: "sk-layout__body"}, React.createElement("div", {className: "sk-layout__filters"}, React.createElement("div", {className: "sk-layout__filters-row"}, React.createElement(MenuFilter, {translations: { "All": "All options" }, field: "type.raw", title: "ItemList", id: "item-list", listComponent: ItemList}), React.createElement(MenuFilter, {field: "type.raw", title: "CheckboxItemList", id: "checkbox-item-list", listComponent: CheckboxItemList}), React.createElement(MenuFilter, {field: "type.raw", title: "ItemHistogramList", id: "histogram-list", listComponent: ItemHistogramList}), React.createElement(MenuFilter, {field: "type.raw", title: "TagCloud", id: "tag-cloud", listComponent: TagCloud}), React.createElement(MenuFilter, {field: "type.raw", title: "Toggle", id: "toggle", listComponent: Toggle}), React.createElement(MenuFilter, {field: "type.raw", title: "Tabs", id: "tabs", listComponent: Tabs}), React.createElement(MenuFilter, {countFormatter: function (count) { return "#" + count; }, field: "type.raw", title: "Select", id: "select", listComponent: Select}))), React.createElement("div", {className: "sk-layout__results sk-results-list"}, React.createElement("div", {className: "sk-action-bar__info"}, React.createElement(HitsStats, {translations: {
            "hitstats.results_found": "{hitCount} results found"
        }})), React.createElement(Hits, {hitsPerPage: 12, highlightFields: ["title", "plot"], sourceFilter: ["plot", "title", "poster", "imdbId", "imdbRating", "year"], mod: "sk-hits-list", itemComponent: MovieHitsListItem, scrollTo: "body"}), React.createElement(NoHits, {suggestionsField: "title"}), React.createElement(Pagination, {showNumbers: true}))))));
    };
    return App;
}(React.Component));
var View = function (props) {
    return (React.createElement("div", null, React.createElement(react_router_1.Link, {to: '/list-app'}, "go to list"), React.createElement("a", {onClick: props.history.goBack}, "go back")));
};
ReactDOM.render((React.createElement(react_router_1.Router, {history: react_router_1.browserHistory}, React.createElement(react_router_1.Route, {path: "/list-app"}, React.createElement(react_router_1.IndexRoute, {component: App}), React.createElement(react_router_1.Route, {path: "view/:id", component: View})))), document.getElementById("root"));
//# sourceMappingURL=index.js.map