var AppActions = require('./actions.jsx')
var Store = require('./store.jsx')
var Listeneraq = {
    activeMq: function(key, callback){
    var sett = true
    Store.storeKey(key)
    Store.addChangeListener(callback)
    AppActions.getClient()
    AppActions.updateView()
    }
}


module.exports = Listeneraq




