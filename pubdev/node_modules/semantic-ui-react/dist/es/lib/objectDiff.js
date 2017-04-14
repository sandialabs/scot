import _isEqual from 'lodash/isEqual';
import _has from 'lodash/has';
import _transform from 'lodash/transform';


/**
 * Naive and inefficient object difference, intended for development / debugging use only.
 * Deleted keys are shown as [DELETED].
 * @param {{}} source The source object
 * @param {{}} target The target object.
 * @returns {{}} A new object containing new/modified/deleted keys.
 * @example
 * import { objectDiff } from 'src/lib'
 *
 * const a = { key: 'val', foo: 'bar' }
 * const b = { key: 'val', foo: 'baz' }
 *
 * objectDiff(a, b)
 * //=> { foo: 'baz' }
 */
export var objectDiff = function objectDiff(source, target) {
  return _transform(source, function (res, val, key) {
    // deleted keys
    if (!_has(target, key)) res[key] = '[DELETED]';
    // new keys / changed values
    else if (!_isEqual(val, target[key])) res[key] = target[key];
  }, {});
};