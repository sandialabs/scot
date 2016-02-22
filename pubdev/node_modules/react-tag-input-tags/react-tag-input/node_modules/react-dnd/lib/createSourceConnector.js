"use strict";

exports.__esModule = true;
exports["default"] = createSourceConnector;

function createSourceConnector(backend) {
  return {
    dragSource: function connectDragSource() {
      return backend.connectDragSource.apply(backend, arguments);
    },
    dragPreview: function connectDragPreview() {
      return backend.connectDragPreview.apply(backend, arguments);
    }
  };
}

module.exports = exports["default"];