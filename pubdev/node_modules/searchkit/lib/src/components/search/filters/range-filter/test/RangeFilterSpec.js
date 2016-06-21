"use strict";
var _this = this;
var React = require("react");
var enzyme_1 = require("enzyme");
var RangeFilter_tsx_1 = require("../src/RangeFilter.tsx");
var core_1 = require("../../../../../core");
var TestHelpers_1 = require("../../../../__test__/TestHelpers");
describe("Range Filter tests", function () {
    beforeEach(function () {
        _this.searchkit = core_1.SearchkitManager.mock();
        spyOn(_this.searchkit, "performSearch");
        _this.createWrapper = function (withHistogram, interval) {
            if (interval === void 0) { interval = undefined; }
            _this.wrapper = enzyme_1.mount(React.createElement(RangeFilter_tsx_1.RangeFilter, {id: "m", searchkit: _this.searchkit, field: "metascore", min: 0, max: 100, title: "metascore", interval: interval, rangeFormatter: function (count) { return count + " score"; }, showHistogram: withHistogram}));
            _this.searchkit.setResults({
                "aggregations": {
                    "m": {
                        "m": {
                            "buckets": [
                                { key: "10", doc_count: 1 },
                                { key: "20", doc_count: 3 },
                                { key: "30", doc_count: 1 },
                                { key: "40", doc_count: 1 },
                                { key: "50", doc_count: 1 },
                                { key: "60", doc_count: 5 },
                                { key: "70", doc_count: 1 },
                                { key: "80", doc_count: 1 },
                                { key: "90", doc_count: 1 },
                                { key: "100", doc_count: 1 }
                            ]
                        }
                    }
                }
            });
            _this.wrapper.update();
            _this.accessor = _this.searchkit.accessors.getAccessors()[0];
        };
    });
    it("accessor has correct config", function () {
        _this.createWrapper(true);
        expect(_this.accessor.options).toEqual({
            id: "m",
            min: 0,
            max: 100,
            field: "metascore",
            title: "metascore",
            interval: undefined,
            loadHistogram: true,
            fieldOptions: {
                type: 'embedded',
                field: 'metascore'
            }
        });
    });
    it('renders correctly', function () {
        _this.createWrapper(true);
        expect(_this.wrapper.html()).toEqual(TestHelpers_1.jsxToHTML(React.createElement("div", {className: "sk-panel filter--m"}, React.createElement("div", {className: "sk-panel__header"}, "metascore"), React.createElement("div", {className: "sk-panel__content"}, React.createElement("div", null, React.createElement("div", {className: "sk-range-histogram"}, React.createElement("div", {className: "sk-range-histogram__bar", style: { height: "20%" }}), React.createElement("div", {className: "sk-range-histogram__bar", style: { height: "60%" }}), React.createElement("div", {className: "sk-range-histogram__bar", style: { height: "20%" }}), React.createElement("div", {className: "sk-range-histogram__bar", style: { height: "20%" }}), React.createElement("div", {className: "sk-range-histogram__bar", style: { height: "20%" }}), React.createElement("div", {className: "sk-range-histogram__bar", style: { height: "100%" }}), React.createElement("div", {className: "sk-range-histogram__bar", style: { height: "20%" }}), React.createElement("div", {className: "sk-range-histogram__bar", style: { height: "20%" }}), React.createElement("div", {className: "sk-range-histogram__bar", style: { height: "20%" }}), React.createElement("div", {className: "sk-range-histogram__bar", style: { height: "20%" }})), React.createElement("div", {className: "sk-range-slider"}, React.createElement("div", {className: "rc-slider"}, React.createElement("div", {className: "rc-slider-handle", style: { left: "100%" }}), React.createElement("div", {className: "rc-slider-handle", style: { left: "0%" }}), React.createElement("div", {className: "rc-slider-track", style: { left: "0%", width: "100%", visibility: "visible" }}), React.createElement("div", {className: "rc-slider-step"}, React.createElement("span", {className: "rc-slider-dot rc-slider-dot-active", style: { left: "0%" }}), React.createElement("span", {className: "rc-slider-dot rc-slider-dot-active", style: { left: "100%" }})), React.createElement("div", {className: "rc-slider-mark"}, React.createElement("span", {className: "rc-slider-mark-text rc-slider-mark-text-active", style: { width: "90%", left: "-45%" }}, "0 score"), React.createElement("span", {className: "rc-slider-mark-text rc-slider-mark-text-active", style: { width: "90%", left: "55%" }}, "100 score")))))))));
    });
    it("renders without histogram", function () {
        _this.createWrapper(false);
        expect(_this.wrapper.find(".sk-range-histogram").length).toBe(0);
        expect(_this.wrapper.find(".sk-range-histogram__bar").length).toBe(0);
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
        _this.wrapper.node.sliderUpdateAndSearch({ min: 0, max: 100 });
        expect(_this.accessor.state.getValue()).toEqual({});
    });
    it("has default interval", function () {
        _this.createWrapper(true);
        expect(_this.accessor.getInterval()).toEqual(5);
    });
    it("handles interval correctly", function () {
        _this.createWrapper(true, 2);
        expect(_this.accessor.getInterval()).toEqual(2);
    });
    it("renders limited range correctly", function () {
        _this.createWrapper(true);
        _this.wrapper.node.sliderUpdate({ min: 30, max: 70 });
        expect(_this.wrapper.find(".sk-range-histogram").html()).toEqual(TestHelpers_1.jsxToHTML(React.createElement("div", {className: "sk-range-histogram"}, React.createElement("div", {className: "sk-range-histogram__bar is-out-of-bounds", style: { height: "20%" }}), React.createElement("div", {className: "sk-range-histogram__bar is-out-of-bounds", style: { height: "60%" }}), React.createElement("div", {className: "sk-range-histogram__bar", style: { height: "20%" }}), React.createElement("div", {className: "sk-range-histogram__bar", style: { height: "20%" }}), React.createElement("div", {className: "sk-range-histogram__bar", style: { height: "20%" }}), React.createElement("div", {className: "sk-range-histogram__bar", style: { height: "100%" }}), React.createElement("div", {className: "sk-range-histogram__bar", style: { height: "20%" }}), React.createElement("div", {className: "sk-range-histogram__bar is-out-of-bounds", style: { height: "20%" }}), React.createElement("div", {className: "sk-range-histogram__bar is-out-of-bounds", style: { height: "20%" }}), React.createElement("div", {className: "sk-range-histogram__bar is-out-of-bounds", style: { height: "20%" }}))));
    });
});
//# sourceMappingURL=RangeFilterSpec.js.map