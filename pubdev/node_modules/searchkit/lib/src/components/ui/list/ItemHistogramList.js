"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var React = require("react");
var ItemListComponents_1 = require("./ItemListComponents");
var _1 = require("../../../");
var defaults = require('lodash/defaults');
var ItemHistogramComponent = (function (_super) {
    __extends(ItemHistogramComponent, _super);
    function ItemHistogramComponent() {
        _super.apply(this, arguments);
    }
    ItemHistogramComponent.prototype.getCountRatio = function () {
        var _a = this.props, rawCount = _a.rawCount, listDocCount = _a.listDocCount;
        if ((rawCount == undefined) || (listDocCount == undefined) || (listDocCount == 0)) {
            return 0;
        }
        else {
            return rawCount / listDocCount;
        }
    };
    ItemHistogramComponent.prototype.render = function () {
        var _a = this.props, bemBlocks = _a.bemBlocks, onClick = _a.onClick, active = _a.active, disabled = _a.disabled, style = _a.style, itemKey = _a.itemKey, label = _a.label, count = _a.count, showCount = _a.showCount, showCheckbox = _a.showCheckbox, listDocCount = _a.listDocCount;
        var block = bemBlocks.option;
        var className = block()
            .state({ active: active, disabled: disabled, histogram: true })
            .mix(bemBlocks.container("item"));
        var barWidth = (this.getCountRatio() * 100) + '%';
        return (React.createElement(_1.FastClick, {handler: onClick}, React.createElement("div", {className: className, style: style, "data-qa": "option", "data-key": itemKey}, React.createElement("div", {className: block("bar-container")}, React.createElement("div", {className: block("bar"), style: { width: barWidth }})), showCheckbox ? React.createElement("input", {type: "checkbox", "data-qa": "checkbox", checked: active, readOnly: true, className: block("checkbox").state({ active: active })}) : undefined, React.createElement("div", {"data-qa": "label", className: block("text")}, label), (showCount && (count != undefined)) ? React.createElement("div", {"data-qa": "count", className: block("count")}, count) : undefined)));
    };
    ItemHistogramComponent = __decorate([
        _1.PureRender, 
        __metadata('design:paramtypes', [])
    ], ItemHistogramComponent);
    return ItemHistogramComponent;
}(React.Component));
exports.ItemHistogramComponent = ItemHistogramComponent;
var ItemHistogramList = (function (_super) {
    __extends(ItemHistogramList, _super);
    function ItemHistogramList() {
        _super.apply(this, arguments);
    }
    ItemHistogramList.defaultProps = defaults({
        //mod: "sk-item-histogram",
        itemComponent: ItemHistogramComponent,
        showCount: true,
    }, ItemListComponents_1.AbstractItemList.defaultProps);
    return ItemHistogramList;
}(ItemListComponents_1.AbstractItemList));
exports.ItemHistogramList = ItemHistogramList;
//# sourceMappingURL=ItemHistogramList.js.map