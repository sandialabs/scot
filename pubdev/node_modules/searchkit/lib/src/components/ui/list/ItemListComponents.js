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
var ItemComponents_1 = require("./ItemComponents");
var pure_render_1 = require("../../../core/react/pure-render");
var block = require('bem-cn');
var map = require("lodash/map");
var includes = require("lodash/includes");
var defaults = require("lodash/defaults");
var identity = require("lodash/identity");
var AbstractItemList = (function (_super) {
    __extends(AbstractItemList, _super);
    function AbstractItemList() {
        _super.apply(this, arguments);
    }
    AbstractItemList.prototype.isActive = function (option) {
        var _a = this.props, selectedItems = _a.selectedItems, multiselect = _a.multiselect;
        if (multiselect) {
            return includes(selectedItems, option.key);
        }
        else {
            if (selectedItems.length == 0)
                return null;
            return selectedItems[0] == option.key;
        }
    };
    AbstractItemList.prototype.render = function () {
        var _this = this;
        var _a = this.props, mod = _a.mod, itemComponent = _a.itemComponent, items = _a.items, _b = _a.selectedItems, selectedItems = _b === void 0 ? [] : _b, translate = _a.translate, toggleItem = _a.toggleItem, setItems = _a.setItems, multiselect = _a.multiselect, countFormatter = _a.countFormatter, disabled = _a.disabled, showCount = _a.showCount, className = _a.className, docCount = _a.docCount;
        var bemBlocks = {
            container: block(mod),
            option: block(mod + "-option")
        };
        var toggleFunc = multiselect ? toggleItem : (function (key) { return setItems([key]); });
        var actions = map(items, function (option) {
            var label = option.title || option.label || option.key;
            return React.createElement(itemComponent, {
                label: translate(label),
                onClick: function () { return toggleFunc(option.key); },
                bemBlocks: bemBlocks,
                key: option.key,
                itemKey: option.key,
                count: countFormatter(option.doc_count),
                rawCount: option.doc_count,
                listDocCount: docCount,
                disabled: option.disabled,
                showCount: showCount,
                active: _this.isActive(option)
            });
        });
        return (React.createElement("div", {"data-qa": "options", className: bemBlocks.container().mix(className).state({ disabled: disabled })}, actions));
    };
    AbstractItemList.defaultProps = {
        mod: "sk-item-list",
        showCount: true,
        itemComponent: ItemComponents_1.CheckboxItemComponent,
        translate: identity,
        multiselect: true,
        selectItems: [],
        countFormatter: identity
    };
    AbstractItemList = __decorate([
        pure_render_1.PureRender, 
        __metadata('design:paramtypes', [])
    ], AbstractItemList);
    return AbstractItemList;
}(React.Component));
exports.AbstractItemList = AbstractItemList;
var ItemList = (function (_super) {
    __extends(ItemList, _super);
    function ItemList() {
        _super.apply(this, arguments);
    }
    ItemList.defaultProps = defaults({
        itemComponent: ItemComponents_1.ItemComponent
    }, AbstractItemList.defaultProps);
    return ItemList;
}(AbstractItemList));
exports.ItemList = ItemList;
var CheckboxItemList = (function (_super) {
    __extends(CheckboxItemList, _super);
    function CheckboxItemList() {
        _super.apply(this, arguments);
    }
    CheckboxItemList.defaultProps = defaults({
        itemComponent: ItemComponents_1.CheckboxItemComponent
    }, AbstractItemList.defaultProps);
    return CheckboxItemList;
}(AbstractItemList));
exports.CheckboxItemList = CheckboxItemList;
var Toggle = (function (_super) {
    __extends(Toggle, _super);
    function Toggle() {
        _super.apply(this, arguments);
    }
    Toggle.defaultProps = defaults({
        itemComponent: ItemComponents_1.ItemComponent,
        mod: 'sk-toggle',
        showCount: false,
    }, AbstractItemList.defaultProps);
    return Toggle;
}(AbstractItemList));
exports.Toggle = Toggle;
var Tabs = (function (_super) {
    __extends(Tabs, _super);
    function Tabs() {
        _super.apply(this, arguments);
    }
    Tabs.defaultProps = defaults({
        itemComponent: ItemComponents_1.ItemComponent,
        mod: 'sk-tabs',
        showCount: false,
        multiselect: false,
    }, AbstractItemList.defaultProps);
    return Tabs;
}(AbstractItemList));
exports.Tabs = Tabs;
//# sourceMappingURL=ItemListComponents.js.map