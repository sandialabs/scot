function update( state, callback, payload ){
    activemqstate = 'update';
    
    activemqwho = payload.action.activemq.data.who;
    activemqmessage = ' updated ' + state + ' : '; 
    activemqid = payload.action.activemq.data.id;
    activemqtype = state.toLowerCase();
    callback.emitChange( payload.action.activemq.data.id );
    
    callback.emitChange( 'notification' );
}
function creation( state, callback, payload ){
    activemqstate = 'create';
    if ( state != 'alert' ) {    	
    
        activemqwho = payload.action.activemq.data.who;
        activemqmessage = ' created ' + state + ' : '; 
        activemqid = payload.action.activemq.data.id;
        activemqtype = state;
        changeKey = payload.action.activemq.data.type+'listview';
        callback.emitChange( changeKey );
        callback.emitChange( 'notification' );
    }
}

function deletion( state, callback, payload ){ 
    activemqstate = 'delete';
    activemqwho = payload.action.activemq.data.who;
    activemqmessage = ' deleted ' + state + ' : '; 
    activemqid = payload.action.activemq.data.id;
    activemqtype = state;
    callback.emitChange( payload.action.activemq.data.id ); 
    callback.emitChange( 'notification' );
}

/* not used for now
function views(state, callback, payload){
    if (state == 'entry'){

    }
    else if (state == 'event') {
        callback.emitChange('eventgroup') 
    }
    else if (state == 'intel'){
        callback.emitChange('intelgroup') 
    }
   else if(state == 'incident'){

        callback.emitChange('incidentgroup') 
   }
   else if(state == 'alertgroup' || state == 'alert'){
        callback.emitChange('activealertgroup') 
   }

}
*/

let ActiveMQ = {
    handle_update: function( callback, payload ){
        if ( amqdebug == true ) {
            activemqaction = payload.action.activemq.action;
            activemqid = payload.action.activemq.data.id;
            activemqtype = payload.action.activemq.data.type;
            activemqwho = payload.action.activemq.data.who;
            activemqguid = payload.action.activemq.guid;
            activemqhostname = payload.action.activemq.hostname;
            activemqpid = payload.action.activemq.pid;
            callback.emitChange( 'amqdebug' );
        }

        if ( payload.action.activemq.action == 'wall' ) {
            activemqwho = payload.action.activemq.data.who;
            activemqmessage = payload.action.activemq.data.message;
            activemqwhen = payload.action.activemq.data.when;
            activemqwall = true;
            callback.emitChange( 'wall' );
        }
        if ( payload.action.activemq.data.type == 'admin_notice' ) {
            display_notice( json );
        } else {
            switch ( payload.action.activemq.action ) {
            case 'updated':
                update( payload.action.activemq.data.type, callback, payload );
                break;
            case 'created':
                creation( payload.action.activemq.data.type, callback, payload );
                break;
            case 'deleted':
                deletion( payload.action.activemq.data.type, callback, payload );
                break;
            }
        }
    }
};

module.exports = ActiveMQ;

