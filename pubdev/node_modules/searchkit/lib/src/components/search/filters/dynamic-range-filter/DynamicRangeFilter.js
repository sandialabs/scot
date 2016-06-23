"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var React = require("react");
var core_1 = require("../../../../core");
var ui_1 = require("../../../ui");
var defaults = require("lodash/defaults");
var map = require("lodash/map");
var get = require("lodash/get");
var identity = require("lodash/identity");
var DynamicRangeFilter = (function (_super) {
    __extends(DynamicRangeFilter, _super);
    function DynamicRangeFilter(props) {
        _super.call(this, props);
        this.sliderUpdate = this.sliderUpdate.bind(this);
        this.sliderUpdateAndSearch = this.sliderUpdateAndSearch.bind(this);
    }
    DynamicRangeFilter.prototype.defineAccessor = function () {
        var _a = this.props, id = _a.id, title = _a.title, field = _a.field, fieldOptions = _a.fieldOptions;
        return new core_1.DynamicRangeAccessor(id, {
            id: id, title: title, field: field, fieldOptions: fieldOptions
        });
    };
    DynamicRangeFilter.prototype.defineBEMBlocks = function () {
        var block = this.props.mod || "sk-dynamic-range-filter";
        return {
            container: block,
            labels: block + "-value-labels"
        };
    };
    DynamicRangeFilter.prototype.getMinMax = function () {
        return {
            min: this.accessor.getStat("min") || 0,
            max: this.accessor.getStat("max") || 0
        };
    };
    DynamicRangeFilter.prototype.sliderUpdate = function (newValues) {
        var _a = this.getMinMax(), min = _a.min, max = _a.max;
        if ((newValues.min == min) && (newValues.max == max)) {
            this.accessor.state = this.accessor.state.clear();
        }
        else {
            this.accessor.state = this.accessor.state.setValue(newValues);
        }
        this.forceUpdate();
    };
    DynamicRangeFilter.prototype.sliderUpdateAndSearch = function (newValues) {
        this.sliderUpdate(newValues);
        this.searchkit.performSearch();
    };
    DynamicRangeFilter.prototype.render = function () {
        var _a = this.props, id = _a.id, title = _a.title, containerComponent = _a.containerComponent;
        return core_1.renderComponent(containerComponent, {
            title: title,
            className: id ? "filter--" + id : undefined,
            disabled: this.accessor.isDisabled()
        }, this.renderRangeComponent(this.props.rangeComponent));
    };
    DynamicRangeFilter.prototype.renderRangeComponent = function (component) {
        var _a = this.getMinMax(), min = _a.min, max = _a.max;
        var rangeFormatter = this.props.rangeFormatter;
        var state = this.accessor.state.getValue();
        return core_1.renderComponent(component, {
            min: min, max: max,
            minValue: Number(get(state, "min", min)),
            maxValue: Number(get(state, "max", max)),
            rangeFormatter: rangeFormatter,
            onChange: this.sliderUpdate,
            onFinished: this.sliderUpdateAndSearch
        });
    };
    DynamicRangeFilter.propTypes = defaults({
        field: React.PropTypes.string.isRequired,
        title: React.PropTypes.string.isRequired,
        id: React.PropTypes.string.isRequired,
        containerComponent: core_1.RenderComponentPropType,
        rangeComponent: core_1.RenderComponentPropType,
        rangeFormatter: React.PropTypes.func,
        fieldOptions: React.PropTypes.shape({
            type: React.PropTypes.oneOf(["embedded", "nested", "children"]).isRequired,
            options: React.PropTypes.object
        }),
    }, core_1.SearchkitComponent.propTypes);
    DynamicRangeFilter.defaultProps = {
        containerComponent: ui_1.Panel,
        rangeComponent: ui_1.RangeSlider,
        rangeFormatter: identity
    };
    return DynamicRangeFilter;
}(core_1.SearchkitComponent));
exports.DynamicRangeFilter = DynamicRangeFilter;
//# sourceMappingURL=DynamicRangeFilter.js.map