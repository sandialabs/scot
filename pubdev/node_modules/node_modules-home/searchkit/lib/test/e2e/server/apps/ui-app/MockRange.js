"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var React = require("react");
var src_1 = require("../../../../../src");
var MockRange = (function (_super) {
    __extends(MockRange, _super);
    function MockRange(props) {
        _super.call(this, props);
        var self = this;
        this.state = {
            items: [
                { key: 0, doc_count: 0 },
                { key: 1, doc_count: 4 },
                { key: 2, doc_count: 5 },
                { key: 3, doc_count: 6 },
                { key: 4, doc_count: 7 },
                { key: 5, doc_count: 8 },
                { key: 6, doc_count: 0 },
                { key: 7, doc_count: 10 },
                { key: 8, doc_count: 4 },
                { key: 9, doc_count: 2 },
                { key: 10, doc_count: 0 },
            ],
            min: 0, max: 10,
            minValue: 2, maxValue: 5,
            onChange: function (_a) {
                var min = _a.min, max = _a.max;
                self.setState({
                    minValue: min, maxValue: max
                });
            },
            onFinished: function (_a) {
                var min = _a.min, max = _a.max;
                self.setState({
                    minValue: min, maxValue: max
                });
                console.log("Set range to ", min, ", ", max);
            }
        };
    }
    MockRange.prototype.render = function () {
        var _a = this.props, title = _a.title, containerComponent = _a.containerComponent, rangeComponent = _a.rangeComponent;
        return src_1.renderComponent(containerComponent, { title: title }, src_1.renderComponent(rangeComponent, this.state));
    };
    MockRange.defaultProps = {
        rangeComponent: src_1.RangeSlider,
        containerComponent: src_1.Panel,
    };
    MockRange.propTypes = {
        containerComponent: src_1.RenderComponentPropType,
        rangeComponent: src_1.RenderComponentPropType,
    };
    return MockRange;
}(React.Component));
exports.MockRange = MockRange;
//# sourceMappingURL=MockRange.js.map