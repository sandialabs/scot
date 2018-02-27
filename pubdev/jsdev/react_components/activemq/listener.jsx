let AppActions  = require( './actions.jsx' ).default;
let Listeneraq = {
    activeMq: function(){
        AppActions.getClient();
    }
};


module.exports = Listeneraq;




