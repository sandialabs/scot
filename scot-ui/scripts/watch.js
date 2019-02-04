process.env.BABEL_ENV = 'development';
process.env.NODE_ENV = 'development';
const fs = require('fs-extra');
const webpack = require('webpack');
//const config = require('../config/webpack.config.js');
const webpackconfig = require('../config/webpack.config.js');
const config = webpackconfig('development');
const paths = require('../config/paths.js');
// removes react-dev-utils/webpackHotDevClient.js at first in the array

config.entry = config.entry.filter(
  entry => !entry.includes('webpackHotDevClient')
);

config.output.path = paths.appBuild;
paths.publicUrl = paths.appBuild + '/';

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
