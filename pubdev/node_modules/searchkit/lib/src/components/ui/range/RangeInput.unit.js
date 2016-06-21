"use strict";
var _this = this;
var React = require("react");
var enzyme_1 = require("enzyme");
var RangeInput_1 = require('./RangeInput');
var MockRange_1 = require('./MockRange');
var TestHelpers_1 = require("../../__test__/TestHelpers");
describe("RangeInput", function () {
    it("should render and behave correctly", function () {
        _this.wrapper = enzyme_1.mount(React.createElement(MockRange_1.MockRange, {rangeComponent: RangeInput_1.RangeInput}));
        expect(_this.wrapper.html()).toEqual(TestHelpers_1.jsxToHTML(React.createElement("form", {className: "sk-range-input"}, React.createElement("input", {type: "number", className: "sk-range-input__input", value: "2", placeholder: "min", onChange: function () { }}), React.createElement("div", {className: "sk-range-input__to-label"}, "-"), React.createElement("input", {type: "number", className: "sk-range-input__input", value: "5", placeholder: "max", onChange: function () { }}), React.createElement("button", {type: "submit", className: "sk-range-input__submit"}, "Go"))));
    });
    it("mod + classname can be updated", function () {
        _this.wrapper = enzyme_1.mount(React.createElement(MockRange_1.MockRange, {rangeComponent: RangeInput_1.RangeInput, mod: "sk-range-slider-updated", className: "my-custom-class"}));
        expect(_this.wrapper.find(".sk-range-slider-updated").hasClass("my-custom-class")).toBe(true);
    });
});
//# sourceMappingURL=RangeInput.unit.js.map