import React from 'react';
import Index from '../main';
import $ from "jquery";
import * as SessionStorage from "../components/session_storage";
import Dispatcher from "./dispatcher";

export class AMQ extends React.Component{

    constructor(props) {
        super(props);
        this.state = {
            activemqwho:'',
            activemqid:'',
            activemqmessage: '',
            activemqtype:'',
            activemqaction:'',
            activemqguid:'',
            activemqhostname: '',
            activemqpid:'',
            activemqstate:'',
            activemqsetentry:0,
            activemqsetentrytype:'',
            activemqwall:'',
            activemqwhen: '',
            entityPopUpHeight:'',
            entityPopUpWidth:'',
            changeKey:'',
            amqdebug:false,
            client: '',
            whoami:''
        }
        this.update= this.update.bind(this)
        this.updateView = this.updateView.bind(this)

    }

    update = ( state, callback, payload ) =>{
        this.setState({activemqwho:payload.action.activemq.data.who,
            activemqstate:'update', activemqmessage:' created ' + state + ' : ',
            activemqid: payload.action.activemq.data.id,
            activemqtype:payload.action.activemq.data.type});
        callback.emitChange( payload.action.activemq.data.id );
        callback.emitChange( 'notification' );
    }

    creation = ( state, callback, payload ) => {
        this.setState({activemqstate:'create'});
        if ( state !== 'alert' ) {
            this.setState({activemqwho:payload.action.activemq.data.who});
            this.setState({activemqmessage:' created ' + state + ' : '});
            this.setState({activemqpid:payload.action.activemq.pid});
            this.setState({activemqtype:payload.action.activemq.data.type});
            this.setState({changeKey:payload.action.activemq.data.type+'listview'});
            callback.emitChange( this.changeKey );
            callback.emitChange( 'notification' );
        }
    }

    deletion = ( state, callback, payload ) =>{
        this.setState({activemqwho:payload.action.activemq.data.who});
        this.setState({activemqstate:'delete'});
        this.setState({activemqmessage:' deleted ' + state + ' : '});
        this.setState({activemqid:payload.action.activemq.data.id});
        this.setState({activemqtype:state});
        callback.emitChange( payload.action.activemq.data.id );
        callback.emitChange( 'notification' );
    }


    handle_update = ( callback, payload ) =>{
        if ( this.amqdebug === true ) {
            this.setState({activemqaction:payload.action.activemq.action,
                activemqid:payload.action.activemq.data.id,
                activemqtype:payload.action.activemq.data.type,
                activemqwho:payload.action.activemq.data.who,
                activemqguid:payload.action.activemq.guid,
                activemqhostname:payload.action.activemq.hostname,
                activemqpid:payload.action.activemq.pid});
            callback.emitChange( 'amqdebug' );
        }

        if ( payload.action.activemq.action === 'wall' ) {
            this.setState({activemqwho:payload.action.activemq.data.who,
                activemqmessage:payload.action.activemq.data.message,
                activemqwhen:payload.action.activemq.data.when,
                activemqwall:true});
            callback.emitChange( 'wall' );
        }
        switch ( payload.action.activemq.action ) {
            case 'updated':
                this.update( payload.action.activemq.data.type, callback, payload );
                break;
            case 'created':
                this.creation( payload.action.activemq.data.type, callback, payload );
                break;
            case 'deleted':
                this.deletion( payload.action.activemq.data.type, callback, payload );
                break;
        }
    }

    s4 = () => {
        return Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
    }

    get_guid = () => {
        return this.s4() + this.s4() + this.s4() + this.s4() + this.s4() + this.s4() + this.s4() + this.s4();
    }

    register_client = (restart) =>{
        let client = this.get_guid();
        this.setState({client:{client}});
        this.whoami = SessionStorage.getSessionStorage('whoami');
        this.topic = SessionStorage.getSessionStorage('topic');

        $.ajax( {
            type: 'POST',
            url:'/vastaq/amq',
            data: {
                message: 'chat',
                type: 'listen',
                clientId: this.client,
                destination: 'topic://vast'
            },
            success: function(){
                console.log( 'Registered client as '+client );
                if ( !restart ) {   //only start the update if this is not a restart. Restart will just use the new clientid once it is live.
                    setTimeout( function() { this.updateView(); }.bind(this), 1000 );
                }
            }.bind(this),
            error:function() {
                console.log( 'Error: failed to register client, retry in 1 sec' );
                setTimeout( function() {this.register_client();}.bind(this), 1000 );
            }.bind(this)
        } );
    }

    getClient = () => {
        this.register_client();
    }

    restartClient = () => {
        this.register_client(true);  //restart client
    }

    updateView = () => {
        let now = new Date();
        $.ajax( {
            type: 'GET',
            url:  '/vastaq/amq',
            data: {
                /*loc: location.hash, */
                clientId: client,
                timeout: 20000,
                d: now.getTime(),
                r: Math.random(),
                json:'true',
                username: whoami
            },
            success: function( data ) {
                console.log('Received Message: '+JSON.stringify(data));
                setTimeout(function () {
                    this.updateView();
                }.bind(this), 40);
                let messages = $(data).text().split('\n');
                $.each(messages, function (key, message) {
                    if (message != '') {
                        let json = JSON.parse(message);
                        console.log(json);
                        Dispatcher.handleActivemq({
                            activemq: json
                        });
                    }
                });
            }.bind(this),
            error: function() {
                setTimeout(function () {
                    this.updateView();
                }.bind(this), 1000);
                console.log('AMQ not detected, retrying in 1 second.');
            }
        } );
    }

    render() {
        return (
            <Index
                   eventemitter = {new Store()}
                   location={this.props.location} match={this.props.match}
                   history={this.props.history} activemqstate={this.state.activemqstate}
                   activemqwho={this.state.activemqwho} activemqwall={this.state.activemqwall}
                   activemqid={this.state.activemqid} activemqtype={this.state.activemqtype}
                   activemqmessage={this.state.activemqmessage} activemqwhen={this.state.activemqwhen}
                   registerClient={this.register_client}
            />
        );
    }
}


export class EventEmitter {
    constructor() {
      this.events = {};
      this.on = this.on.bind(this);
      this.removeListener = this.removeListener.bind(this);
      this.emit = this.emit.bind(this);
    }
    on = (event, listener) => {
        if (typeof this.events[event] !== 'object') {
            this.events[event] = [];
        }
        this.events[event].push(listener);
        return () => this.removeListener(event, listener);
    }
    removeListener = (event, listener) => {
      if (typeof this.events[event] === 'object') {
          const idx = this.events[event].indexOf(listener);
          if (idx > -1) {
            this.events[event].splice(idx, 1);
          }
      }
    }
    emit = (event, ...args) => {
      if (typeof this.events[event] === 'object') {
        this.events[event].forEach(listener => listener.apply(this, args));
      }
    }
};