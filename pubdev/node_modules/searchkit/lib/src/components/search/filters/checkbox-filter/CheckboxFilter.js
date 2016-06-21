"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var React = require("react");
var core_1 = require("../../../../core");
var ui_1 = require("../../../ui");
var defaults = require('lodash/defaults');
var map = require('lodash/map');
var CheckboxFilter = (function (_super) {
    __extends(CheckboxFilter, _super);
    function CheckboxFilter(props) {
        _super.call(this, props);
        this.toggleFilter = this.toggleFilter.bind(this);
    }
    CheckboxFilter.prototype.defineAccessor = function () {
        var _a = this.props, id = _a.id, title = _a.title, translations = _a.translations, label = _a.label, filter = _a.filter;
        return new core_1.CheckboxFilterAccessor(id, {
            id: id, title: title, label: label, translations: translations, filter: filter
        });
    };
    CheckboxFilter.prototype.toggleFilter = function (key) {
        this.accessor.state = this.accessor.state.create(!this.accessor.state.getValue());
        this.searchkit.performSearch();
    };
    CheckboxFilter.prototype.setFilters = function (keys) {
        this.accessor.state = this.accessor.state.setValue(keys.length > 0);
        this.searchkit.performSearch();
    };
    CheckboxFilter.prototype.getSelectedItems = function () {
        if (this.accessor.state.getValue()) {
            return [this.props.label];
        }
        else {
            return [];
        }
    };
    CheckboxFilter.prototype.render = function () {
        var _a = this.props, listComponent = _a.listComponent, containerComponent = _a.containerComponent, showCount = _a.showCount, title = _a.title, id = _a.id, label = _a.label;
        var disabled = (this.searchkit.getHitsCount() == 0) && !this.accessor.state.getValue();
        return core_1.renderComponent(containerComponent, {
            title: title,
            className: id ? "filter--" + id : undefined,
            disabled: disabled
        }, core_1.renderComponent(listComponent, {
            items: [{ key: label, doc_count: this.accessor.getDocCount() }],
            selectedItems: this.getSelectedItems(),
            toggleItem: this.toggleFilter,
            setItems: this.setFilters.bind(this),
            showCount: showCount
        }));
    };
    CheckboxFilter.propTypes = defaults({
        id: React.PropTypes.string.isRequired,
        title: React.PropTypes.string.isRequired,
        label: React.PropTypes.string.isRequired,
        filter: React.PropTypes.object.isRequired,
        translations: core_1.SearchkitComponent.translationsPropType(core_1.CheckboxFilterAccessor.translations),
        showCount: React.PropTypes.bool,
    }, core_1.SearchkitComponent.propTypes);
    CheckboxFilter.defaultProps = {
        listComponent: ui_1.CheckboxItemList,
        containerComponent: ui_1.Panel,
        collapsable: false,
        showCount: true
    };
    return CheckboxFilter;
}(core_1.SearchkitComponent));
exports.CheckboxFilter = CheckboxFilter;
//# sourceMappingURL=CheckboxFilter.js.map