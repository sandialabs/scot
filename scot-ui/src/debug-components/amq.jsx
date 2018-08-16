'use strict';

let React                   = require( 'react' );
let Notificationactivemq    = require( '../../../node_modules/react-notification-system' );
let Store                   = require( '../activemq/store.jsx' );

let notificationStyle = {
    Containers: {
        DefaultStyle: {
            height: '85vh', width:'98%', overflowY: 'auto', left: 'null', marginLeft: 'null', position: 'relative'
        },
    },
    NotificationItem: {
        DefaultStyle: {
            width: '98%'
        },
    }
};

module.exports = React.createClass( {
    componentDidMount: function() {
        Store.storeKey( 'amqdebug' );
        Store.addChangeListener( this.reloadactive );
        amqdebug = true;
    },
    //Callback for AMQ updates
    reloadactive: function(){
        let level = 'info';
        switch ( activemqaction ) {
        case 'updated':
            level = 'info';
            break;
        case 'created':
            level = 'success';
            break;
        case 'deleted':
            level = 'error';
            break;
        case 'views':
            level = 'warning';
            break;
        case 'unlinked':
            'error';
            break;
        }
        let notification = this.refs.notificationSystem;
        notification.addNotification( {
            message: 'action: ' + activemqaction + ' | id: ' + activemqid + ' | type: ' + activemqtype + ' | who: ' + activemqwho + ' | guid: ' + activemqguid + ' | hostname: ' + activemqhostname + ' | pid: ' + activemqpid,
            level: level,
            autoDismiss: 0,
            position: 'bc',
            dismissable: false,
            action: {
                label: 'View',
                callback: function(){
                    window.open( '#/' + activemqtype + '/' + activemqid );
                }
            } 
        } );
    },
    render: function() {
        return (
            <div className="allComponents" style={{'margin-left': '17px'}}>
                <div>
                    <div className='main-header-info-null'>
                        <div className='main-header-info-child'>
                            <h2 style={{'font-size': '30px'}}>AMQ Debugging</h2>
                        </div> 
                    </div>
                    <div className='mainview'>
                        <Notificationactivemq ref='notificationSystem' style={notificationStyle}/>
                    </div>
                </div>
            </div>
        );
    },
} );

