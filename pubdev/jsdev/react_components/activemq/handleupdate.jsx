var set;
function update(state, callback, payload){
    activemqstate = 'update'
    if (state == 'event') {
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " updated " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        activemqsetentry = activemqid
        activemqsetentrytype = 'event'
        callback.emitChange('guidegroup')
        callback.emitChange('intelgroup')
        callback.emitChange('entryNotification');
        callback.emitChange('taskgroup')
        callback.emitChange('selectedHeaderEntry');
        callback.emitChange('alertgroupnotification')
        callback.emitChange('eventgroup')
        callback.emitChange('activealertgroup')
        callback.emitChange('incidentgroup')
        callback.emitChange(payload.action.activemq.data.id)
        /* setTimeout(function(){$('.z-row').each(function(key, value){
            $(value).find('.z-cell').each(function(r,s){
            if($(s).attr('name') == 'id' && $(s).text() == payload.action.activemq.data.id){
                $(value).css('background', '#FFFF76')
                setTimeout(function(){$(value).css('background', "")}, 10000)
                }
        })
        }) }, 1000) */
    }
    else if (state == 'entry'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " updated " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        callback.emitChange(payload.action.activemq.data.id)
    }
    else if (state == 'intel'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " updated " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        activemqsetentry = activemqid
        activemqsetentrytype = 'intel'
        callback.emitChange('guidegroup')
        callback.emitChange('intelgroup')
        callback.emitChange('taskgroup')
        callback.emitChange('selectedHeaderEntry');
        callback.emitChange('entryNotification');
        callback.emitChange('alertgroupnotification')
        callback.emitChange('incidentgroup')
        callback.emitChange("activealertgroup")
        callback.emitChange('eventgroup')
        callback.emitChange(payload.action.activemq.data.id)
    }
   else if(state == 'task'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " updated " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        callback.emitChange('guidegroup')
        callback.emitChange('intelgroup')
        callback.emitChange('taskgroup')
        callback.emitChange('selectedHeaderEntry');
        callback.emitChange('entryNotification');
        callback.emitChange('alertgroupnotification')
        callback.emitChange('incidentgroup')
        callback.emitChange("activealertgroup")
        callback.emitChange('eventgroup')
        callback.emitChange(payload.action.activemq.data.id)
    }

    else if(state == 'entity'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " updated " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        callback.emitChange('guidegroup')
        callback.emitChange('intelgroup')
        callback.emitChange('taskgroup')
        callback.emitChange('selectedHeaderEntry');
        callback.emitChange('entryNotification');
        callback.emitChange('alertgroupnotification')
        callback.emitChange('incidentgroup')
        callback.emitChange("activealertgroup")
        callback.emitChange('eventgroup')
        callback.emitChange(payload.action.activemq.data.id)
    }
   else if(state == 'guide'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " updated " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqsetentry = activemqid
        activemqsetentrytype = 'guide'
        activemqtype = state
        callback.emitChange('guidegroup')
        callback.emitChange('intelgroup')
        callback.emitChange('taskgroup')
        callback.emitChange('selectedHeaderEntry');
        callback.emitChange('entryNotification');
        callback.emitChange('alertgroupnotification')
        callback.emitChange('incidentgroup')
        callback.emitChange("activealertgroup")
        callback.emitChange('eventgroup')
        callback.emitChange(payload.action.activemq.data.id)
    }
   else if(state == 'incident'){
        activemqsetentry = activemqid
        activemqsetentrytype = 'incident'
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " updated " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        callback.emitChange('guidegroup')
        callback.emitChange('intelgroup')
        callback.emitChange('taskgroup')
        callback.emitChange('selectedHeaderEntry');
        callback.emitChange('entryNotification');
        callback.emitChange('alertgroupnotification')
        callback.emitChange('incidentgroup')
        callback.emitChange("activealertgroup")
        callback.emitChange('eventgroup')
        callback.emitChange(payload.action.activemq.data.id)
    }
   else if(state == 'alertgroup'){
    /*
    $('.z-table').each(function(key, value){
        $(value).find('.z-row').each(function(x,y){
           $(y).find('.z-cell').each(function(r,s){
           if($(s).attr('name') == 'id' && $(s).text() == payload.action.activemq.data.id){
            $(y).css('background', '#FFFF76')
            setTimeout(function(){$(y).css('background', "")}, 10000)
            }
        })
      })
    }) */
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " updated " + state + " : " 
        activemqtype = state 
        activemqid = payload.action.activemq.data.id
        activemqsetentry = activemqid
        activemqsetentrytype = 'alertgroup'
        callback.emitChange('guidegroup')
        callback.emitChange('intelgroup')
        callback.emitChange('viewentrykey')
        callback.emitChange('taskgroup')
        callback.emitChange('selectedHeaderEntry');
        callback.emitChange('entryNotification');
        callback.emitChange('alertgroupnotification')
        callback.emitChange("activealertgroup")
        callback.emitChange('incidentgroup')
        callback.emitChange('eventgroup')
        callback.emitChange(payload.action.activemq.data.id)
   }
   else if (state == 'alert'){
        
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " updated " + 'alert' + " id: " 
        activemqid = payload.action.activemq.data.id
        activemqtype = 'alert'
        callback.emitChange('guidegroup')
        callback.emitChange('intelgroup')
        callback.emitChange(payload.action.activemq.data.id)
        callback.emitChange('taskgroup')
        callback.emitChange('selectedHeaderEntry');
        callback.emitChange('alertgroupnotification')
        callback.emitChange("activealertgroup")
        callback.emitChange('incidentgroup')
        callback.emitChange('eventgroup')    
    }
}
function creation(state, callback, payload){
    activemqstate = 'create'
    if(state == 'alert'){    	
    }
    else if (state == 'entry'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " created " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        changeKey = payload.action.activemq.data.type+'listview';
        callback.emitChange(changeKey)
    }
   else if(state == 'task'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " updated " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        changeKey = payload.action.activemq.data.type+'listview';
        callback.emitChange(changeKey)
    }
   else if(state == 'guide'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " updated " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        changeKey = payload.action.activemq.data.type+'listview';
        callback.emitChange(changeKey) 
    }
    else if (state == 'event') {
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " created " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        changeKey = payload.action.activemq.data.type+'listview';
        callback.emitChange(changeKey)
    }
    else if (state == 'intel'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " created " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        changeKey = payload.action.activemq.data.type+'listview';
        callback.emitChange(changeKey)
   }
   else if(state == 'incident'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " created " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        changeKey = payload.action.activemq.data.type+'listview';
        callback.emitChange(changeKey)
    }
   else if(state == 'alertgroup'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " created " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        changeKey = payload.action.activemq.data.type+'listview';
        callback.emitChange(changeKey)
   }
   else if(state == 'entity'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " created " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        changeKey = payload.action.activemq.data.type+'listview';
        callback.emitChange(changeKey) 
   }
   else if(state == 'guide'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " created " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        changeKey = payload.action.activemq.data.type+'listview';
        callback.emitChange(changeKey)
   }
}

