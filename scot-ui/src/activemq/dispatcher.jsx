let Dispatch  = require( 'flux' ).Dispatcher;
let assign      = require( 'object-assign' );

let Dispatcher = assign( new Dispatch(), {
    handleActivemq: function( action ){
        this.dispatch( {
            action: action
        } );
    }
} );

module.exports = Dispatcher;
