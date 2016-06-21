"use strict";
var _this = this;
var React = require("react");
var enzyme_1 = require("enzyme");
var RangeSlider_1 = require('./RangeSlider');
var MockRange_1 = require('./MockRange');
var TestHelpers_1 = require("../../__test__/TestHelpers");
describe("RangeSlider", function () {
    it("should render and behave correctly", function () {
        _this.wrapper = enzyme_1.mount(React.createElement(MockRange_1.MockRange, {rangeComponent: RangeSlider_1.RangeSlider}));
        expect(_this.wrapper.html()).toEqual(TestHelpers_1.jsxToHTML(React.createElement("div", {className: "sk-range-slider"}, React.createElement("div", {className: "rc-slider"}, React.createElement("div", {className: "rc-slider-handle", style: { left: "50%" }}), React.createElement("div", {className: "rc-slider-handle", style: { left: "20%" }}), React.createElement("div", {className: "rc-slider-track", style: { left: "20%", width: "30%", visibility: "visible" }}), React.createElement("div", {className: "rc-slider-step"}, React.createElement("span", {className: "rc-slider-dot", style: { left: "0%" }}), React.createElement("span", {className: "rc-slider-dot", style: { left: "100%" }})), React.createElement("div", {className: "rc-slider-mark"}, React.createElement("span", {className: "rc-slider-mark-text", style: { width: "90%", left: "-45%" }}, "0"), React.createElement("span", {className: "rc-slider-mark-text", style: { width: "90%", left: "55%" }}, "10"))))));
    });
    it("mod + classname can be updated", function () {
        _this.wrapper = enzyme_1.mount(React.createElement(MockRange_1.MockRange, {rangeComponent: RangeSlider_1.RangeSlider, mod: "sk-range-slider-updated", className: "my-custom-class"}));
        expect(_this.wrapper.find(".sk-range-slider-updated").hasClass("my-custom-class")).toBe(true);
    });
});
//# sourceMappingURL=RangeSlider.unit.js.map