'use strict';

exports.__esModule = true;
exports['default'] = bindConnectorMethod;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var _utilsShallowEqual = require('./utils/shallowEqual');

var _utilsShallowEqual2 = _interopRequireDefault(_utilsShallowEqual);

var _utilsCloneWithRef = require('./utils/cloneWithRef');

var _utilsCloneWithRef2 = _interopRequireDefault(_utilsCloneWithRef);

var _disposables = require('disposables');

var _react = require('react');

function areOptionsEqual(currentOptions, nextOptions) {
  if (currentOptions === nextOptions) {
    return true;
  }

  return currentOptions !== null && nextOptions !== null && _utilsShallowEqual2['default'](currentOptions, nextOptions);
}

function bindConnectorMethod(handlerId, connect) {
  var disposable = new _disposables.SerialDisposable();

  var currentNode = null;
  var currentOptions = null;

  function ref() {
    var nextWhatever = arguments.length <= 0 || arguments[0] === undefined ? null : arguments[0];
    var nextOptions = arguments.length <= 1 || arguments[1] === undefined ? null : arguments[1];

    // If passed a ReactElement, clone it and attach this function as a ref.
    // This helps us achieve a neat API where user doesn't even know that refs
    // are being used under the hood.
    if (_react.isValidElement(nextWhatever)) {
      // Custom components can no longer be wrapped directly in React DnD 2.0
      // so that we don't need to depend on findDOMNode() from react-dom.
      if (typeof nextWhatever.type !== 'string') {
        var displayName = nextWhatever.type.displayName || nextWhatever.type.name || 'the component';
        throw new Error('Only native element nodes can now be passed to ' + connect.name + '(). ' + ('You can either wrap ' + displayName + ' into a <div>, or turn it into a ') + 'drag source or a drop target itself.');
      }

      var nextElement = nextWhatever;
      return _utilsCloneWithRef2['default'](nextElement, function (inst) {
        return ref(inst, nextOptions);
      });
    }

    // At this point we can only receive DOM nodes.
    var nextNode = nextWhatever;

    // If nothing changed, bail out of re-connecting the node to the backend.
    if (nextNode === currentNode && areOptionsEqual(currentOptions, nextOptions)) {
      return;
    }

    currentNode = nextNode;
    currentOptions = nextOptions;

    if (!nextNode) {
      disposable.setDisposable(null);
      return;
    }

    // Re-connect the node to the backend.
    var currentDispose = connect(handlerId, nextNode, nextOptions);
    disposable.setDisposable(new _disposables.Disposable(currentDispose));
  }

  return {
    ref: ref,
    disposable: disposable
  };
}

module.exports = exports['default'];