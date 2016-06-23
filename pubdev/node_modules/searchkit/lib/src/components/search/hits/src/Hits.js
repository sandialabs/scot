"use strict";
var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var React = require("react");
var core_1 = require("../../../../core");
var map = require("lodash/map");
var defaults = require("lodash/defaults");
var HitItem = (function (_super) {
    __extends(HitItem, _super);
    function HitItem() {
        _super.apply(this, arguments);
    }
    HitItem.prototype.render = function () {
        return (React.createElement("div", {"data-qa": "hit", className: this.props.bemBlocks.item().mix(this.props.bemBlocks.container("item"))}, this.props.result._id));
    };
    HitItem = __decorate([
        core_1.PureRender, 
        __metadata('design:paramtypes', [])
    ], HitItem);
    return HitItem;
}(React.Component));
exports.HitItem = HitItem;
var HitsList = (function (_super) {
    __extends(HitsList, _super);
    function HitsList() {
        _super.apply(this, arguments);
    }
    HitsList.prototype.render = function () {
        var _a = this.props, hits = _a.hits, mod = _a.mod, className = _a.className, itemComponent = _a.itemComponent;
        var bemBlocks = {
            container: core_1.block(mod),
            item: core_1.block(mod + "-hit")
        };
        return (React.createElement("div", {"data-qa": "hits", className: bemBlocks.container().mix(className)}, map(hits, function (result, index) {
            return core_1.renderComponent(itemComponent, {
                key: result._id, result: result, bemBlocks: bemBlocks, index: index
            });
        })));
    };
    HitsList.defaultProps = {
        mod: "sk-hits",
        itemComponent: HitItem
    };
    HitsList.propTypes = {
        mod: React.PropTypes.string,
        className: React.PropTypes.string,
        itemComponent: core_1.RenderComponentPropType,
        hits: React.PropTypes.array
    };
    HitsList = __decorate([
        core_1.PureRender, 
        __metadata('design:paramtypes', [])
    ], HitsList);
    return HitsList;
}(React.Component));
exports.HitsList = HitsList;
var Hits = (function (_super) {
    __extends(Hits, _super);
    function Hits() {
        _super.apply(this, arguments);
    }
    Hits.prototype.componentWillMount = function () {
        _super.prototype.componentWillMount.call(this);
        if (this.props.highlightFields) {
            this.searchkit.addAccessor(new core_1.HighlightAccessor(this.props.highlightFields));
        }
        if (this.props.sourceFilter) {
            this.searchkit.addAccessor(new core_1.SourceFilterAccessor(this.props.sourceFilter));
        }
        this.hitsAccessor = new core_1.HitsAccessor({ scrollTo: this.props.scrollTo });
        this.searchkit.addAccessor(this.hitsAccessor);
    };
    Hits.prototype.defineAccessor = function () {
        return new core_1.PageSizeAccessor(this.props.hitsPerPage);
    };
    Hits.prototype.render = function () {
        var hits = this.getHits();
        var hasHits = hits.length > 0;
        if (!this.isInitialLoading() && hasHits) {
            var _a = this.props, listComponent = _a.listComponent, mod = _a.mod, className = _a.className, itemComponent = _a.itemComponent;
            return core_1.renderComponent(listComponent, {
                hits: hits, mod: mod, className: className, itemComponent: itemComponent
            });
        }
        return null;
    };
    Hits.propTypes = defaults({
        hitsPerPage: React.PropTypes.number.isRequired,
        highlightFields: React.PropTypes.arrayOf(React.PropTypes.string),
        sourceFilterType: React.PropTypes.oneOf([
            React.PropTypes.string,
            React.PropTypes.arrayOf(React.PropTypes.string),
            React.PropTypes.bool
        ]),
        itemComponent: core_1.RenderComponentPropType,
        listComponent: core_1.RenderComponentPropType
    }, core_1.SearchkitComponent.propTypes);
    Hits.defaultProps = {
        listComponent: HitsList,
        scrollTo: "body"
    };
    return Hits;
}(core_1.SearchkitComponent));
exports.Hits = Hits;
//# sourceMappingURL=Hits.js.map