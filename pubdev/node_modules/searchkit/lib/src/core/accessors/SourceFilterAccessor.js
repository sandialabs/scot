"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var Accessor_1 = require("./Accessor");
var SourceFilterAccessor = (function (_super) {
    __extends(SourceFilterAccessor, _super);
    function SourceFilterAccessor(source) {
        _super.call(this);
        this.source = source;
    }
    SourceFilterAccessor.prototype.buildSharedQuery = function (query) {
        return query.setSource(this.source);
    };
    return SourceFilterAccessor;
}(Accessor_1.Accessor));
exports.SourceFilterAccessor = SourceFilterAccessor;
//# sourceMappingURL=SourceFilterAccessor.js.map