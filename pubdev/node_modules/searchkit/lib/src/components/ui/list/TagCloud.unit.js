"use strict";
var _this = this;
var React = require("react");
var enzyme_1 = require("enzyme");
var bemBlock = require('bem-cn');
var TagCloud_1 = require("./TagCloud");
var MockList_1 = require("./MockList");
var TestHelpers_1 = require("../../__test__/TestHelpers");
describe("TagCloud", function () {
    it("should render and behave correctly", function () {
        _this.wrapper = enzyme_1.mount(React.createElement(MockList_1.MockList, {listComponent: TagCloud_1.TagCloud}));
        expect(_this.wrapper.html()).toEqual(TestHelpers_1.jsxToHTML(React.createElement("div", {className: "sk-tag-cloud"}, React.createElement("div", {className: "sk-tag-cloud-option sk-tag-cloud__item is-active", style: { fontSize: "1em" }, "data-qa": "option", "data-key": "a"}, React.createElement("div", {"data-qa": "label", className: "sk-tag-cloud-option__text"}, "A translated")), React.createElement("div", {className: "sk-tag-cloud-option sk-tag-cloud__item is-disabled", style: { fontSize: "1.1em" }, "data-qa": "option", "data-key": "b"}, React.createElement("div", {"data-qa": "label", className: "sk-tag-cloud-option__text"}, "B translated")), React.createElement("div", {className: "sk-tag-cloud-option sk-tag-cloud__item is-active", style: { fontSize: "1.2em" }, "data-qa": "option", "data-key": "c"}, React.createElement("div", {"data-qa": "label", className: "sk-tag-cloud-option__text"}, "C translated")), React.createElement("div", {className: "sk-tag-cloud-option sk-tag-cloud__item", style: { fontSize: "1.5em" }, "data-qa": "option", "data-key": "d"}, React.createElement("div", {"data-qa": "label", className: "sk-tag-cloud-option__text"}, "d translated")))));
        _this.wrapper.setProps({ disabled: true });
        expect(_this.wrapper.find(".sk-tag-cloud").hasClass("is-disabled")).toBe(true);
        expect(_this.wrapper.node.state.toggleItem).not.toHaveBeenCalled();
        TestHelpers_1.fastClick(_this.wrapper.find(".sk-tag-cloud__item").at(2));
        expect(_this.wrapper.node.state.toggleItem).toHaveBeenCalledWith("c");
    });
    it("should sort items", function () {
        var items = [
            { key: "d", doc_count: 15 },
            { key: "a", label: "a", doc_count: 10 },
            { key: "c", title: "C", doc_count: 12 },
            { key: "b", label: "B", doc_count: 11 },
        ];
        _this.wrapper = enzyme_1.mount(React.createElement(MockList_1.MockList, {listComponent: TagCloud_1.TagCloud, items: items}));
        expect(_this.wrapper.html()).toEqual(TestHelpers_1.jsxToHTML(React.createElement("div", {className: "sk-tag-cloud"}, React.createElement("div", {className: "sk-tag-cloud-option sk-tag-cloud__item is-active", style: { fontSize: "1em" }, "data-qa": "option", "data-key": "a"}, React.createElement("div", {"data-qa": "label", className: "sk-tag-cloud-option__text"}, "a translated")), React.createElement("div", {className: "sk-tag-cloud-option sk-tag-cloud__item", style: { fontSize: "1.1em" }, "data-qa": "option", "data-key": "b"}, React.createElement("div", {"data-qa": "label", className: "sk-tag-cloud-option__text"}, "B translated")), React.createElement("div", {className: "sk-tag-cloud-option sk-tag-cloud__item is-active", style: { fontSize: "1.2em" }, "data-qa": "option", "data-key": "c"}, React.createElement("div", {"data-qa": "label", className: "sk-tag-cloud-option__text"}, "C translated")), React.createElement("div", {className: "sk-tag-cloud-option sk-tag-cloud__item", style: { fontSize: "1.5em" }, "data-qa": "option", "data-key": "d"}, React.createElement("div", {"data-qa": "label", className: "sk-tag-cloud-option__text"}, "d translated")))));
    });
    it("mod + classname can be updated", function () {
        _this.wrapper = enzyme_1.mount(React.createElement(MockList_1.MockList, {listComponent: TagCloud_1.TagCloud, mod: "sk-other-class", className: "my-custom-class"}));
        expect(_this.wrapper.find(".sk-other-class").hasClass("my-custom-class")).toBe(true);
    });
    it("show count", function () {
        _this.wrapper = enzyme_1.mount(React.createElement(MockList_1.MockList, {listComponent: TagCloud_1.TagCloud, showCount: true}));
        expect(_this.wrapper.find(".sk-tag-cloud__item").at(0).text())
            .toBe("A translated#10"); // Count is appended in a span and styled with CSS
    });
});
//# sourceMappingURL=TagCloud.unit.js.map