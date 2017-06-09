function spawnFactory(namespace, debugFabFactory) {
  namespace = namespace || '';

  if(!debugFabFactory){
    debugFabFactory = require('./debugFabFactory')();
  }

  function Debugger(base, ns){
    base = base || '';
    ns = ns || '';
    var newNs = ns ? base + ':' + ns : base;
    var debug = debugFabFactory(newNs);
    this.debug = debug;
    this.debug.spawn = this.spawn;
  }

  Debugger.prototype.spawn = function(ns) {
    var dbg = new Debugger(this.namespace, ns);

    return dbg.debug;
  };

  var rootDebug = (new Debugger(namespace)).debug;

  return rootDebug;
};

module.exports = spawnFactory;
