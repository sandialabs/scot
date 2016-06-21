"use strict";
var _this = this;
var React = require("react");
var enzyme_1 = require("enzyme");
var Select_1 = require("./Select");
var MockList_1 = require("./MockList");
var TestHelpers_1 = require("../../__test__/TestHelpers");
describe("Select", function () {
    beforeEach(function () {
        _this.wrapper = enzyme_1.mount(React.createElement(MockList_1.MockList, {listComponent: Select_1.Select}));
    });
    it("should render and behave correctly", function () {
        expect(_this.wrapper.html()).toEqual(TestHelpers_1.jsxToHTML(React.createElement("div", {className: "sk-select"}, React.createElement("select", {defaultValue: "a"}, React.createElement("option", {value: "a"}, "A translated (#10)"), React.createElement("option", {value: "b", disabled: true}, "B translated (#11)"), React.createElement("option", {value: "c"}, "C translated (#12)"), React.createElement("option", {value: "d"}, "d translated (#15)")))));
        var optionC = _this.wrapper.find("select").children().at(2);
        optionC.simulate("change");
        expect(_this.wrapper.node.state.setItems).toHaveBeenCalledWith(["c"]);
        _this.wrapper.setProps({ disabled: true });
        expect(_this.wrapper.find(".sk-select").hasClass("is-disabled")).toBe(true);
    });
    it("mod + classname can be updated", function () {
        _this.wrapper.setProps({
            mod: "sk-other-class", className: "my-custom-class"
        });
        expect(_this.wrapper.find(".sk-other-class").hasClass("my-custom-class")).toBe(true);
    });
});
//# sourceMappingURL=Select.unit.js.map