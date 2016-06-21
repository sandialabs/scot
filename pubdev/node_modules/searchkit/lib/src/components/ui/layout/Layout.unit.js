"use strict";
var _this = this;
var React = require("react");
var enzyme_1 = require("enzyme");
var Layout_1 = require("./Layout");
var TestHelpers_1 = require("../../__test__/TestHelpers");
describe("Layout components", function () {
    it("should render correctly", function () {
        _this.wrapper = enzyme_1.mount(React.createElement("div", null, React.createElement(Layout_1.Layout, {size: "m"}, React.createElement(Layout_1.TopBar, null, "search bar"), React.createElement(Layout_1.LayoutBody, null, React.createElement(Layout_1.SideBar, null, "filters"), React.createElement(Layout_1.LayoutResults, null, React.createElement(Layout_1.ActionBar, null, React.createElement(Layout_1.ActionBarRow, null, "row 1"), React.createElement(Layout_1.ActionBarRow, null, "row 2")), React.createElement("p", null, "hits"))))));
        expect(_this.wrapper.html()).toEqual(TestHelpers_1.jsxToHTML(React.createElement("div", null, React.createElement("div", {className: "sk-layout sk-layout__size-m"}, React.createElement("div", {className: "sk-layout__top-bar sk-top-bar"}, React.createElement("div", {className: "sk-top-bar__content"}, "search bar")), React.createElement("div", {className: "sk-layout__body"}, React.createElement("div", {className: "sk-layout__filters"}, "filters"), React.createElement("div", {className: "sk-layout__results sk-results-list"}, React.createElement("div", {className: "sk-results-list__action-bar sk-action-bar"}, React.createElement("div", {className: "sk-action-bar-row"}, "row 1"), React.createElement("div", {className: "sk-action-bar-row"}, "row 2")), React.createElement("p", null, "hits")))))));
    });
    it("layout - no size prop", function () {
        _this.wrapper = enzyme_1.mount(React.createElement("div", null, React.createElement(Layout_1.Layout, null, "content")));
        expect(_this.wrapper.html()).toEqual(TestHelpers_1.jsxToHTML(React.createElement("div", null, React.createElement("div", {className: "sk-layout"}, "content"))));
    });
});
//# sourceMappingURL=Layout.unit.js.map