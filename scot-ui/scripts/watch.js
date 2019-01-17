process.env.BABEL_ENV = 'production';
process.env.NODE_ENV = 'production';
const fs = require('fs-extra');
const webpack = require('webpack');
//const config = require('../config/webpack.config.js');
const webpackconfig = require('../config/webpack.config.js');
const config = webpackconfig('development');
const paths = require('../config/paths.js');
// removes react-dev-utils/webpackHotDevClient.js at first in the array

console.log("📦 Starting webpack dev build with watch functionality, no minification");

webpack(config).watch({}, (err, stats) => {
  if (err) {
    console.error(err);
  } else {
    copyPublicFolder();
  }
  console.error(stats.toString({
    chunks: false,
    colors: true
  }));
});

function copyPublicFolder() {
  console.log("🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵");
  console.log("Starting compile!!!!!!!");
  fs.copySync(paths.appPublic, paths.appBuild, {
    dereference: true,
    filter: file => file !== paths.appHtml
  });
}
