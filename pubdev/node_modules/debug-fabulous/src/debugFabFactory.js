var wrapLazyEval = require('./lazy-eval');

module.exports = function debugFactory(debugApi) {
  debugApi = debugApi ? debugApi : require('debug');
  debugApi = wrapLazyEval(debugApi);

  return debugApi;
}
