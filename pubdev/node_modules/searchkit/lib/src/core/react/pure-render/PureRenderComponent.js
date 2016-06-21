"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var React = require("react");
var shouldPureComponentUpdate_1 = require("./shouldPureComponentUpdate");
var PureRenderComponent = (function (_super) {
    __extends(PureRenderComponent, _super);
    function PureRenderComponent() {
        _super.apply(this, arguments);
        this.shouldComponentUpdate = shouldPureComponentUpdate_1.shouldPureComponentUpdate;
    }
    return PureRenderComponent;
}(React.Component));
exports.PureRenderComponent = PureRenderComponent;
//# sourceMappingURL=PureRenderComponent.js.map