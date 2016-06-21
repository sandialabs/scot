"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var StatefulAccessor_1 = require("./StatefulAccessor");
var state_1 = require("../state");
var PageSizeAccessor = (function (_super) {
    __extends(PageSizeAccessor, _super);
    function PageSizeAccessor(defaultSize) {
        _super.call(this, "size");
        this.defaultSize = defaultSize;
        this.state = new state_1.ValueState();
    }
    PageSizeAccessor.prototype.setSize = function (size) {
        if (this.defaultSize == size) {
            this.state = this.state.clear();
        }
        else {
            this.state = this.state.setValue(size);
        }
    };
    PageSizeAccessor.prototype.getSize = function () {
        return Number(this.state.getValue() || this.defaultSize);
    };
    PageSizeAccessor.prototype.buildSharedQuery = function (query) {
        return query.setSize(this.getSize());
    };
    return PageSizeAccessor;
}(StatefulAccessor_1.StatefulAccessor));
exports.PageSizeAccessor = PageSizeAccessor;
//# sourceMappingURL=PageSizeAccessor.js.map