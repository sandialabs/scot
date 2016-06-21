"use strict";
var shouldPureComponentUpdate_1 = require("./shouldPureComponentUpdate");
exports.PureRender = function (target) {
    target.prototype.shouldComponentUpdate = shouldPureComponentUpdate_1.shouldPureComponentUpdate;
};
//# sourceMappingURL=PureRender.js.map