function deletion(state, callback, payload){ 
   activemqstate = 'delete'
    if(state == 'alert'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " deleted " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = 'alert'
        callback.emitChange(payload.action.activemq.data.id) 
    }
    else if (state == 'entry'){
         callback.emitChange(payload.action.activemq.data.id) 
    }
    else if (state == 'entity') {
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " deleted " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        callback.emitChange(payload.action.activemq.data.id)
    }
    else if (state == 'tag') {
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " deleted " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        callback.emitChange(payload.action.activemq.data.id)
    }
    else if (state == 'source') {
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " deleted " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        callback.emitChange(payload.action.activemq.data.id)
    }

    else if (state == 'event') {
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " deleted " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        callback.emitChange(payload.action.activemq.data.id)
    }
    else if (state == 'task'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " deleted " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        callback.emitChange(payload.action.activemq.data.id)
}

    else if (state == 'intel'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " deleted " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        callback.emitChange(payload.action.activemq.data.id)
}
   else if(state == 'incident'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " deleted " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        callback.emitChange(payload.action.activemq.data.id)
   }
   else if(state == 'alertgroup'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " deleted " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        callback.emitChange(payload.action.activemq.data.id)
   }
   else if(state == 'guide'){
        activemqwho = payload.action.activemq.data.who
        activemqmessage = " deleted " + state + " : " 
        activemqid = payload.action.activemq.data.id
        activemqtype = state
        callback.emitChange(payload.action.activemq.data.id)
   }
}


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

