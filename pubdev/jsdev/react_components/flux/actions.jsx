var React = require('react')
var Dispatcher = require('./dispatcher.jsx')

var AppActions = { 
	updateItem: function(item, message,statusmessage){
	Dispatcher.handleViewAction({
		actionType: message,
		item: item,
		status:statusmessage
	})
    },
	updateView: function(message){
	Dispatcher.handleViewAction({
		actionType:message
	})
    }
}


module.exports = AppActions
