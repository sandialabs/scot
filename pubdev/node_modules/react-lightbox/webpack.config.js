var path = require('path');
var nodeModulesPath = path.resolve(__dirname, 'node_modules');
var srcPath = path.resolve(__dirname, 'src');
var buildPath = path.resolve(__dirname, 'build');

var config = {
  entry: [path.resolve(srcPath, 'react-lightbox.js')],
  output: {
    path: buildPath,
    filename: 'lib.js',
    libraryTarget: 'umd',
    library: 'ReactLightbox'
  },
  externals: {
    'react': 'React'
  }
};

module.exports = config;
