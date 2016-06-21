"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var React = require("react");
var assign = require("lodash/assign");
var MockList = (function (_super) {
    __extends(MockList, _super);
    function MockList(props) {
        _super.call(this, props);
        this.state = {
            items: [
                { key: "a", label: "A", doc_count: 10 },
                { key: "b", label: "B", doc_count: 11, disabled: true },
                { key: "c", title: "C", doc_count: 12 },
                { key: "d", doc_count: 15 },
            ],
            docCount: 10 + 11 + 12 + 15,
            selectedItems: ["a", "c"],
            toggleItem: jasmine.createSpy("toggleItem"),
            setItems: jasmine.createSpy("setItems"),
            translate: function (key) {
                return key + " translated";
            },
            countFormatter: function (count) { return "#" + count; }
        };
    }
    MockList.prototype.render = function () {
        return React.createElement(this.props.listComponent, assign({}, this.state, this.props));
    };
    return MockList;
}(React.Component));
exports.MockList = MockList;
//# sourceMappingURL=MockList.js.map