var ActiveMQ = {
    handle_update: function(callback, payload){
    switch (payload.action.activemq.data.type) {

            case 'tag': 
                switch (payload.action.activemq.action) {
                    case 'updated':
                        update('tag', callback, payload);
                        break;
                    case 'created':
                         creation('tag', callback, payload)
                        break;
                    case 'deleted':
                        deletion('tag', callback, payload)
                        break;
                }
                break;
            case 'source': 
                switch (payload.action.activemq.action) {
                    case 'updated':
                        update('source', callback, payload);
                        break;
                    case 'created':
                         creation('source', callback, payload)
                        break;
                    case 'deleted':
                        deletion('source', callback, payload)
                        break;
                }
                break;

            case 'entity': 
                switch (payload.action.activemq.action) {
                    case 'updated':
                        update('entity', callback, payload);
                        break;
                    case 'created':
                         creation('entity', callback, payload)
                        break;
                    case 'deleted':
                        deletion('entity', callback, payload)
                        break;
                }
                break;           
            case 'task': 
                switch (payload.action.activemq.action) {
                    case 'updated':
                        update('task', callback, payload);
                        break;
                    case 'created':
                         creation('task', callback, payload)
                        break;
                    case 'deleted':
                        deletion('task', callback, payload)
                        break;
                }
                break; 
            case 'entry': 
                switch (payload.action.activemq.action) {
                    case 'updated':
                        update('entry', callback, payload);
                        break;
                    case 'created':
                         creation('entry', callback, payload)
                        break;
                    case 'deleted':
                        deletion('entry', callback, payload)
                        break;
                }
                break;
            case 'event': 
                switch (payload.action.activemq.action) {
                    case 'updated':
                        update('event', callback, payload);
                        break;
                    case 'created':
                        creation('event', callback, payload);
                        break;
                    case 'deleted':
                        deletion('event', callback, payload);
                        break;
                    case 'views':
                        views('event',callback,payload);
                        break;
                    case 'unlinked':
                        update('event',callback,payload);
                        break;
                }
                break;
            case 'intel': 
                switch (payload.action.activemq.action) {
                    case 'updated':
                        update('intel', callback, payload);
                        break;
                    case 'created':
                        creation('intel', callback, payload);
                        break;
                    case 'deleted':
                        deletion('intel', callback, payload)
                        break;
                }
                break;
            case 'guide': 
                switch (payload.action.activemq.action) {
                    case 'updated':
                        update('guide', callback, payload);
                        break;
                    case 'created':
                        creation('guide', callback, payload);
                        break;
                    case 'deleted':
                        deletion('guide', callback, payload)
                        break;
                }
                break;
            case 'alert':
                switch (payload.action.activemq.action) {
                    case 'updated':
			            update('alert', callback, payload)
                        break;
                    case 'created':
                        creation('alert', callback, payload);
                        break;
                    case 'deleted':
                        deletion('alert', callback, payload);
                        break;
                }
			break;
            case 'incident':
                switch (payload.action.activemq.action) {
                    case 'updated':
                        update('incident', callback, payload);
                        break;
                    case 'created':
                        creation('incident', callback, payload);
                        break;
                    case 'deleted':
                        deletion('incident', callback, payload);
                        break;
                }
                break;
            case 'admin_notice':
                display_notice(json);
                break;
	    case 'alertgroup':
		switch (payload.action.activemq.action) {
			case 'updated':
				update('alertgroup', callback, payload);
			break;
			case 'views':
				views('alertgroup', callback, payload);
			break;
			case 'deleted':
				deletion('alertgroup', callback, payload)
			break;
			case 'created':
				creation('alertgroup', callback, payload);
			break;
		}
            break;

    }
}

}

module.exports = ActiveMQ

