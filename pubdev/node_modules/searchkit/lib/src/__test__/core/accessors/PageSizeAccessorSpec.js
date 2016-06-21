"use strict";
var _this = this;
var _1 = require("../../../");
describe("PageSizeAccessor", function () {
    beforeEach(function () {
        _this.accessor = new _1.PageSizeAccessor(10);
        _this.query = new _1.ImmutableQuery();
    });
    it("constructor()", function () {
        expect(_this.accessor.defaultSize).toBe(10);
        expect(_this.accessor.state.getValue()).toBe(null);
    });
    it("buildSharedQuery()", function () {
        var query = _this.accessor.buildSharedQuery(_this.query);
        expect(query).not.toBe(_this.query);
        expect(query.getSize()).toBe(10);
        _this.accessor.setSize(20);
        query = _this.accessor.buildSharedQuery(_this.query);
        expect(query.getSize()).toBe(20);
    });
    it("setSize()", function () {
        _this.accessor.setSize(20);
        expect(_this.accessor.getSize()).toBe(20);
        expect(_this.accessor.state.getValue()).toBe(20);
        _this.accessor.setSize(10);
        expect(_this.accessor.getSize()).toBe(10);
        expect(_this.accessor.state.getValue()).toBe(null);
    });
});
//# sourceMappingURL=PageSizeAccessorSpec.js.map