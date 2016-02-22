'use strict';

exports.__esModule = true;
exports['default'] = bindConnector;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var _bindConnectorMethod2 = require('./bindConnectorMethod');

var _bindConnectorMethod3 = _interopRequireDefault(_bindConnectorMethod2);

var _disposables = require('disposables');

function bindConnector(connector, handlerId) {
  var compositeDisposable = new _disposables.CompositeDisposable();
  var handlerConnector = {};

  Object.keys(connector).forEach(function (key) {
    var _bindConnectorMethod = _bindConnectorMethod3['default'](handlerId, connector[key]);

    var disposable = _bindConnectorMethod.disposable;
    var ref = _bindConnectorMethod.ref;

    compositeDisposable.add(disposable);
    handlerConnector[key] = function () {
      return ref;
    };
  });

  return {
    disposable: compositeDisposable,
    handlerConnector: handlerConnector
  };
}

module.exports = exports['default'];