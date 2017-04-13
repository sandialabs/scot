import _startsWith from 'lodash/fp/startsWith';
import _has from 'lodash/fp/has';
import _eq from 'lodash/fp/eq';
import _flow from 'lodash/fp/flow';
import _curry from 'lodash/fp/curry';
import _get from 'lodash/fp/get';
import _includes from 'lodash/fp/includes';
import _values from 'lodash/fp/values';


export var TYPES = {
  ADDON: 'addon',
  COLLECTION: 'collection',
  ELEMENT: 'element',
  VIEW: 'view',
  MODULE: 'module'
};

var TYPE_VALUES = _values(TYPES);

/**
 * Determine if an object qualifies as a META object.
 * It must have the required keys and valid values.
 * @private
 * @param {Object} _meta A proposed component _meta object.
 * @returns {Boolean}
 */
export var isMeta = function isMeta(_meta) {
  return _includes(_get('type', _meta), TYPE_VALUES);
};

/**
 * Extract a component's _meta object and optional key.
 * Handles literal _meta objects, classes with _meta, objects with _meta
 * @private
 * @param {function|object} metaArg A class, a component instance, or meta object..
 * @returns {object|string|undefined}
 */
var getMeta = function getMeta(metaArg) {
  // literal
  if (isMeta(metaArg)) return metaArg;

  // from prop
  else if (isMeta(_get('_meta', metaArg))) return metaArg._meta;

    // from class
    else if (isMeta(_get('constructor._meta', metaArg))) return metaArg.constructor._meta;
};

var metaHasKeyValue = _curry(function (key, val, metaArg) {
  return _flow(getMeta, _get(key), _eq(val))(metaArg);
});
export var isType = metaHasKeyValue('type');

// ----------------------------------------
// Export
// ----------------------------------------

// type
export var isAddon = isType(TYPES.ADDON);
export var isCollection = isType(TYPES.COLLECTION);
export var isElement = isType(TYPES.ELEMENT);
export var isView = isType(TYPES.VIEW);
export var isModule = isType(TYPES.MODULE);

// parent
export var isParent = _flow(getMeta, _has('parent'), _eq(false));
export var isChild = _flow(getMeta, _has('parent'));

// other
export var isPrivate = _flow(getMeta, _get('name'), _startsWith('_'));