var AppActions  = require('./actions.jsx')
var Store       = require('./store.jsx')
var Listeneraq = {
    activeMq: function(){
        AppActions.getClient()
        AppActions.updateView()
    }
}


module.exports = Listeneraq




