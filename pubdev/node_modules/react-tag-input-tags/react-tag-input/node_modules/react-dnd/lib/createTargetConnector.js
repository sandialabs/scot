"use strict";

exports.__esModule = true;
exports["default"] = createTargetConnector;

function createTargetConnector(backend) {
  return {
    dropTarget: function connectDropTarget() {
      return backend.connectDropTarget.apply(backend, arguments);
    }
  };
}

module.exports = exports["default"];