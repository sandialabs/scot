"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var React = require("react");
var ReactDOM = require("react-dom");
var src_1 = require("../../../../../src");
require("./customisations.scss");
require("../../../../../theming/theme.scss");
var TaxonomyHitsItem = function (props) {
    var result = props.result, bemBlocks = props.bemBlocks;
    return (React.createElement("div", {className: bemBlocks.item().mix(bemBlocks.container("item"))}, result._source.name));
};
var App = (function (_super) {
    __extends(App, _super);
    function App() {
        _super.call(this);
        var host = "http://demo.searchkit.co/api/taxonomy";
        this.searchkit = new src_1.SearchkitManager(host);
    }
    App.prototype.render = function () {
        return (React.createElement("div", null, React.createElement(src_1.SearchkitProvider, {searchkit: this.searchkit}, React.createElement("div", {className: "sk-layout"}, React.createElement("div", {className: "sk-layout__top-bar sk-top-bar"}, React.createElement("div", {className: "sk-top-bar__content"}, React.createElement("div", {className: "my-logo"}, "Searchkit Acme co"), React.createElement(src_1.SearchBox, {translations: { "searchbox.placeholder": "search regions" }, queryOptions: { "minimum_should_match": "70%" }, autofocus: true, searchOnChange: true, queryFields: ["title^5"]}))), React.createElement("div", {className: "sk-layout__body"}, React.createElement("div", {className: "sk-layout__filters"}, React.createElement(src_1.HierarchicalRefinementFilter, {field: "taxonomy", id: "categories", title: "Region", startLevel: 2}), React.createElement(src_1.RefinementListFilter, {field: "taxonomy.value", fieldOptions: { type: 'nested', options: { path: "taxonomy" } }, size: 10, id: "NestedTest", title: "Nested Test"}), React.createElement(src_1.NumericRefinementListFilter, {field: "taxonomy.level", options: [
            { title: "All" },
            { title: "1", from: 1, to: 2 },
            { title: "2", from: 2, to: 3 },
            { title: "3", from: 3 }
        ], fieldOptions: { type: 'nested', options: { path: "taxonomy" } }, id: "NestedNumeric", title: "Nested Numeric"}), React.createElement(src_1.RangeFilter, {min: 1, max: 6, field: "taxonomy.level", id: "levelRange", title: "Taxonomy level range", fieldOptions: { type: "nested", options: { path: "taxonomy" } }}), React.createElement(src_1.DynamicRangeFilter, {field: "taxonomy.level", id: "levelRangeDynamic", title: "Taxonomy level Dynamic range", fieldOptions: { type: "nested", options: { path: "taxonomy" } }})), React.createElement("div", {className: "sk-layout__results sk-results-list"}, React.createElement("div", {className: "sk-results-list__action-bar sk-action-bar"}, React.createElement("div", {className: "sk-action-bar__info"}, React.createElement(src_1.HitsStats, null)), React.createElement("div", {className: "sk-action-bar__filters"}, React.createElement(src_1.SelectedFilters, null), React.createElement(src_1.ResetFilters, null))), React.createElement(src_1.Hits, {hitsPerPage: 10, mod: "sk-hits-list", itemComponent: TaxonomyHitsItem}), React.createElement(src_1.NoHits, null), React.createElement(src_1.InitialLoader, null), React.createElement(src_1.Pagination, {showNumbers: true}))), React.createElement("a", {className: "view-src-link", href: "https://github.com/searchkit/searchkit-demo/blob/master/src/app/src/TaxonomyApp.tsx"}, "View source »")))));
    };
    return App;
}(React.Component));
exports.App = App;
ReactDOM.render(React.createElement(App, null), document.getElementById("root"));
//# sourceMappingURL=index.js.map