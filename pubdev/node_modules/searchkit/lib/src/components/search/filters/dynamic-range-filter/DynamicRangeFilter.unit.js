"use strict";
var _this = this;
var React = require("react");
var enzyme_1 = require("enzyme");
var DynamicRangeFilter_tsx_1 = require("./DynamicRangeFilter.tsx");
var core_1 = require("../../../../core");
var TestHelpers_1 = require("../../../__test__/TestHelpers");
describe("Dynamic Range Filter tests", function () {
    beforeEach(function () {
        _this.searchkit = core_1.SearchkitManager.mock();
        spyOn(_this.searchkit, "performSearch");
        _this.createWrapper = function () {
            _this.wrapper = enzyme_1.mount(React.createElement(DynamicRangeFilter_tsx_1.DynamicRangeFilter, {id: "m", searchkit: _this.searchkit, field: "metascore", title: "metascore", rangeFormatter: function (count) { return count + " score"; }}));
            _this.searchkit.setResults({
                "aggregations": {
                    "m": {
                        "m": {
                            avg: 20,
                            count: 1,
                            max: 120,
                            min: 1,
                            sum: 100000
                        }
                    }
                }
            });
            _this.wrapper.update();
            _this.accessor = _this.searchkit.accessors.getAccessors()[0];
        };
    });
    it("renders correctly", function () {
        _this.createWrapper();
        expect(_this.wrapper.html()).toBe(TestHelpers_1.jsxToHTML(React.createElement("div", {className: "sk-panel filter--m"}, React.createElement("div", {className: "sk-panel__header"}, "metascore"), React.createElement("div", {className: "sk-panel__content"}, React.createElement("div", {className: "sk-range-slider"}, React.createElement("div", {className: "rc-slider"}, React.createElement("div", {className: "rc-slider-handle", style: { left: " 100%" }}), React.createElement("div", {className: "rc-slider-handle", style: { left: " 0%" }}), React.createElement("div", {className: "rc-slider-track", style: { visibility: " visible", " left": " 0%", " width": " 100%" }}), React.createElement("div", {className: "rc-slider-step"}, React.createElement("span", {className: "rc-slider-dot rc-slider-dot-active", style: { left: "0%" }}), React.createElement("span", {className: "rc-slider-dot rc-slider-dot-active", style: { left: "100%" }})), React.createElement("div", {className: "rc-slider-mark"}, React.createElement("span", {className: "rc-slider-mark-text rc-slider-mark-text-active", style: { width: "90%", left: "-45%" }}, "1 score"), React.createElement("span", {className: "rc-slider-mark-text rc-slider-mark-text-active", style: { width: "90%", left: "55%" }}, "120 score"))))))));
    });
    it("accessor has correct config", function () {
        _this.createWrapper();
        expect(_this.accessor.options).toEqual({
            id: "m",
            field: "metascore",
            title: "metascore",
            fieldOptions: {
                type: "embedded",
                field: "metascore"
            }
        });
    });
    it("handle slider events correctly", function () {
        _this.createWrapper(true);
        _this.wrapper.node.sliderUpdate({ min: 30, max: 70 });
        expect(_this.accessor.state.getValue()).toEqual({
            min: 30, max: 70
        });
        expect(_this.searchkit.performSearch).not.toHaveBeenCalled();
        _this.wrapper.node.sliderUpdateAndSearch({ min: 40, max: 60 });
        expect(_this.accessor.state.getValue()).toEqual({
            min: 40, max: 60
        });
        expect(_this.searchkit.performSearch).toHaveBeenCalled();
        // min/max should clear
        _this.wrapper.node.sliderUpdateAndSearch({ min: 1, max: 120 });
        expect(_this.accessor.state.getValue()).toEqual({});
    });
});
//# sourceMappingURL=DynamicRangeFilter.unit.js.map