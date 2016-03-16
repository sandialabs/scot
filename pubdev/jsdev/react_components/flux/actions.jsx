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
	url:  '/scot/api/v2/alertgroup'
	}).done(function(data) {
	setTimeout(AppActions.updateView(item, message), 200000)
	if(data != null){
	Dispatcher.handleActivemq({
		actionType:message,
		item: item,
		activemq: data
	})
	}
    })
  }
}


module.exports = AppActions
