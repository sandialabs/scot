const {override} = require('customize-cra');
const cspHtmlWebpackPlugin = require("csp-html-webpack-plugin");

const cspConfigPolicy = { 
         'script-src': ["'unsafe-inline'", "'self'", "'unsafe-eval'"],
        'frame-src': ["'self'"],
        'style-src': [ "'unsafe-inline'", "'self'", "'unsafe-eval'", "blob:"],
 }
const  otherConfig = {       
    hashEnabled: {
          'script-src': true,
          'style-src': false
    },
    nonceEnabled: {
         'script-src': true,
         'style-src': false
    }
}

function addCspHtmlWebpackPlugin(config) {
    if(process.env.NODE_ENV === 'production') {
        config.plugins.push(new cspHtmlWebpackPlugin(cspConfigPolicy, otherConfig));
    }

    return config;
}

module.exports = {
    webpack: override(addCspHtmlWebpackPlugin),
};
