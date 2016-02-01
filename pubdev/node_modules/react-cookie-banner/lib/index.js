'use strict';

exports.__esModule = true;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var _CookieBannerJs = require('./CookieBanner.js');

var _CookieBannerJs2 = _interopRequireDefault(_CookieBannerJs);

exports['default'] = _CookieBannerJs2['default'];

var _browserCookieLite = require('browser-cookie-lite');

exports.cookie = _browserCookieLite.cookie;