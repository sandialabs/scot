/**
 * 获取 node 上的 align 对齐点 相对于页面的坐标
 */

'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
function getAlignOffset(region, align) {
  var V = align.charAt(0);
  var H = align.charAt(1);
  var w = region.width;
  var h = region.height;
  var x = undefined;
  var y = undefined;

  x = region.left;
  y = region.top;

  if (V === 'c') {
    y += h / 2;
  } else if (V === 'b') {
    y += h;
  }

  if (H === 'c') {
    x += w / 2;
  } else if (H === 'r') {
    x += w;
  }

  return {
    left: x,
    top: y
  };
}

exports['default'] = getAlignOffset;
module.exports = exports['default'];