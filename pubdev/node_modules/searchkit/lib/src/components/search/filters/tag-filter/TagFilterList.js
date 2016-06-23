"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var React = require("react");
var TagFilter_1 = require("./TagFilter");
var map = require("lodash/map");
var TagFilterList = (function (_super) {
    __extends(TagFilterList, _super);
    function TagFilterList() {
        _super.apply(this, arguments);
    }
    TagFilterList.prototype.render = function () {
        var _a = this.props, field = _a.field, values = _a.values, searchkit = _a.searchkit;
        return (React.createElement("div", {className: "sk-tag-filter-list"}, map(values, function (value) { return React.createElement(TagFilter_1.TagFilter, {key: value, field: field, value: value, searchkit: searchkit}); })));
    };
    return TagFilterList;
}(React.Component));
exports.TagFilterList = TagFilterList;
//# sourceMappingURL=TagFilterList.js.map