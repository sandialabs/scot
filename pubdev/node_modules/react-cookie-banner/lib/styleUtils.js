'use strict';

exports.__esModule = true;

var styles = {
  icon: {
    position: 'absolute',
    fontSize: '1em',
    top: '50%',
    marginTop: '-0.5em',
    right: '1em',
    color: 'white',
    cursor: 'pointer'
  },

  link: {
    color: '#F0F0F0',
    textDecoration: 'underline',
    marginLeft: '10px'
  },

  button: {
    position: 'absolute',
    top: '50%',
    right: '35px',
    height: '24px',
    lineHeight: '24px',
    marginTop: '-12px',
    paddingLeft: '8px',
    paddingRight: '8px',
    opacity: '0.5',
    backgroundColor: 'white',
    borderRadius: '3px',
    fontSize: '14px',
    fontWeight: '500',
    color: '#242424',
    cursor: 'pointer'
  },

  message: {
    lineHeight: '45px',
    fontWeight: 500,
    color: '#F0F0F0'
  },

  banner: {
    position: 'relative',
    textAlign: 'center',
    backgroundColor: '#484848',
    width: '100%',
    height: '45px',
    zIndex: '10000'
  }
};

var getStyle = function getStyle(style) {
  return styles[style];
};

exports['default'] = { getStyle: getStyle };
module.exports = exports['default'];