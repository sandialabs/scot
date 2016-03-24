var React = require('react');
var Dispatcher = require('./dispatcher.jsx');
var client;
var msgs_received   = 0;
var clientId;
var attempt_number = 0;
var set;
var AppActions = { 
	updateItem: function(item, message,data,type){
        Dispatcher.handleViewAction({
            actionType: message,
            item: item,
            data: data,
            type: type
        })
    }
};


module.exports = AppActions
