"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var React = require("react");
var SearchkitManager_1 = require("../SearchkitManager");
var support_1 = require("../support");
var block = require('bem-cn');
var keys = require("lodash/keys");
var without = require("lodash/without");
var transform = require("lodash/transform");
var SearchkitComponent = (function (_super) {
    __extends(SearchkitComponent, _super);
    function SearchkitComponent(props) {
        _super.call(this, props);
        this.translations = {};
        this.unmounted = false;
        this.translate = this.translate.bind(this);
    }
    SearchkitComponent.prototype.defineBEMBlocks = function () {
        return null;
    };
    SearchkitComponent.prototype.defineAccessor = function () {
        return null;
    };
    SearchkitComponent.prototype.translate = function (key, interpolations) {
        var translation = ((this.searchkit.translate(key)) ||
            (this.props.translations && this.props.translations[key]) ||
            this.translations[key] || key);
        return support_1.Utils.translate(translation, interpolations);
    };
    Object.defineProperty(SearchkitComponent.prototype, "bemBlocks", {
        get: function () {
            return transform(this.defineBEMBlocks(), function (result, cssClass, name) {
                result[name] = block(cssClass);
            });
        },
        enumerable: true,
        configurable: true
    });
    SearchkitComponent.prototype._getSearchkit = function () {
        return this.props.searchkit || this.context["searchkit"];
    };
    SearchkitComponent.prototype.componentWillMount = function () {
        var _this = this;
        this.searchkit = this._getSearchkit();
        if (this.searchkit) {
            this.accessor = this.defineAccessor();
            if (this.accessor) {
                this.accessor = this.searchkit.addAccessor(this.accessor);
            }
            this.stateListenerUnsubscribe = this.searchkit.emitter.addListener(function () {
                if (!_this.unmounted) {
                    _this.forceUpdate();
                }
            });
        }
        else {
            console.warn("No searchkit found in props or context for " + this.constructor["name"]);
        }
    };
    SearchkitComponent.prototype.componentWillUnmount = function () {
        if (this.stateListenerUnsubscribe) {
            this.stateListenerUnsubscribe();
        }
        if (this.searchkit && this.accessor) {
            this.searchkit.removeAccessor(this.accessor);
        }
        this.unmounted = true;
    };
    SearchkitComponent.prototype.getResults = function () {
        return this.searchkit.results;
    };
    SearchkitComponent.prototype.getHits = function () {
        return this.searchkit.getHits();
    };
    SearchkitComponent.prototype.getHitsCount = function () {
        return this.searchkit.getHitsCount();
    };
    SearchkitComponent.prototype.hasHits = function () {
        return this.searchkit.hasHits();
    };
    SearchkitComponent.prototype.hasHitsChanged = function () {
        return this.searchkit.hasHitsChanged();
    };
    SearchkitComponent.prototype.getQuery = function () {
        return this.searchkit.query;
    };
    SearchkitComponent.prototype.isInitialLoading = function () {
        return this.searchkit.initialLoading;
    };
    SearchkitComponent.prototype.isLoading = function () {
        return this.searchkit.loading;
    };
    SearchkitComponent.prototype.getError = function () {
        return this.searchkit.error;
    };
    SearchkitComponent.contextTypes = {
        searchkit: React.PropTypes.instanceOf(SearchkitManager_1.SearchkitManager)
    };
    SearchkitComponent.translationsPropType = function (translations) {
        return React.PropTypes.objectOf(React.PropTypes.string);
    };
    SearchkitComponent.propTypes = {
        mod: React.PropTypes.string,
        className: React.PropTypes.string,
        translations: React.PropTypes.objectOf(React.PropTypes.string),
        searchkit: React.PropTypes.instanceOf(SearchkitManager_1.SearchkitManager)
    };
    return SearchkitComponent;
}(React.Component));
exports.SearchkitComponent = SearchkitComponent;
//# sourceMappingURL=SearchkitComponent.js.map