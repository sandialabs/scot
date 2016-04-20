var Dispatcher  = require('../../../node_modules/flux').Dispatcher
var assign      = require('object-assign')

var AppDispatcher = assign(new Dispatcher(), {
	handleViewAction: function(action){
	    this.dispatch({
	        message: action.actionType,
	        action: action
	})
    }
})


module.exports = AppDispatcher 

