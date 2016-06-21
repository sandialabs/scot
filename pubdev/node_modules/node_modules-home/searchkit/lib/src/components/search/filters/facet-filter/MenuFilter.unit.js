"use strict";
var _this = this;
var React = require("react");
var enzyme_1 = require("enzyme");
var TestHelpers_1 = require("../../../__test__/TestHelpers");
var MenuFilter_tsx_1 = require("./MenuFilter.tsx");
var core_1 = require("../../../../core");
var ui_1 = require("../../../ui");
var bem = require("bem-cn");
var _ = require("lodash");
describe("MenuFilter", function () {
    beforeEach(function () {
        core_1.Utils.guidCounter = 0;
        _this.searchkit = core_1.SearchkitManager.mock();
        spyOn(_this.searchkit, "performSearch");
        _this.wrapper = enzyme_1.mount(React.createElement(MenuFilter_tsx_1.MenuFilter, {searchkit: _this.searchkit, translations: { "Red": "Red Translated" }, field: "color", title: "Color", orderKey: "_term", orderDirection: "asc", include: "title", exclude: ["n/a"], id: "color", size: 10}));
        _this.getOptionAt = function (at) {
            return _this.wrapper.find(".sk-item-list")
                .children().at(at);
        };
        _this.accessor = _this.searchkit.accessors.accessors[0];
        _this.searchkit.setResults({
            aggregations: {
                color1: {
                    color: {
                        buckets: [
                            { key: "Red", doc_count: 10 },
                            { key: "Blue", doc_count: 11 },
                            { key: "Green", doc_count: 12 }
                        ]
                    },
                    doc_count: 33
                }
            }
        });
    });
    it("expect accessor options to be correct", function () {
        expect(_this.wrapper.node.props.listComponent).toBe(ui_1.ItemList);
        expect(_this.accessor.options).toEqual(jasmine.objectContaining({
            id: "color", field: "color", title: "Color", operator: "OR",
            translations: { "Red": "Red Translated" },
            size: 10, facetsPerPage: 50, orderKey: "_term",
            orderDirection: "asc", include: "title", exclude: ["n/a"],
            "fieldOptions": {
                type: "embedded",
                field: "color"
            }
        }));
    });
    it("getSelectedItems", function () {
        _this.accessor.state = new core_1.ArrayState([]);
        expect(_this.wrapper.node.getSelectedItems())
            .toEqual(['$all']);
        _this.accessor.state = new core_1.ArrayState([false]);
        expect(_this.wrapper.node.getSelectedItems())
            .toEqual([false]);
        _this.accessor.state = new core_1.ArrayState(["foo", "bar"]);
        expect(_this.wrapper.node.getSelectedItems())
            .toEqual(["foo"]);
    });
    it("should render correctly", function () {
        expect(_this.wrapper.html()).toEqual(TestHelpers_1.jsxToHTML(React.createElement("div", {className: "sk-panel filter--color"}, React.createElement("div", {className: "sk-panel__header"}, "Color"), React.createElement("div", {className: "sk-panel__content"}, React.createElement("div", {"data-qa": "options", className: "sk-item-list"}, React.createElement("div", {className: "sk-item-list-option sk-item-list__item is-active", "data-qa": "option", "data-key": "$all"}, React.createElement("div", {"data-qa": "label", className: "sk-item-list-option__text"}, "All"), React.createElement("div", {"data-qa": "count", className: "sk-item-list-option__count"}, "33")), React.createElement("div", {className: "sk-item-list-option sk-item-list__item", "data-qa": "option", "data-key": "Red"}, React.createElement("div", {"data-qa": "label", className: "sk-item-list-option__text"}, "Red Translated"), React.createElement("div", {"data-qa": "count", className: "sk-item-list-option__count"}, "10")), React.createElement("div", {className: "sk-item-list-option sk-item-list__item", "data-qa": "option", "data-key": "Blue"}, React.createElement("div", {"data-qa": "label", className: "sk-item-list-option__text"}, "Blue"), React.createElement("div", {"data-qa": "count", className: "sk-item-list-option__count"}, "11")), React.createElement("div", {className: "sk-item-list-option sk-item-list__item", "data-qa": "option", "data-key": "Green"}, React.createElement("div", {"data-qa": "label", className: "sk-item-list-option__text"}, "Green"), React.createElement("div", {"data-qa": "count", className: "sk-item-list-option__count"}, "12")))))));
    });
    it("should handle selection correctly", function () {
        var all = _this.getOptionAt(0);
        var blue = _this.getOptionAt(2);
        var green = _this.getOptionAt(3);
        TestHelpers_1.fastClick(blue);
        expect(_this.accessor.state.getValue()).toEqual(["Blue"]);
        TestHelpers_1.fastClick(green);
        expect(_this.accessor.state.getValue()).toEqual(["Green"]);
        expect(_this.searchkit.performSearch).toHaveBeenCalled();
        //should clear if button clicked
        TestHelpers_1.fastClick(green);
        expect(_this.accessor.state.getValue()).toEqual([]);
        TestHelpers_1.fastClick(blue);
        expect(_this.accessor.state.getValue()).toEqual(["Blue"]);
        TestHelpers_1.fastClick(all);
        expect(_this.accessor.state.getValue()).toEqual([]);
        TestHelpers_1.fastClick(all);
        expect(_this.accessor.state.getValue()).toEqual([]);
    });
});
//# sourceMappingURL=MenuFilter.unit.js.map