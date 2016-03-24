var Dispatcher = require('./dispatcher.jsx')
var client;
function s4(){
    return Math.floor((1+ Math.random()) * 0x10000).toString(16).substring(1);
}

function get_guid(){
    return s4()+s4()+s4()+s4()+s4()+s4()+s4()+s4()
}

function register_client(){
    client = get_guid()
    $.ajax({
        type: 'POST',
        url:'/scotaq/amq',
        data: {
            message: 'chat',
            type: 'listen',
            clientId: client,
            destination: '/scot'
        }
    }).done(function(){
        console.log('Registered client as '+client);
    }).fail(function() {
        console.log("Error: failed to register client, retry in 1 sec");
        setTimeout(register_client, 1000);
    })
}

var Actions = {

   getClient: function(){
    register_client()
    },
    updateView: function(){
        var now = new Date();
        $.ajax({
            type: 'GET',
            url:  '/scotaq/amq',
            data: {
                /*loc: location.hash, */
                clientId: client,
                timeout: 2000,
                d: now.getTime(),
                r: Math.random(),
                json:'true',
                username: whoami
            }
        }).done(function(data) {
            console.log("Received Message")
            var set = setTimeout(Actions.updateView(), 40)
            var messages = $(data).text().split('\n')
            $.each(messages, function(key,message){
                if(message != ""){
                    var json = JSON.parse(message);
                    if(json.data.type == 'alertgroup' || json.data.type == 'event' || json.data.type == 'incident' || json.data.type == 'intel' || json.data.type == 'entry')
                    Dispatcher.handleActivemq({
                    activemq: json
                })
               }
            });       
        }).fail(function(){
            setTimeout(Actions.updateView(), 20)
        })
    }

}



module.exports = Actions
