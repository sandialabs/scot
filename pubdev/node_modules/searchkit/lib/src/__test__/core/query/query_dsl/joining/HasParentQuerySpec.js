"use strict";
var _1 = require("../../../../../");
it("HasParentQuery", function () {
    expect(_1.HasParentQuery("folder", "somequery")).toEqual({
        has_parent: {
            parent_type: "folder",
            query: "somequery"
        }
    });
    expect(_1.HasParentQuery("folder", "somequery", {
        score_mode: "sum", invalid: true, inner_hits: {}
    })).toEqual({
        has_parent: {
            parent_type: "folder",
            query: "somequery",
            score_mode: "sum",
            inner_hits: {}
        }
    });
});
//# sourceMappingURL=HasParentQuerySpec.js.map