var Dispatcher = require('./dispatcher.jsx')
var EventEmitter = require('../../../node_modules/events').EventEmitter
var Actions = ('./tab_actions.jsx')
var assign = require('object-assign')
var storekey;

function updateStatus(payload) {
	var data = new Object()
	var type = 'PUT'
	$('.subtable'+payload.action.item).find('.z-selected').each(function(key, value){
	$(value).find('.z-cell').each(function(x,y){
	    if($(y).attr('name') == "id"){
		if(payload.action.status == "promoted"){
		data = JSON.stringify({promote: 'new'})
		}
		else if(payload.action.status == 'closed'){
		var curr = Math.round(new Date().getTime() /1000)
		data = JSON.stringify({status: payload.action.status, closed: curr})
		}
		else if (payload.action.status == 'open'){	
		data = JSON.stringify({status:payload.action.status})
		}
		else{
		type = 'DELETE'
		}
		$.ajax({
			type: type,
			url: '/scot/api/v2/alert/'+$(y).text(),
			data: data
		}).success(function(response){
		})
	}
	})
	})
    if(type == 'PUT'){
 	$.ajax({
	type: type,
 	url: '/scot/api/v2/alertgroup/' + payload.action.item,
	data: JSON.stringify({status:payload.action.status})
	}).success(function(response){
	})
    }
}


var Store = assign({}, EventEmitter.prototype, {
	emitChange: function(key){
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
	if(payload.message == 'alertstatusmessage') {
		updateStatus(payload)
	}
	else if(payload.message == 'update'){

	}

	setTimeout(function() {Store.emitChange(payload.action.item)}, 1000)
   	return true
     })

module.exports = Store
