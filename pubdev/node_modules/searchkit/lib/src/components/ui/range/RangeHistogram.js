"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var React = require("react");
var _1 = require("../../../");
var block = require('bem-cn');
var maxBy = require("lodash/maxBy");
var map = require("lodash/map");
function computeMaxValue(items, field) {
    if (!items || items.length == 0)
        return 0;
    return maxBy(items, field)[field];
}
var RangeHistogram = (function (_super) {
    __extends(RangeHistogram, _super);
    function RangeHistogram() {
        _super.apply(this, arguments);
    }
    RangeHistogram.prototype.render = function () {
        var _a = this.props, mod = _a.mod, className = _a.className, min = _a.min, max = _a.max, minValue = _a.minValue, maxValue = _a.maxValue, _b = _a.items, items = _b === void 0 ? [] : _b;
        var bemBlocks = {
            container: block(mod)
        };
        var maxCount = computeMaxValue(items, "doc_count");
        if (maxCount == 0)
            return null;
        var bars = map(items, function (_a) {
            var key = _a.key, doc_count = _a.doc_count;
            var outOfBounds = (key < minValue || key > maxValue);
            return (React.createElement("div", {className: bemBlocks.container('bar').state({ 'out-of-bounds': outOfBounds }), key: key, style: {
                height: (doc_count / maxCount) * 100 + "%"
            }}));
        });
        return (React.createElement("div", {className: bemBlocks.container().mix(className)}, bars));
    };
    RangeHistogram.defaultProps = {
        mod: 'sk-range-histogram'
    };
    RangeHistogram = __decorate([
        _1.PureRender, 
        __metadata('design:paramtypes', [])
    ], RangeHistogram);
    return RangeHistogram;
}(React.Component));
exports.RangeHistogram = RangeHistogram;
//# sourceMappingURL=RangeHistogram.js.map