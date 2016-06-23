"use strict";
var _this = this;
var React = require("react");
var enzyme_1 = require("enzyme");
var TestHelpers_1 = require("../../../../__test__/TestHelpers");
var HierarchicalRefinementFilter_tsx_1 = require("../src/HierarchicalRefinementFilter.tsx");
var core_1 = require("../../../../../core");
var bem = require("bem-cn");
var _ = require("lodash");
describe("Refinement List Filter tests", function () {
    beforeEach(function () {
        _this.searchkit = core_1.SearchkitManager.mock();
        spyOn(_this.searchkit, "performSearch");
        _this.wrapper = enzyme_1.mount(React.createElement(HierarchicalRefinementFilter_tsx_1.HierarchicalRefinementFilter, {countFormatter: function (count) { return "#" + count; }, field: "test", id: "testid", title: "test title", searchkit: _this.searchkit}));
        _this.accessor = _this.searchkit.accessors.getAccessors()[0];
        _this.setResults = function () {
            _this.searchkit.setResults({
                aggregations: {
                    testid: {
                        children: {
                            lvl0: {
                                children: {
                                    buckets: [
                                        { key: "option1", doc_count: 1 },
                                        { key: "option2", doc_count: 2 }
                                    ]
                                }
                            },
                            lvl1: {
                                children: {
                                    buckets: [
                                        { key: "option2child1", doc_count: 1 },
                                        { key: "option2child2", doc_count: 1 }
                                    ]
                                }
                            }
                        }
                    }
                }
            });
        };
        _this.getContainer = function (label, index) {
            var container = _this.wrapper.find(".sk-hierarchical-refinement-list__" + label);
            if (_.isNumber(index)) {
                return container.children().at(index);
            }
            else {
                return container;
            }
        };
    });
    it("should configure accessor correctly", function () {
        expect(_this.accessor.key).toBe("testid");
        var options = _this.accessor.options;
        expect(options).toEqual({
            "id": "testid",
            "title": "test title",
            "field": "test",
            "orderKey": undefined,
            "orderDirection": undefined,
            "startLevel": undefined
        });
    });
    it("should render correctly", function () {
        _this.setResults();
        expect(_this.wrapper.html()).toEqual(TestHelpers_1.jsxToHTML(React.createElement("div", {"data-qa": "filter--testid", className: "sk-hierarchical-refinement-list filter--testid"}, React.createElement("div", {"data-qa": "title", className: "sk-hierarchical-refinement-list__header"}, "test title"), React.createElement("div", {"data-qa": "options", className: "sk-hierarchical-refinement-list__root"}, React.createElement("div", {className: "sk-hierarchical-refinement-list__hierarchical-options"}, React.createElement("div", null, React.createElement("div", {className: "sk-hierarchical-refinement-option"}, React.createElement("div", {className: "sk-hierarchical-refinement-option__text"}, "option1"), React.createElement("div", {className: "sk-hierarchical-refinement-option__count"}, "#1"))), React.createElement("div", null, React.createElement("div", {className: "sk-hierarchical-refinement-option"}, React.createElement("div", {className: "sk-hierarchical-refinement-option__text"}, "option2"), React.createElement("div", {className: "sk-hierarchical-refinement-option__count"}, "#2"))))))));
    });
    it("should render 2nd level and have 1 levels selected correctly", function () {
        _this.accessor.state = _this.accessor.state.setValue([
            ["option2"], ["option2child2"]
        ]);
        _this.setResults();
        expect(_this.wrapper.html()).toEqual(TestHelpers_1.jsxToHTML(React.createElement("div", {"data-qa": "filter--testid", className: "sk-hierarchical-refinement-list filter--testid"}, React.createElement("div", {"data-qa": "title", className: "sk-hierarchical-refinement-list__header"}, "test title"), React.createElement("div", {"data-qa": "options", className: "sk-hierarchical-refinement-list__root"}, React.createElement("div", {className: "sk-hierarchical-refinement-list__hierarchical-options"}, React.createElement("div", null, React.createElement("div", {className: "sk-hierarchical-refinement-option"}, React.createElement("div", {className: "sk-hierarchical-refinement-option__text"}, "option1"), React.createElement("div", {className: "sk-hierarchical-refinement-option__count"}, "#1"))), React.createElement("div", null, React.createElement("div", {className: "sk-hierarchical-refinement-option is-selected"}, React.createElement("div", {className: "sk-hierarchical-refinement-option__text"}, "option2"), React.createElement("div", {className: "sk-hierarchical-refinement-option__count"}, "#2")), React.createElement("div", {className: "sk-hierarchical-refinement-list__hierarchical-options"}, React.createElement("div", null, React.createElement("div", {className: "sk-hierarchical-refinement-option"}, React.createElement("div", {className: "sk-hierarchical-refinement-option__text"}, "option2child1"), React.createElement("div", {className: "sk-hierarchical-refinement-option__count"}, "#1"))), React.createElement("div", null, React.createElement("div", {className: "sk-hierarchical-refinement-option is-selected"}, React.createElement("div", {className: "sk-hierarchical-refinement-option__text"}, "option2child2"), React.createElement("div", {className: "sk-hierarchical-refinement-option__count"}, "#1")), React.createElement("div", {className: "sk-hierarchical-refinement-list__hierarchical-options"})))))))));
    });
    it("handle clicking an option", function () {
        _this.setResults();
        var option2 = _this.wrapper
            .find(".sk-hierarchical-refinement-list__hierarchical-options")
            .children().at(1)
            .find(".sk-hierarchical-refinement-option");
        TestHelpers_1.fastClick(option2);
        expect(_this.accessor.state.getValue())
            .toEqual([["option2"]]);
    });
    it("should add disabled state when no results", function () {
        expect(_this.wrapper.html()).toEqual(TestHelpers_1.jsxToHTML(React.createElement("div", {"data-qa": "filter--testid", className: "sk-hierarchical-refinement-list filter--testid is-disabled"}, React.createElement("div", {"data-qa": "title", className: "sk-hierarchical-refinement-list__header"}, "test title"), React.createElement("div", {"data-qa": "options", className: "sk-hierarchical-refinement-list__root"}, React.createElement("div", {className: "sk-hierarchical-refinement-list__hierarchical-options"})))));
    });
});
//# sourceMappingURL=HierarchicalRefinementFilterSpec.js.map