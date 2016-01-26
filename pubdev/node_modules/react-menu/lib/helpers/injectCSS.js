var jss = require('js-stylesheet');

module.exports = function() {
  jss({
    '.Menu': {
      position: 'relative'
    },
    '.Menu__MenuOptions': {
      border: '1px solid #ccc',
      'border-radius': '3px',
      background: '#FFF',
      position: 'absolute'
    },
    '.Menu__MenuOption': {
      padding: '5px',
      'border-radius': '2px',
      outline: 'none',
      cursor: 'pointer'
    },
    '.Menu__MenuOption--disabled': {
      'background-color': '#eee',
    },
    '.Menu__MenuOption--active': {
      'background-color': '#0aafff',
    },
    '.Menu__MenuOption--active.Menu__MenuOption--disabled': {
      'background-color': '#ccc'
    },
    '.Menu__MenuTrigger': {
      border: '1px solid #ccc',
      'border-radius': '3px',
      padding: '5px',
      background: '#FFF'
    },
    '.Menu__MenuOptions--horizontal-left': {
      right: '0px'
    },
    '.Menu__MenuOptions--horizontal-right': {
      left: '0px'
    },
    '.Menu__MenuOptions--vertical-top': {
      bottom: '45px'
    },
    '.Menu__MenuOptions--vertical-bottom': {
    }
  });
};
