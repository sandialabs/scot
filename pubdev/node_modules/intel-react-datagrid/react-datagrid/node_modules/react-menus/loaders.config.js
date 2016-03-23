module.exports = [
    {
        test   : /\.jsx$/,
        loader : 'jsx-loader?insertPragma=React.DOM&harmony',
        exclude: /node_modules/
    },
    {
        test   : /\.styl$/,
        loader : 'style-loader!css-loader!stylus-loader',
        exclude: /node_modules/
    },
    {
        test   : /\.css$/,
        loader : 'style-loader!css-loader',
        exclude: /node_modules/
    },
    {
        test   : /\.png$/,
        loader : 'url-loader?mimetype=image/png',
        exclude: /node_modules/
    }
]