"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var _a = require("../../../../../src"), SearchkitManager = _a.SearchkitManager, SearchkitProvider = _a.SearchkitProvider, SearchBox = _a.SearchBox, Hits = _a.Hits, RefinementListFilter = _a.RefinementListFilter, Pagination = _a.Pagination, RangeFilter = _a.RangeFilter, HitsStats = _a.HitsStats, SortingSelector = _a.SortingSelector, NoHits = _a.NoHits, RangeHistogram = _a.RangeHistogram, RangeSlider = _a.RangeSlider, RangeInput = _a.RangeInput, RangeSliderHistogram = _a.RangeSliderHistogram, RangeSliderHistogramInput = _a.RangeSliderHistogramInput, RangeSliderInput = _a.RangeSliderInput, RangeHistogramInput = _a.RangeHistogramInput;
var host = "http://demo.searchkit.co/api/movies";
var ReactDOM = require("react-dom");
var React = require("react");
var searchkit = new SearchkitManager(host);
var _ = require("lodash");
require("../../../../../theming/theme.scss");
require("./customisations.scss");
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
        return (React.createElement(SearchkitProvider, {searchkit: searchkit}, React.createElement("div", {className: "sk-layout range-app"}, React.createElement("div", {className: "sk-layout__top-bar sk-top-bar"}, React.createElement("div", {className: "sk-top-bar__content"}, React.createElement("div", {className: "my-logo"}, "Range components"), React.createElement(SearchBox, {autofocus: true, searchOnChange: true, prefixQueryFields: ["actors^1", "type^2", "languages", "title^10"]}))), React.createElement("div", {className: "sk-layout__body"}, React.createElement("div", {className: "sk-layout__filters"}, React.createElement("div", {className: "sk-layout__filters-row"}, React.createElement(RangeFilter, {min: 0, max: 100, field: "metaScore", id: "metascore", title: "RangeHistogram", rangeComponent: RangeHistogram}), React.createElement(RangeFilter, {min: 0, max: 100, field: "metaScore", id: "metascore", title: "RangeSliderHistogram", rangeComponent: RangeSliderHistogram}), React.createElement(RangeFilter, {min: 0, max: 100, field: "metaScore", id: "metascore", title: "RangeHistogramInput", rangeComponent: RangeHistogramInput}), React.createElement(RangeFilter, {min: 0, max: 100, field: "metaScore", id: "metascore", title: "RangeSliderHistogramInput", rangeComponent: RangeSliderHistogramInput}), React.createElement(RangeFilter, {min: 0, max: 100, field: "metaScore", id: "metascore", title: "RangeSlider", rangeComponent: RangeSlider, rangeFormatter: function (count) { return count + " stars"; }}), React.createElement(RangeFilter, {min: 0, max: 100, field: "metaScore", id: "metascore", title: "RangeInput", rangeComponent: RangeInput}), React.createElement(RangeFilter, {min: 0, max: 100, field: "metaScore", id: "metascore", title: "RangeSliderInput", rangeComponent: RangeSliderInput}))), React.createElement("div", {className: "sk-layout__results sk-results-list"}, React.createElement("div", {className: "sk-action-bar__info"}, React.createElement(HitsStats, {translations: {
            "hitstats.results_found": "{hitCount} results found"
        }})), React.createElement(Hits, {hitsPerPage: 12, highlightFields: ["title", "plot"], sourceFilter: ["plot", "title", "poster", "imdbId", "imdbRating", "year"], mod: "sk-hits-grid", itemComponent: MovieHitsGridItem, scrollTo: "body"}), React.createElement(NoHits, {suggestionsField: "title"}), React.createElement(Pagination, {showNumbers: true}))))));
    };
    return App;
}(React.Component));
ReactDOM.render(React.createElement(App, null), document.getElementById("root"));
//# sourceMappingURL=index.js.map