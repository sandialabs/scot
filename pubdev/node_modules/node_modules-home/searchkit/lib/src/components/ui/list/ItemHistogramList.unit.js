"use strict";
var _this = this;
var React = require("react");
var enzyme_1 = require("enzyme");
var ItemHistogramList_1 = require("./ItemHistogramList");
var MockList_1 = require("./MockList");
var TestHelpers_1 = require("../../__test__/TestHelpers");
describe("ItemHistogramList Components", function () {
    it("should render and behave correctly", function () {
        _this.wrapper = enzyme_1.mount(React.createElement(MockList_1.MockList, {listComponent: ItemHistogramList_1.ItemHistogramList}));
        var total = 10 + 11 + 12 + 15;
        expect(_this.wrapper.html()).toEqual(TestHelpers_1.jsxToHTML(React.createElement("div", {"data-qa": "options", className: "sk-item-list"}, React.createElement("div", {className: "sk-item-list-option sk-item-list__item is-active is-histogram", "data-qa": "option", "data-key": "a"}, React.createElement("div", {className: "sk-item-list-option__bar-container"}, React.createElement("div", {className: "sk-item-list-option__bar", style: { width: "20.833333333333336%" }})), React.createElement("div", {"data-qa": "label", className: "sk-item-list-option__text"}, "A translated"), React.createElement("div", {"data-qa": "count", className: "sk-item-list-option__count"}, "#10")), React.createElement("div", {className: "sk-item-list-option sk-item-list__item is-disabled is-histogram", "data-qa": "option", "data-key": "b"}, React.createElement("div", {className: "sk-item-list-option__bar-container"}, React.createElement("div", {className: "sk-item-list-option__bar", style: { width: "22.916666666666664%" }})), React.createElement("div", {"data-qa": "label", className: "sk-item-list-option__text"}, "B translated"), React.createElement("div", {"data-qa": "count", className: "sk-item-list-option__count"}, "#11")), React.createElement("div", {className: "sk-item-list-option sk-item-list__item is-active is-histogram", "data-qa": "option", "data-key": "c"}, React.createElement("div", {className: "sk-item-list-option__bar-container"}, React.createElement("div", {className: "sk-item-list-option__bar", style: { width: "25%" }})), React.createElement("div", {"data-qa": "label", className: "sk-item-list-option__text"}, "C translated"), React.createElement("div", {"data-qa": "count", className: "sk-item-list-option__count"}, "#12")), React.createElement("div", {className: "sk-item-list-option sk-item-list__item is-histogram", "data-qa": "option", "data-key": "d"}, React.createElement("div", {className: "sk-item-list-option__bar-container"}, React.createElement("div", {className: "sk-item-list-option__bar", style: { width: "31.25%" }})), React.createElement("div", {"data-qa": "label", className: "sk-item-list-option__text"}, "d translated"), React.createElement("div", {"data-qa": "count", className: "sk-item-list-option__count"}, "#15")))));
        _this.wrapper.setProps({ disabled: true });
        expect(_this.wrapper.find(".sk-item-list").hasClass("is-disabled")).toBe(true);
        expect(_this.wrapper.find(".sk-item-list-option__count").length).toBe(4);
        _this.wrapper.setProps({ showCount: false });
        expect(_this.wrapper.find(".sk-item-list-option__count").length).toBe(0);
        _this.wrapper.setProps({ mod: "my-item-list" });
        expect(_this.wrapper.find(".my-item-list").length).toBe(1);
        expect(_this.wrapper.node.state.toggleItem).not.toHaveBeenCalled();
        TestHelpers_1.fastClick(_this.wrapper.find(".my-item-list-option").at(2));
        expect(_this.wrapper.node.state.toggleItem).toHaveBeenCalledWith("c");
    });
    it("should handle multiselect={false}", function () {
        _this.wrapper = enzyme_1.mount(React.createElement(MockList_1.MockList, {listComponent: ItemHistogramList_1.ItemHistogramList, multiselect: false}));
        expect(_this.wrapper.node.state.toggleItem).not.toHaveBeenCalled();
        expect(_this.wrapper.node.state.setItems).not.toHaveBeenCalled();
        TestHelpers_1.fastClick(_this.wrapper.find(".sk-item-list-option").at(2));
        expect(_this.wrapper.node.state.toggleItem).not.toHaveBeenCalled();
        expect(_this.wrapper.node.state.setItems).toHaveBeenCalledWith(["c"]);
    });
    it("mod + classname can be updated", function () {
        _this.wrapper = enzyme_1.mount(React.createElement(MockList_1.MockList, {listComponent: ItemHistogramList_1.ItemHistogramList, mod: "sk-item-list-updated", className: "my-custom-class"}));
        expect(_this.wrapper.find(".sk-item-list-updated").hasClass("my-custom-class")).toBe(true);
    });
});
//# sourceMappingURL=ItemHistogramList.unit.js.map