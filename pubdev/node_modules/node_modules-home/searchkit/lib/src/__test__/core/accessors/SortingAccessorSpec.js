"use strict";
var _this = this;
var _1 = require("../../../");
describe("SortingAccessor", function () {
    beforeEach(function () {
        _this.options = {
            options: [
                { label: "None" },
                {
                    label: "Highest Price",
                    field: 'price',
                    order: 'desc'
                },
                {
                    label: "Lowest Price",
                    field: 'price',
                    key: "cheap"
                },
                {
                    label: "Highly rated",
                    key: "rated",
                    fields: [
                        { field: "rating", options: { order: "asc" } },
                        { field: "price", options: { order: "desc", customKey: "custom" } }
                    ]
                },
                {
                    label: "Cheapest",
                    key: "cheapest",
                    fields: [
                        { field: "price", options: { order: 'desc' } },
                        { field: "rated" }
                    ]
                }
            ]
        };
        _this.accessor = new _1.SortingAccessor("sort", _this.options);
    });
    it("constructor()", function () {
        expect(_this.accessor.key).toBe("sort");
        expect(_this.accessor.options).toBe(_this.options);
        expect(_this.options.options).toEqual([
            { label: 'None', key: 'none' },
            { label: 'Highest Price', field: 'price', order: 'desc', key: 'price_desc' },
            { label: 'Lowest Price', field: 'price', key: 'cheap' },
            {
                label: "Highly rated",
                key: "rated",
                fields: [
                    { field: "rating", options: { order: "asc" } },
                    { field: "price", options: { order: "desc", customKey: "custom" } }
                ]
            },
            {
                label: "Cheapest",
                key: "cheapest",
                fields: [
                    { field: "price", options: { order: 'desc' } },
                    { field: "rated" }
                ]
            }
        ]);
    });
    it("buildOwnQuery()", function () {
        _this.accessor.state = new _1.ValueState("cheap");
        var query = new _1.ImmutableQuery();
        var priceQuery = _this.accessor.buildOwnQuery(query);
        expect(priceQuery.query.sort).toEqual(['price']);
        _this.accessor.state = _this.accessor.state.clear();
        query = _this.accessor.buildOwnQuery(query);
        expect(query.query.sort).toEqual(undefined);
        _this.options.options[1].defaultOption = true;
        query = _this.accessor.buildOwnQuery(query);
        expect(query.query.sort).toEqual([{ 'price': 'desc' }]);
        // handle complex sort
        _this.accessor.state = new _1.ValueState("rated");
        query = _this.accessor.buildOwnQuery(query);
        expect(query.query.sort).toEqual([{ 'rating': { order: 'asc' } }, { 'price': { order: 'desc', customKey: 'custom' } }]);
        // empty options
        _this.accessor.state = new _1.ValueState("cheapest");
        query = _this.accessor.buildOwnQuery(query);
        expect(query.query.sort).toEqual([{ 'price': { order: 'desc' } }, { 'rated': {} }]);
        // handle no options
        _this.accessor.options.options = [];
        query = _this.accessor.buildOwnQuery(new _1.ImmutableQuery());
        expect(query.query.sort).toEqual(undefined);
    });
});
//# sourceMappingURL=SortingAccessorSpec.js.map