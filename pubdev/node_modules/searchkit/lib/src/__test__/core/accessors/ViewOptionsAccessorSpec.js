"use strict";
var _this = this;
var _1 = require("../../../");
describe("ViewOptionsAccessor", function () {
    beforeEach(function () {
        _this.searchkit = _1.SearchkitManager.mock();
        _this.accessor = new _1.ViewOptionsAccessor("view", [
            { key: "grid" },
            { key: "list", defaultOption: true }
        ]);
        _this.searchkit.addAccessor(_this.accessor);
        spyOn(_this.searchkit, "performSearch");
    });
    it("should set view", function () {
        _this.accessor.setView("grid");
        expect(_this.accessor.state.getValue()).toBe("grid");
        expect(_this.searchkit.performSearch).toHaveBeenCalledWith(false, false);
    });
    it("should set view - default option", function () {
        _this.accessor.setView("list");
        expect(_this.accessor.state.getValue()).toBe(null);
        expect(_this.searchkit.performSearch).toHaveBeenCalledWith(false, false);
    });
});
//# sourceMappingURL=ViewOptionsAccessorSpec.js.map