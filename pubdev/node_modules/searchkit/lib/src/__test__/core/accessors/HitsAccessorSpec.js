"use strict";
var _this = this;
var _1 = require("../../../");
describe("HitsAccessor", function () {
    beforeEach(function () {
        _this.searchkit = _1.SearchkitManager.mock();
        _this.accessor = new _1.HitsAccessor({ scrollTo: "#scrolltome" });
        _this.searchkit.setResults({
            hits: {
                hits: [{ _id: 1, title: 1 }, { _id: 2, title: 2 }],
                total: 2
            }
        });
        _this.searchkit.addAccessor(_this.accessor);
        _this.scroll = { scrollTop: 99 };
        spyOn(document, "querySelector").and.returnValue(_this.scroll);
    });
    it("constructor()()", function () {
        expect(_this.accessor.options).toEqual({
            scrollTo: "#scrolltome"
        });
    });
    it("setResults()", function () {
        _this.searchkit.setResults({
            hits: {
                hits: [{ _id: 1, title: 1 }, { _id: 2, title: 2 }],
                total: 2
            }
        });
        expect(document.querySelector).not.toHaveBeenCalled();
        _this.searchkit.setResults({
            hits: {
                hits: [{ _id: 1, title: 1 }, { _id: 2, title: 2 }, { _id: 3 }],
                total: 3
            }
        });
        expect(document.querySelector).toHaveBeenCalledWith("#scrolltome");
        expect(_this.scroll.scrollTop).toBe(0);
    });
    it("getScrollSelector()", function () {
        expect(_this.accessor.getScrollSelector()).toBe("#scrolltome");
        _this.accessor.options.scrollTo = true;
        expect(_this.accessor.getScrollSelector()).toBe("body");
    });
});
//# sourceMappingURL=HitsAccessorSpec.js.map