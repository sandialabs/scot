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
var xenon_1 = require("xenon");
var pageobjects_ts_1 = require("../../../ui/list/pageobjects.ts");
var FacetFilter = (function (_super) {
    __extends(FacetFilter, _super);
    function FacetFilter() {
        _super.apply(this, arguments);
    }
    FacetFilter.prototype.id = function (name) {
        this.css(".filter--" + name);
    };
    __decorate([
        xenon_1.field(xenon_1.Component, { css: ".sk-panel__header" }), 
        __metadata('design:type', xenon_1.Component)
    ], FacetFilter.prototype, "title", void 0);
    return FacetFilter;
}(pageobjects_ts_1.ItemList));
exports.FacetFilter = FacetFilter;
//# sourceMappingURL=pageobjects.js.map