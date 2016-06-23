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
var _1 = require("../../../");
function itemRenderer(props) {
    var bemBlocks = props.bemBlocks, onClick = props.onClick, active = props.active, disabled = props.disabled, style = props.style, itemKey = props.itemKey, label = props.label, count = props.count, showCount = props.showCount, showCheckbox = props.showCheckbox;
    var block = bemBlocks.option;
    var className = block()
        .state({ active: active, disabled: disabled })
        .mix(bemBlocks.container("item"));
    var hasCount = showCount && (count != undefined) && (count != null);
    return (React.createElement(_1.FastClick, {handler: onClick}, React.createElement("div", {className: className, style: style, "data-qa": "option", "data-key": itemKey}, showCheckbox ? React.createElement("input", {type: "checkbox", "data-qa": "checkbox", checked: active, readOnly: true, className: block("checkbox").state({ active: active })}) : undefined, React.createElement("div", {"data-qa": "label", className: block("text")}, label), hasCount ? React.createElement("div", {"data-qa": "count", className: block("count")}, count) : undefined)));
}
var ItemComponent = (function (_super) {
    __extends(ItemComponent, _super);
    function ItemComponent() {
        _super.apply(this, arguments);
    }
    ItemComponent.prototype.render = function () {
        return itemRenderer(this.props);
    };
    ItemComponent.defaultProps = {
        showCount: true,
        showCheckbox: false
    };
    ItemComponent = __decorate([
        _1.PureRender, 
        __metadata('design:paramtypes', [])
    ], ItemComponent);
    return ItemComponent;
}(React.Component));
exports.ItemComponent = ItemComponent;
var CheckboxItemComponent = (function (_super) {
    __extends(CheckboxItemComponent, _super);
    function CheckboxItemComponent() {
        _super.apply(this, arguments);
    }
    CheckboxItemComponent.prototype.render = function () {
        return itemRenderer(this.props);
    };
    CheckboxItemComponent.defaultProps = {
        showCount: true,
        showCheckbox: true
    };
    CheckboxItemComponent = __decorate([
        _1.PureRender, 
        __metadata('design:paramtypes', [])
    ], CheckboxItemComponent);
    return CheckboxItemComponent;
}(React.Component));
exports.CheckboxItemComponent = CheckboxItemComponent;
//# sourceMappingURL=ItemComponents.js.map