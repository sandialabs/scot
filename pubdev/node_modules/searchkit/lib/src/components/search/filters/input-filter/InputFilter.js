"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var React = require("react");
var core_1 = require("../../../../core");
var SearchBox_1 = require("../../search-box/SearchBox");
var ui_1 = require("../../../ui");
var defaults = require('lodash/defaults');
var throttle = require("lodash/throttle");
var assign = require("lodash/assign");
var isUndefined = require("lodash/isUndefined");
var InputFilter = (function (_super) {
    __extends(InputFilter, _super);
    function InputFilter(props) {
        var _this = this;
        _super.call(this, props);
        this.translations = SearchBox_1.SearchBox.translations;
        this.state = {
            focused: false,
            input: undefined
        };
        this.lastSearchMs = 0;
        this.onClear = this.onClear.bind(this);
        this.throttledSearch = throttle(function () {
            _this.searchQuery(_this.accessor.getQueryString());
        }, props.searchThrottleTime);
    }
    InputFilter.prototype.componentWillMount = function () {
        _super.prototype.componentWillMount.call(this);
    };
    InputFilter.prototype.defineBEMBlocks = function () {
        return { container: this.props.mod };
    };
    InputFilter.prototype.defineAccessor = function () {
        var _this = this;
        var _a = this.props, id = _a.id, title = _a.title, prefixQueryFields = _a.prefixQueryFields, queryFields = _a.queryFields, queryBuilder = _a.queryBuilder, searchOnChange = _a.searchOnChange, queryOptions = _a.queryOptions, prefixQueryOptions = _a.prefixQueryOptions;
        return new core_1.QueryAccessor(id, {
            title: title,
            addToFilters: true,
            queryFields: queryFields || ["_all"],
            prefixQueryFields: prefixQueryFields,
            queryOptions: assign({}, queryOptions),
            prefixQueryOptions: assign({}, prefixQueryOptions),
            queryBuilder: queryBuilder,
            onQueryStateChange: function () {
                if (!_this.unmounted && _this.state.input) {
                    _this.setState({ input: undefined });
                }
            }
        });
    };
    InputFilter.prototype.onSubmit = function (event) {
        event.preventDefault();
        this.searchQuery(this.getValue());
    };
    InputFilter.prototype.searchQuery = function (query) {
        var shouldResetOtherState = false;
        this.accessor.setQueryString(query, shouldResetOtherState);
        var now = +new Date;
        var newSearch = now - this.lastSearchMs <= 2000;
        this.lastSearchMs = now;
        this.searchkit.performSearch(newSearch);
    };
    InputFilter.prototype.getValue = function () {
        var input = this.state.input;
        if (isUndefined(input)) {
            return this.getAccessorValue();
        }
        else {
            return input;
        }
    };
    InputFilter.prototype.getAccessorValue = function () {
        return (this.accessor.state.getValue() || "") + "";
    };
    InputFilter.prototype.onChange = function (e) {
        var query = e.target.value;
        if (this.props.searchOnChange) {
            this.accessor.setQueryString(query);
            this.throttledSearch();
            this.forceUpdate();
        }
        else {
            this.setState({ input: query });
        }
    };
    InputFilter.prototype.onClear = function () {
        this.accessor.state = this.accessor.state.clear();
        this.searchkit.performSearch();
        this.setState({ input: undefined });
    };
    InputFilter.prototype.setFocusState = function (focused) {
        if (!focused) {
            var input = this.state.input;
            if (this.props.blurAction == "search"
                && !isUndefined(input)
                && input != this.getAccessorValue()) {
                this.searchQuery(input);
            }
            this.setState({
                focused: focused,
                input: undefined // Flush (should use accessor's state now)
            });
        }
        else {
            this.setState({ focused: focused });
        }
    };
    InputFilter.prototype.render = function () {
        var _a = this.props, containerComponent = _a.containerComponent, title = _a.title, id = _a.id;
        var block = this.bemBlocks.container;
        var value = this.getValue();
        return core_1.renderComponent(containerComponent, {
            title: title,
            className: id ? "filter--" + id : undefined,
            disabled: (this.searchkit.getHitsCount() == 0) && (this.getAccessorValue() == "")
        }, React.createElement("div", {className: block().state({ focused: this.state.focused })}, React.createElement("form", {onSubmit: this.onSubmit.bind(this)}, React.createElement("div", {className: block("icon")}), React.createElement("input", {type: "text", "data-qa": "input-filter", className: block("text"), placeholder: this.props.placeholder || this.translate("searchbox.placeholder"), value: value, onFocus: this.setFocusState.bind(this, true), onBlur: this.setFocusState.bind(this, false), ref: "queryField", autoFocus: false, onInput: this.onChange.bind(this)}), React.createElement("input", {type: "submit", value: "search", className: block("action"), "data-qa": "submit"}), React.createElement("div", {"data-qa": "remove", onClick: this.onClear, className: block("remove").state({ hidden: value == "" })}))));
    };
    InputFilter.translations = {
        "searchbox.placeholder": "Search"
    };
    InputFilter.defaultProps = {
        containerComponent: ui_1.Panel,
        collapsable: false,
        mod: "sk-input-filter",
        searchThrottleTime: 200,
        blurAction: "search"
    };
    InputFilter.propTypes = defaults({
        id: React.PropTypes.string.isRequired,
        title: React.PropTypes.string.isRequired,
        searchOnChange: React.PropTypes.bool,
        searchThrottleTime: React.PropTypes.number,
        queryBuilder: React.PropTypes.func,
        queryFields: React.PropTypes.arrayOf(React.PropTypes.string),
        queryOptions: React.PropTypes.object,
        prefixQueryFields: React.PropTypes.arrayOf(React.PropTypes.string),
        prefixQueryOptions: React.PropTypes.object,
        translations: core_1.SearchkitComponent.translationsPropType(SearchBox_1.SearchBox.translations),
        mod: React.PropTypes.string,
        placeholder: React.PropTypes.string,
        blurAction: React.PropTypes.string
    }, core_1.SearchkitComponent.propTypes);
    return InputFilter;
}(core_1.SearchkitComponent));
exports.InputFilter = InputFilter;
//# sourceMappingURL=InputFilter.js.map