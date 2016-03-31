var set;
function update(state, callback, payload){
    if (state == 'event') {
     activemqwho = payload.action.activemq.data.who
     activemqmessage = " updated " + state + " : " 
     activemqid = payload.action.activemq.data.id
     activemqtype = state
     callback.emitChange('alertgroupnotification')
     callback.emitChange('eventgroup')
     callback.emitChange('activealertgroup')
     callback.emitChange('incidentgroup')
     callback.emitChange(payload.action.activemq.data.id)
     setTimeout(function(){$('.z-row').each(function(key, value){
           $(value).find('.z-cell').each(function(r,s){
           if($(s).attr('name') == 'id' && $(s).text() == payload.action.activemq.data.id){
            $(value).css('background', '#FFFF76')
            setTimeout(function(){$(value).css('background', "")}, 10000)
            }
      })
    }) }, 1000)
    }
    else if (state == 'entry'){
     activemqwho = payload.action.activemq.data.who
     activemqmessage = " updated " + state + " : " 
     activemqid = payload.action.activemq.data.id
     activemqtype = state
    callback.emitChange(payload.action.activemq.data.id)
    }
    else if (state == 'intel'){
     callback.emitChange('intelgroup')
     callback.emitChange(payload.action.activemq.data.id)
    }

   else if(state == 'incident'){
     activemqwho = payload.action.activemq.data.who
     activemqmessage = " updated " + state + " : " 
     activemqid = payload.action.activemq.data.id
     activemqtype = state
     callback.emitChange('alertgroupnotification')
     callback.emitChange('incidentgroup')
     callback.emitChange("activealertgroup")
     callback.emitChange('eventgroup')
     callback.emitChange(payload.action.activemq.data.id)
   }
   else if(state == 'alertgroup'){
    
    $('.z-table').each(function(key, value){
        $(value).find('.z-row').each(function(x,y){
           $(y).find('.z-cell').each(function(r,s){
           if($(s).attr('name') == 'id' && $(s).text() == payload.action.activemq.data.id){
            $(y).css('background', '#FFFF76')
            setTimeout(function(){$(y).css('background', "")}, 10000)
            }
        })
      })
    })
     activemqwho = payload.action.activemq.data.who
     activemqmessage = " updated " + state + " : " 
     activemqid = payload.action.activemq.data.id
     activemqtype = state
     callback.emitChange('alertgroupnotification')
     callback.emitChange("activealertgroup")
     callback.emitChange('incidentgroup')
     callback.emitChange('eventgroup')
     callback.emitChange(payload.action.activemq.data.id)
   }
   else if (state == 'alert'){
/*    $('.z-table').each(function(key, value){
        $(value).find('.z-row').each(function(x,y){
           $(y).find('.z-cell').each(function(r,s){
           if($(s).attr('name') == 'id' && $(s).text() == payload.action.activemq.data.id){
            $(y).css('background', '#FFFF76')
            setTimeout(function(){$(y).css('background', "")}, 10000)
            }
        })
      })
    })

*/
   }
}
function creation(state, callback, payload){
    if(state == 'alert'){    	
    }
    else if (state == 'entry'){
    activemqwho = payload.action.activemq.data.who
    activemqmessage = " created " + state + " : " 
    activemqid = payload.action.activemq.data.id
    activemqtype = state
    callback.emitChange(payload.action.activemq.data.id) 
    callback.emitChange('eventgroup') 
    callback.emitChange('activealertgroup')
    callback.emitChange('incidentgroup') 
    callback.emitChange('alertgroupnotification')
    }
    else if (state == 'event') {
    activemqwho = payload.action.activemq.data.who
    activemqmessage = " created " + state + " : " 
    activemqid = payload.action.activemq.data.id
    activemqtype = state
    callback.emitChange('incidentgroup') 
    callback.emitChange('eventgroup')  
    callback.emitChange('activealertgroup')
    callback.emitChange('alertgroupnotification')
    setTimeout(function(){$('.z-row').each(function(key, value){
           $(value).find('.z-cell').each(function(r,s){
           if($(s).attr('name') == 'id' && $(s).text() == payload.action.activemq.data.id){
            $(value).css('background', '#FFFF76')
            setTimeout(function(){$(value).css('background', "")}, 10000)
            }
      })
    }) }, 1000)
    }
    else if (state == 'intel'){

     callback.emitChange('intelgroup') 

    }
   else if(state == 'incident'){
     activemqwho = payload.action.activemq.data.who
     activemqmessage = " created " + state + " : " 
     activemqid = payload.action.activemq.data.id
     activemqtype = state
     callback.emitChange('incidentgroup') 
     callback.emitChange('eventgroup')  
     callback.emitChange('activealertgroup')
     callback.emitChange('alertgroupnotification')
     callback.emitChange(payload.action.activemq.data.id)
   }
   else if(state == 'alertgroup'){
     activemqwho = payload.action.activemq.data.who
     activemqmessage = " created " + state + " : " 
     activemqid = payload.action.activemq.data.id
     activemqtype = state
     callback.emitChange('activealertgroup')
     callback.emitChange('eventgroup')
     callback.emitChange('incidentgroup')
     callback.emitChange('alertgroupnotification')
     callback.emitChange(payload.action.activemq.data.id)
   }
}

function deletion(state, callback, payload){
    if(state == 'alert'){
     activemqwho = payload.action.activemq.data.who
     activemqmessage = " deleted " + state + " : " 
     activemqid = payload.action.activemq.data.id
     activemqtype = state
     callback.emitChange('activealertgroup')

    }
    else if (state == 'entry'){
     callback.emitChange(payload.action.activemq.data.id) 
    }
    else if (state == 'event') {
     activemqwho = payload.action.activemq.data.who
     activemqmessage = " deleted " + state + " : " 
     activemqid = payload.action.activemq.data.id
     activemqtype = state
     callback.emitChange('activealertgroup') 
     callback.emitChange('incidentgroup') 
     callback.emitChange('eventgroup') 
     callback.emitChange('alertgroupnotification')
    }
    else if (state == 'intel'){

     callback.emitChange('intelgroup') 

    }
   else if(state == 'incident'){
     activemqwho = payload.action.activemq.data.who
     activemqmessage = " deleted " + state + " : " 
     activemqid = payload.action.activemq.data.id
     activemqtype = state
     callback.emitChange('incidentgroup')
     callback.emitChange('activealertgroup') 
     callback.emitChange('eventgroup') 
    callback.emitChange('alertgroupnotification')
    callback.emitChange(payload.action.activemq.data.id)
   }
   else if(state == 'alertgroup'){
     activemqwho = payload.action.activemq.data.who
     activemqmessage = " deleted " + state + " : " 
     activemqid = payload.action.activemq.data.id
     activemqtype = state
     callback.emitChange('incidentgroup')
     callback.emitChange('eventgroup') 
     callback.emitChange('activealertgroup') 
     callback.emitChange('alertgroupnotification')
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

