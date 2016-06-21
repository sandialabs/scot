"use strict";
var _this = this;
var React = require("react");
var enzyme_1 = require("enzyme");
var FilterGroup_1 = require("./FilterGroup");
var TestHelpers_1 = require("../../__test__/TestHelpers");
describe("FilterGroup", function () {
    beforeEach(function () {
        _this.title = 'GroupTitle';
        _this.removeFilter = jasmine.createSpy('removeFilter');
        _this.removeFilters = jasmine.createSpy('removeFilters');
        _this.translate = function (str) { return (str + " translated"); };
        _this.filters = [
            { value: 'A' },
            { value: 'B' },
            { value: 'C' },
            { value: 'D' }
        ];
    });
    it("should render and behave correctly", function () {
        _this.wrapper = enzyme_1.mount(React.createElement(FilterGroup_1.FilterGroup, {title: _this.title, translate: _this.translate, className: "filter-group-1", removeFilter: _this.removeFilter, removeFilters: _this.removeFilters, filters: _this.filters}));
        expect(_this.wrapper.html()).toEqual(TestHelpers_1.jsxToHTML(React.createElement("div", {className: "sk-filter-group filter-group-1"}, React.createElement("div", {className: "sk-filter-group-items"}, React.createElement("div", {className: "sk-filter-group-items__title"}, "GroupTitle"), React.createElement("div", {className: "sk-filter-group-items__list"}, React.createElement("div", {className: "sk-filter-group-items__value", "data-key": "A"}, "A translated"), React.createElement("div", {className: "sk-filter-group-items__value", "data-key": "B"}, "B translated"), React.createElement("div", {className: "sk-filter-group-items__value", "data-key": "C"}, "C translated"), React.createElement("div", {className: "sk-filter-group-items__value", "data-key": "D"}, "D translated"))), React.createElement("div", {className: "sk-filter-group__remove-action"}, "X"))));
        expect(_this.removeFilters).not.toHaveBeenCalled();
        TestHelpers_1.fastClick(_this.wrapper.find(".sk-filter-group__remove-action"));
        expect(_this.removeFilters).toHaveBeenCalledWith(_this.filters);
        expect(_this.removeFilter).not.toHaveBeenCalled();
        TestHelpers_1.fastClick(_this.wrapper.find(".sk-filter-group-items__value").at(2));
        expect(_this.removeFilter).toHaveBeenCalledWith(_this.filters[2]);
    });
    it("mod + classname can be updated", function () {
        _this.wrapper = enzyme_1.mount(React.createElement(FilterGroup_1.FilterGroup, {mod: "sk-filter-group-updated", className: "my-custom-class", title: _this.title, translate: _this.translate, removeFilter: _this.removeFilter, removeFilters: _this.removeFilters, filters: _this.filters}));
        expect(_this.wrapper.find(".sk-filter-group-updated").hasClass("my-custom-class")).toBe(true);
    });
});
//# sourceMappingURL=FilterGroup.unit.js.map