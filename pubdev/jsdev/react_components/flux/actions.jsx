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
	updateView: function(item, message){
	var client = ''
	var now = new Date()
	$.ajax({
	type: 'GET',
	dataType:'text',
	data: {
	clientId: client,
	timeout: 2000,
	d: now.getTime(),
	r: Math.random(),
	json: 'true',
	username: 'rjeffer'
	}, 
	url: '/scotaq/amq'
	}).done(function(data) {
	console.log(data)
	setTimeout(AppActions.updateView(item, message), 10)
	if(data != null){
	Dispatcher.handleActivemq({
		actionType:message,
		item: item
	})
	}
    })
  }
}


module.exports = AppActions
