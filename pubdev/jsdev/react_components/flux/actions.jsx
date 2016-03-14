var React = require('react')
var Dispatcher = require('./dispatcher.jsx')

var AppActions = { 
	updateItem: function(item, message,data,type){
	Dispatcher.handleViewAction({
		actionType: message,
		item: item,
		data:data,
        type:type
	})
    },
	updateView: function(message){
	Dispatcher.handleViewAction({
		actionType:message
	})
    }
}


module.exports = AppActions
