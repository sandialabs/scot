process.env.BABEL_ENV = 'development';
process.env.NODE_ENV = 'development';
const fs = require('fs-extra');
const webpack = require('webpack');
const webpackconfig = require('react-scripts/config/webpack.config.js');
const paths = require('react-scripts/config/paths');
const config = webpackconfig('development');


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
