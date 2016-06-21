"use strict";
var _this = this;
var React = require("react");
var enzyme_1 = require("enzyme");
var RangeHistogram_1 = require('./RangeHistogram');
var MockRange_1 = require('./MockRange');
var TestHelpers_1 = require("../../__test__/TestHelpers");
describe("RangeHistogram", function () {
    it("should render and behave correctly", function () {
        _this.wrapper = enzyme_1.mount(React.createElement(MockRange_1.MockRange, {rangeComponent: RangeHistogram_1.RangeHistogram}));
        expect(_this.wrapper.html()).toEqual(TestHelpers_1.jsxToHTML(React.createElement("div", {className: "sk-range-histogram"}, React.createElement("div", {className: "sk-range-histogram__bar is-out-of-bounds", style: { height: '0%' }}), React.createElement("div", {className: "sk-range-histogram__bar is-out-of-bounds", style: { height: '0%' }}), React.createElement("div", {className: "sk-range-histogram__bar", style: { height: '0%' }}), React.createElement("div", {className: "sk-range-histogram__bar", style: { height: '60%' }}), React.createElement("div", {className: "sk-range-histogram__bar", style: { height: '70%' }}), React.createElement("div", {className: "sk-range-histogram__bar", style: { height: '80%' }}), React.createElement("div", {className: "sk-range-histogram__bar is-out-of-bounds", style: { height: '0%' }}), React.createElement("div", {className: "sk-range-histogram__bar is-out-of-bounds", style: { height: '100%' }}), React.createElement("div", {className: "sk-range-histogram__bar is-out-of-bounds", style: { height: '0%' }}), React.createElement("div", {className: "sk-range-histogram__bar is-out-of-bounds", style: { height: '0%' }}), React.createElement("div", {className: "sk-range-histogram__bar is-out-of-bounds", style: { height: '0%' }}))));
    });
    it("mod + classname can be updated", function () {
        _this.wrapper = enzyme_1.mount(React.createElement(MockRange_1.MockRange, {rangeComponent: RangeHistogram_1.RangeHistogram, mod: "sk-range-histogram-updated", className: "my-custom-class"}));
        expect(_this.wrapper.find(".sk-range-histogram-updated").hasClass("my-custom-class")).toBe(true);
    });
});
//# sourceMappingURL=RangeHistogram.unit.js.map