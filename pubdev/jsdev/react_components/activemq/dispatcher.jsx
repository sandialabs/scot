var Dispatcher  = require('flux').Dispatcher
var assign      = require('object-assign')

var Dispatcher = assign(new Dispatcher(), {
    handleActivemq: function(action){
        this.dispatch({
            action: action
        })
    }
})

module.exports = Dispatcher
