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
var core_1 = require("../../../core");
var block = require('bem-cn');
var map = require("lodash/map");
var filter = require("lodash/filter");
var transform = require("lodash/transform");
var find = require("lodash/find");
var identity = require("lodash/identity");
var Select = (function (_super) {
    __extends(Select, _super);
    function Select(props) {
        _super.call(this, props);
        this.onChange = this.onChange.bind(this);
    }
    Select.prototype.onChange = function (e) {
        var setItems = this.props.setItems;
        var key = e.target.value;
        setItems([key]);
    };
    Select.prototype.getSelectedValue = function () {
        var _a = this.props.selectedItems, selectedItems = _a === void 0 ? [] : _a;
        if (selectedItems.length == 0)
            return null;
        return selectedItems[0];
    };
    Select.prototype.render = function () {
        var _a = this.props, mod = _a.mod, className = _a.className, items = _a.items, disabled = _a.disabled, showCount = _a.showCount, translate = _a.translate, countFormatter = _a.countFormatter;
        var bemBlocks = {
            container: block(mod)
        };
        return (React.createElement("div", {className: bemBlocks.container().mix(className).state({ disabled: disabled })}, React.createElement("select", {onChange: this.onChange, value: this.getSelectedValue()}, map(items, function (_a, idx) {
            var key = _a.key, label = _a.label, title = _a.title, disabled = _a.disabled, doc_count = _a.doc_count;
            var text = translate(label || title || key);
            if (showCount && doc_count !== undefined)
                text += " (" + countFormatter(doc_count) + ")";
            return React.createElement("option", {key: key, value: key, disabled: disabled}, text);
        }))));
    };
    Select.defaultProps = {
        mod: "sk-select",
        showCount: true,
        translate: identity,
        countFormatter: identity
    };
    Select = __decorate([
        core_1.PureRender, 
        __metadata('design:paramtypes', [Object])
    ], Select);
    return Select;
}(React.Component));
exports.Select = Select;
//# sourceMappingURL=Select.js.map