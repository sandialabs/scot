"use strict";
var _1 = require("../../../../../");
describe("QueryString", function () {
    it("empty string", function () {
        expect(_1.QueryString("")).toBe(undefined);
    });
    it("with string + options", function () {
        var qs = _1.QueryString("foo", {
            analyzer: "english",
            fields: ["title"],
            use_dis_max: true
        });
        expect(qs).toEqual({
            query_string: {
                query: "foo",
                analyzer: "english",
                fields: ["title"],
                use_dis_max: true
            }
        });
    });
});
//# sourceMappingURL=QueryStringSpec.js.map