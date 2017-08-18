var AppActions  = require('./actions.jsx')
var Store       = require('./store.jsx')
var Listeneraq = {
    activeMq: function(){
        AppActions.getClient()
    }
}


module.exports = Listeneraq




