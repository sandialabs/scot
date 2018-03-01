let Dispatcher      = require( './dispatcher.jsx' );
let EventEmitter    = require( '../../../node_modules/events' ).EventEmitter;
let assign          = require( 'object-assign' );
let Activemq        = require( './handleupdate.jsx' );
let storekey;
function activeMQ( payload ){
    Activemq.handle_update( Storeaq,payload,storekey );
}

var Storeaq = assign( {}, EventEmitter.prototype, {
    emitChange: function( key ){
        //TODO Clean the following comment out once we verify that the scrolling issue due to pre-processing in tinymce is gone at refresh time
        /*if ($('.mce-tinymce')[0]) {
            console.log('Entry box open - holding off update')
            return;
        }*/
        this.emit( key );
    },
    addChangeListener: function( callback ){
        this.on( storekey, callback );
    },
    storeKey: function( key ){
        storekey = key;
    }
} );

Dispatcher.register( function( payload ){
    activeMQ( payload );
    return true;
} );


module.exports = Storeaq;
