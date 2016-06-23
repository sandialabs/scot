"use strict";
var shallowEqualWithoutFunctions_1 = require('./shallowEqualWithoutFunctions');
function shouldPureComponentUpdate(nextProps, nextState) {
    return !shallowEqualWithoutFunctions_1.shallowEqualWithoutFunctions(this.props, nextProps) ||
        !shallowEqualWithoutFunctions_1.shallowEqualWithoutFunctions(this.state, nextState);
}
exports.shouldPureComponentUpdate = shouldPureComponentUpdate;
//# sourceMappingURL=shouldPureComponentUpdate.js.map