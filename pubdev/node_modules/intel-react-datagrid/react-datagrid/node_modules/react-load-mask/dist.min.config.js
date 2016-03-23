module.exports = {
    entry: './src/index.jsx',
    output: {
        path         : __dirname + "/dist",
        libraryTarget: 'umd',
        library      : 'LoadMask',
        filename     : 'react-load-mask.min.js'
    },
    module: {
        loaders: require('./loaders.config')
    },
    externals: {
        'react': 'React'
    },
    resolve: {
        // Allow to omit extensions when requiring these files
        extensions: ['', '.js', '.jsx']
    }
}