"use strict";
var React = require("react");
var core_1 = require("../../../../core");
var defaults = require("lodash/defaults");
exports.FacetFilterPropTypes = defaults({
    field: React.PropTypes.string.isRequired,
    operator: React.PropTypes.oneOf(["AND", "OR"]),
    size: React.PropTypes.number,
    title: React.PropTypes.string.isRequired,
    id: React.PropTypes.string.isRequired,
    containerComponent: core_1.RenderComponentPropType,
    listComponent: core_1.RenderComponentPropType,
    itemComponent: core_1.RenderComponentPropType,
    translations: core_1.SearchkitComponent.translationsPropType(core_1.FacetAccessor.translations),
    orderKey: React.PropTypes.string,
    orderDirection: React.PropTypes.oneOf(["asc", "desc"]),
    include: React.PropTypes.oneOfType([
        React.PropTypes.string, React.PropTypes.array
    ]),
    exclude: React.PropTypes.oneOfType([
        React.PropTypes.string, React.PropTypes.array
    ]),
    showCount: React.PropTypes.bool,
    showMore: React.PropTypes.bool,
    fieldOptions: React.PropTypes.shape({
        type: React.PropTypes.oneOf(["embedded", "nested", "children"]).isRequired,
        options: React.PropTypes.object
    }),
    countFormatter: React.PropTypes.func,
    bucketsTransform: React.PropTypes.func
}, core_1.SearchkitComponent.propTypes);
//# sourceMappingURL=FacetFilterProps.js.map