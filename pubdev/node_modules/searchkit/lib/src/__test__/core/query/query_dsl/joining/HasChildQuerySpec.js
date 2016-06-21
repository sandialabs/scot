"use strict";
var _1 = require("../../../../../");
it("HasChildQuery", function () {
    expect(_1.HasChildQuery("tags", "somequery")).toEqual({
        has_child: {
            type: "tags",
            query: "somequery"
        }
    });
    expect(_1.HasChildQuery("tags", "somequery", {
        score_mode: "sum", invalid: true, inner_hits: {},
        max_children: 10, min_children: 1
    })).toEqual({
        has_child: {
            type: "tags",
            query: "somequery",
            score_mode: "sum",
            inner_hits: {},
            max_children: 10,
            min_children: 1
        }
    });
});
//# sourceMappingURL=HasChildQuerySpec.js.map