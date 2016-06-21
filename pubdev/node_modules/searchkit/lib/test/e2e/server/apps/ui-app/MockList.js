"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var React = require("react");
var _a = require("../../../../../src"), Panel = _a.Panel, renderComponent = _a.renderComponent;
var _ = require("lodash");
var MockList = (function (_super) {
    __extends(MockList, _super);
    function MockList(props) {
        _super.call(this, props);
        var self = this;
        this.state = {
            items: [
                { key: "a", label: "A", doc_count: 10 },
                { key: "b", label: "B", doc_count: 11 },
                { key: "c", title: "C", doc_count: 12 },
                { key: "d", doc_count: 15 },
            ],
            selectedItems: ["a", "c"],
            toggleItem: function (key) {
                if (_.includes(self.state.selectedItems, key)) {
                    self.setState({ selectedItems: _.without(self.state.selectedItems, key) });
                }
                else {
                    self.setState({ selectedItems: self.state.selectedItems.concat([key]) });
                }
            },
            setItems: function (items) {
                self.setState({ selectedItems: items });
            },
            translate: function (key) {
                return key + "!";
            }
        };
    }
    MockList.prototype.render = function () {
        return (React.createElement(Panel, {title: this.props.title}, renderComponent(this.props.listComponent, _.assign({}, this.state, this.props))));
    };
    return MockList;
}(React.Component));
exports.MockList = MockList;
//# sourceMappingURL=MockList.js.map