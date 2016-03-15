var AppActions = require('../flux/actions.jsx')
var Store = require('../flux/store.jsx')
var Listener = {

    activeMq: function(key, callback){
    Store.storeKey(key)
    Store.addChangeListener(callback)
    AppActions.updateView(key, 'activemq')
    }
}


module.exports = Listener




