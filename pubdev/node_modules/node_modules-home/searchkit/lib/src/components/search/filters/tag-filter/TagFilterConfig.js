"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var core_1 = require("../../../../core");
var TagFilterConfig = (function (_super) {
    __extends(TagFilterConfig, _super);
    function TagFilterConfig() {
        _super.apply(this, arguments);
    }
    TagFilterConfig.prototype.defineAccessor = function () {
        var _a = this.props, field = _a.field, id = _a.id, operator = _a.operator, title = _a.title;
        return new core_1.FacetAccessor(field, {
            id: id, operator: operator, title: title, size: 1, loadAggregations: false
        });
    };
    TagFilterConfig.prototype.componentDidUpdate = function (prevProps) {
        if (prevProps.operator != this.props.operator) {
            this.accessor.options.operator = this.props.operator;
            this.searchkit.performSearch();
        }
    };
    TagFilterConfig.prototype.render = function () {
        return null;
    };
    return TagFilterConfig;
}(core_1.SearchkitComponent));
exports.TagFilterConfig = TagFilterConfig;
//# sourceMappingURL=TagFilterConfig.js.map