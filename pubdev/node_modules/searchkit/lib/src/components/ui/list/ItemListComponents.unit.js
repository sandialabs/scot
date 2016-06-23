"use strict";
var _this = this;
var React = require("react");
var enzyme_1 = require("enzyme");
var ItemListComponents_1 = require("./ItemListComponents");
var ItemComponents_1 = require("./ItemComponents");
var MockList_1 = require("./MockList");
var TestHelpers_1 = require("../../__test__/TestHelpers");
describe("ItemList Components", function () {
    it("ItemList should render and behave correctly", function () {
        _this.wrapper = enzyme_1.mount(React.createElement(MockList_1.MockList, {listComponent: ItemListComponents_1.ItemList}));
        expect(_this.wrapper.html()).toEqual(TestHelpers_1.jsxToHTML(React.createElement("div", {"data-qa": "options", className: "sk-item-list"}, React.createElement("div", {className: "sk-item-list-option sk-item-list__item is-active", "data-qa": "option", "data-key": "a"}, React.createElement("div", {"data-qa": "label", className: "sk-item-list-option__text"}, "A translated"), React.createElement("div", {"data-qa": "count", className: "sk-item-list-option__count"}, "#10")), React.createElement("div", {className: "sk-item-list-option sk-item-list__item is-disabled", "data-qa": "option", "data-key": "b"}, React.createElement("div", {"data-qa": "label", className: "sk-item-list-option__text"}, "B translated"), React.createElement("div", {"data-qa": "count", className: "sk-item-list-option__count"}, "#11")), React.createElement("div", {className: "sk-item-list-option sk-item-list__item is-active", "data-qa": "option", "data-key": "c"}, React.createElement("div", {"data-qa": "label", className: "sk-item-list-option__text"}, "C translated"), React.createElement("div", {"data-qa": "count", className: "sk-item-list-option__count"}, "#12")), React.createElement("div", {className: "sk-item-list-option sk-item-list__item", "data-qa": "option", "data-key": "d"}, React.createElement("div", {"data-qa": "label", className: "sk-item-list-option__text"}, "d translated"), React.createElement("div", {"data-qa": "count", className: "sk-item-list-option__count"}, "#15")))));
        _this.wrapper.setProps({ disabled: true });
        expect(_this.wrapper.find(".sk-item-list").hasClass("is-disabled")).toBe(true);
        expect(_this.wrapper.find(".sk-item-list-option__count").length).toBe(4);
        _this.wrapper.setProps({ showCount: false });
        expect(_this.wrapper.find(".sk-item-list-option__count").length).toBe(0);
        expect(_this.wrapper.find("input[type='checkbox']").length).toBe(0);
        _this.wrapper.setProps({ itemComponent: ItemComponents_1.CheckboxItemComponent });
        expect(_this.wrapper.find("input[type='checkbox']").length).toBe(4);
        _this.wrapper.setProps({ mod: "my-item-list" });
        expect(_this.wrapper.find(".my-item-list").length).toBe(1);
        expect(_this.wrapper.node.state.toggleItem).not.toHaveBeenCalled();
        TestHelpers_1.fastClick(_this.wrapper.find(".my-item-list-option").at(2));
        expect(_this.wrapper.node.state.toggleItem).toHaveBeenCalledWith("c");
    });
    it("check default props are set correctly", function () {
        expect(ItemListComponents_1.CheckboxItemList.defaultProps.itemComponent).toBe(ItemComponents_1.CheckboxItemComponent);
        expect(ItemListComponents_1.ItemList.defaultProps.itemComponent).toBe(ItemComponents_1.ItemComponent);
    });
    it("mod + classname can be updated", function () {
        var props = {
            items: _this.items, selectedItems: _this.selectedItems,
            toggleItem: _this.toggleItem, setItems: _this.setItems,
            translate: _this.translate,
            mod: "sk-item-list-updated", className: "my-custom-class"
        };
        _this.wrapper = enzyme_1.mount(React.createElement(MockList_1.MockList, {listComponent: ItemListComponents_1.ItemList, mod: "sk-item-list-updated", className: "my-custom-class"}));
        expect(_this.wrapper.find(".sk-item-list-updated").hasClass("my-custom-class")).toBe(true);
    });
});
//# sourceMappingURL=ItemListComponents.unit.js.map