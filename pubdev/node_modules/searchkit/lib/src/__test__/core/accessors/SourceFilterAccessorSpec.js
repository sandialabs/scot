"use strict";
var _this = this;
var _1 = require("../../../");
describe("SourceFilterAccessor", function () {
    beforeEach(function () {
        _this.accessor = new _1.SourceFilterAccessor(["title.*"]);
        _this.query = new _1.ImmutableQuery();
    });
    it("constructor()", function () {
        expect(_this.accessor.source).toEqual(["title.*"]);
    });
    it("buildSharedQuery()", function () {
        var query = _this.accessor.buildSharedQuery(_this.query);
        expect(query).not.toBe(_this.query);
        expect(query.query._source).toEqual(["title.*"]);
    });
});
//# sourceMappingURL=SourceFilterAccessorSpec.js.map