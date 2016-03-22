var Dispatcher = require('./dispatcher.jsx')
var EventEmitter = require('../../../node_modules/events-activemq/events').EventEmitter
var assign = require('object-assign')
var storekey;
var Activemq = require('./handleupdate.jsx')

function activeMQ(payload){
    Activemq.handle_update(Storeaq,payload)
}

var Storeaq = assign({}, EventEmitter.prototype, {
    emitChange: function(key){
        console.log(key)
        this.emit(key)
    },
    addChangeListener: function(callback){
        this.on(storekey, callback)
    },
    storeKey: function(key){
    storekey = key
    }
    })

    Dispatcher.register(function(payload){
    activeMQ(payload)
    return true
     })


module.exports = Storeaq
