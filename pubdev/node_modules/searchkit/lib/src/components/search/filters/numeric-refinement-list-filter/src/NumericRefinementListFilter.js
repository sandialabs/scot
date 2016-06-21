"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var React = require("react");
var core_1 = require("../../../../../core");
var ui_1 = require("../../../../ui");
var defaults = require("lodash/defaults");
var map = require("lodash/map");
var NumericRefinementListFilter = (function (_super) {
    __extends(NumericRefinementListFilter, _super);
    function NumericRefinementListFilter(props) {
        _super.call(this, props);
        this.toggleItem = this.toggleItem.bind(this);
        this.setItems = this.setItems.bind(this);
    }
    NumericRefinementListFilter.prototype.defineAccessor = function () {
        var _a = this.props, id = _a.id, field = _a.field, options = _a.options, title = _a.title, multiselect = _a.multiselect, fieldOptions = _a.fieldOptions;
        return new core_1.NumericOptionsAccessor(id, {
            id: id, field: field, options: options, title: title, multiselect: multiselect, fieldOptions: fieldOptions
        });
    };
    NumericRefinementListFilter.prototype.toggleItem = function (key) {
        this.accessor.toggleOption(key);
    };
    NumericRefinementListFilter.prototype.setItems = function (keys) {
        this.accessor.setOptions(keys);
    };
    NumericRefinementListFilter.prototype.getSelectedItems = function () {
        var selectedOptions = this.accessor.getSelectedOrDefaultOptions() || [];
        return map(selectedOptions, "title");
    };
    NumericRefinementListFilter.prototype.hasOptions = function () {
        return this.accessor.getBuckets().length != 0;
    };
    NumericRefinementListFilter.prototype.render = function () {
        var _a = this.props, listComponent = _a.listComponent, containerComponent = _a.containerComponent, itemComponent = _a.itemComponent, showCount = _a.showCount, title = _a.title, id = _a.id, mod = _a.mod, className = _a.className, countFormatter = _a.countFormatter;
        return core_1.renderComponent(containerComponent, {
            title: title,
            className: id ? "filter--" + id : undefined,
            disabled: !this.hasOptions()
        }, core_1.renderComponent(listComponent, {
            mod: mod, className: className,
            items: this.accessor.getBuckets(),
            itemComponent: itemComponent,
            selectedItems: this.getSelectedItems(),
            toggleItem: this.toggleItem,
            setItems: this.setItems,
            docCount: this.accessor.getDocCount(),
            showCount: showCount,
            translate: this.translate,
            countFormatter: countFormatter
        }));
    };
    NumericRefinementListFilter.propTypes = defaults({
        containerComponent: core_1.RenderComponentPropType,
        listComponent: core_1.RenderComponentPropType,
        itemComponent: core_1.RenderComponentPropType,
        field: React.PropTypes.string.isRequired,
        title: React.PropTypes.string.isRequired,
        id: React.PropTypes.string.isRequired,
        multiselect: React.PropTypes.bool,
        showCount: React.PropTypes.bool,
        options: React.PropTypes.arrayOf(React.PropTypes.shape({
            title: React.PropTypes.string.isRequired,
            from: React.PropTypes.number,
            to: React.PropTypes.number,
            key: React.PropTypes.string
        })),
        fieldOptions: React.PropTypes.shape({
            type: React.PropTypes.oneOf(["embedded", "nested", "children"]).isRequired,
            options: React.PropTypes.object
        }),
        countFormatter: React.PropTypes.func
    }, core_1.SearchkitComponent.propTypes);
    NumericRefinementListFilter.defaultProps = {
        listComponent: ui_1.ItemList,
        containerComponent: ui_1.Panel,
        multiselect: false,
        showCount: true
    };
    return NumericRefinementListFilter;
}(core_1.SearchkitComponent));
exports.NumericRefinementListFilter = NumericRefinementListFilter;
//# sourceMappingURL=NumericRefinementListFilter.js.map