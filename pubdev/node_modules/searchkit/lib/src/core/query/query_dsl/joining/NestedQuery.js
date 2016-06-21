"use strict";
var assign = require("lodash/assign");
var pick = require("lodash/pick");
var allowedOptions = ["score_mode", "inner_hits"];
function NestedQuery(path, filter, options) {
    if (options === void 0) { options = {}; }
    return {
        nested: assign({
            path: path, filter: filter
        }, pick(options, allowedOptions))
    };
}
exports.NestedQuery = NestedQuery;
//# sourceMappingURL=NestedQuery.js.map