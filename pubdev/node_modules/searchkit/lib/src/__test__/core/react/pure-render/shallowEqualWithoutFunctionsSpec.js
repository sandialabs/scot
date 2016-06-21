"use strict";
var _1 = require("../../../../");
describe("shallowEqualWithoutFunctions", function () {
    it("basics test", function () {
        var a = { a: 1 };
        var b = { a: 1 };
        expect(_1.shallowEqualWithoutFunctions(a, b)).toBe(true);
        expect(_1.shallowEqualWithoutFunctions(a, {})).toBe(false);
        expect(_1.shallowEqualWithoutFunctions(1, 1)).toBe(true);
        expect(_1.shallowEqualWithoutFunctions(1, "1")).toBe(false);
    });
    it("ignores functions", function () {
        var a = { a: 1, fn: function () { } };
        var b = { a: 1, fn: function () { } };
        expect(_1.shallowEqualWithoutFunctions(a, b)).toBe(true);
    });
    it("doesn't ignore functions", function () {
        var a = { a: 1, itemComponent: function () { } };
        var b = { a: 1, itemComponent: function () { } };
        expect(_1.shallowEqualWithoutFunctions(a, b)).toBe(false);
        var component = function () { };
        var c = { a: 1, component: component };
        var d = { a: 1, component: component };
        expect(_1.shallowEqualWithoutFunctions(c, d)).toBe(true);
    });
});
//# sourceMappingURL=shallowEqualWithoutFunctionsSpec.js.map