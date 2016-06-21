"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var _1 = require("../../../../");
describe("PureRenderComponent", function () {
    it("should inherit shouldPureComponentUpdate", function () {
        var MyComponent = (function (_super) {
            __extends(MyComponent, _super);
            function MyComponent() {
                _super.apply(this, arguments);
            }
            return MyComponent;
        }(_1.PureRenderComponent));
        var comp = new MyComponent();
        expect(comp.shouldComponentUpdate).toBe(_1.shouldPureComponentUpdate);
        comp.props = { p: 1 };
        comp.state = { s: 1 };
        expect(comp.shouldComponentUpdate({ p: 1 }, { s: 1 })).toBe(false);
        expect(comp.shouldComponentUpdate({ p: 2 }, { s: 1 })).toBe(true);
    });
});
//# sourceMappingURL=PureRenderComponentSpec.js.map