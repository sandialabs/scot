/**
 * Module Dependencies
 */

var path      = require('path');
var transform = require('react-tools').transform;
var through   = require('through');

/**
 * Exports
 */

var Transformers = {};

Transformers.source = transform;

Transformers.browserify = function(file, options) {
  var source  = '';

  var write = function(data) {
    source += data;
  };

  var compile = function() {
    var result;

    try {
      this.queue(Transformers.source(source, options));
      this.queue(null);
    } catch (error) {
      error.message += ' in "' + file + '"';

      this.emit('error', error);
    }
  };

  return through(write, compile);
};

module.exports = Transformers;
