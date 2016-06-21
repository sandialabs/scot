"use strict";
var _1 = require("../../../../../");
it("NestedQuery", function () {
    expect(_1.NestedQuery("taxonomy", "somequery")).toEqual({
        nested: {
            path: "taxonomy",
            filter: "somequery"
        }
    });
    expect(_1.NestedQuery("taxonomy", "somequery", { score_mode: "sum", invalid: "foo", inner_hits: {} })).toEqual({
        nested: {
            path: "taxonomy",
            filter: "somequery",
            score_mode: "sum",
            inner_hits: {}
        }
    });
});
//# sourceMappingURL=NestedQuerySpec.js.map