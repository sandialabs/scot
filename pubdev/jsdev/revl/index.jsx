'use strict';
var ReactDOM	    = require('react-dom')
var React           = require('react')
var Revl            = require('./revl.coffee');
var Login           = require('../react_components/modal/login.jsx').default;
var Navbar          = require('react-bootstrap/lib/Navbar.js');
var Nav             = require('react-bootstrap/lib/Nav.js');
var NavItem         = require('react-bootstrap/lib/NavItem.js');
var NavDropdown     = require('react-bootstrap/lib/NavDropdown.js');
var MenuItem        = require('react-bootstrap/lib/MenuItem.js');

{
	window.React = React;	
	var $ = window.$;

}

var App = React.createClass({

    getInitialState: function(){
        //Listener.activeMq();   //register for amq updates
        return{handler: undefined, viewMode:'default', notificationSetting: 'on', eestring: '', login: false, csrf: '', origurl: '', sensitivity: '', whoami: undefined, }	
    },

    errorToggle: function(string, result) {
        let errorString = string;
        if ( result ) {
            if ( result.responseJSON ) {
                if ( result.responseJSON.error === 'Authentication Required') {
                    this.setState({csrf: result.responseJSON.csrf}); //set csrf here since it can change after the login prompt loads
                    this.loginToggle( result.responseJSON.csrf );
                    return;
                }
            } else if ( result.statusText == 'Service Unavailable' ) {
                errorString = result.statusText;  //Use server error message if available.
            }
        } 

        var notification = this.refs.notificationSystem
        notification.addNotification({
            message: errorString,
            level: 'error',
            autoDismiss: 0,
        });
    },
    notificationToggle: function() {
        if(this.state.notificationSetting == 'off'){
            this.setState({notificationSetting: 'on'})
            setCookie('notification','on',1000);
        }
        else {
            this.setState({notificationSetting: 'off'})
            setCookie('notification','off',1000);
        } 
    },

    loginToggle: function( csrf, loggedin ) {
        //Only open modal once - if other requests come in to open the modal just bypass since the login page is active
        if ( !this.state.login && loggedin != true ) {
            let origurl = this.props.location.pathname;;
            this.props.history.push( '/' );
            this.setState({login: true, origurl: origurl}); 
        } else if ( this.state.login && loggedin == true ) {
            this.setState({login: false}); 
            this.props.history.push( this.state.origurl );
        }
    },
    
    LogOut: function() {
        //Logs out of SCOT
        $.ajax({ 
            type: 'get',
            url: '/logout',
            success: function(data) {
                this.setState({login: true})
                console.log('Successfully logged out');
            }.bind(this), 
            error: function(data) {
                this.error('Failed to log out', data);
            }.bind(this)
        })
    },

    WhoAmIQuery: function() {

        $.ajax({
            type:'get',
            url:'scot/api/v2/whoami',
            success: function (result) {
                setSessionStorage( 'whoami', result.user );
                if ( result.data ) {
                    this.setState({sensitivity: result.data.sensitivity, whoami: result.user});
                }
            }.bind(this),
            error: function(data) {
                this.errorToggle('Failed to get current user', data);
            }.bind(this)
        })
 
    },
    
    GetHandler: function() {
        $.ajax({
            type: 'get',
            url: '/scot/api/v2/handler?current=1'
        }).success(function(response){
            this.setState({handler: response.records[0].username})
        }.bind(this))
    },   

    render: function() {
        var IH = 'Incident Handler: ' + this.state.handler;
        let type;
        
        return (
            <div>
                <Navbar inverse fixedTop={true} fluid={true}>
                    <Navbar.Header>
                        <Navbar.Brand>
                            <NavItem href="/"><img src='/images/scot.png' style={{width:'50px'}} /></NavItem>
                        </Navbar.Brand>
                        <Navbar.Toggle />
                    </Navbar.Header>
                    <Navbar.Collapse>
                        <Nav>
                            <NavItem href='/#/alertgroup'>Alert</NavItem>
                            <NavItem href="/#/event">Event</NavItem>
                            <NavItem href="/#/incident">Incident</NavItem>
                            <NavItem href='/#/intel'>Intel</NavItem>
                            <NavDropdown id='nav-dropdown' title={'More'}>
                                <MenuItem href='/#/task'>Task</MenuItem>
                                <MenuItem href='/#/guide'>Guide</MenuItem>
                            </NavDropdown>
                            <MenuItem href="/#/visualization">Visualization</MenuItem>
                        <span id='ouo_warning' className='ouo-warning'>{this.state.sensitivity}</span>
                        </Nav>
                    </Navbar.Collapse>
                </Navbar>
                <div className='mainNavPadding'>
                    <Login csrf={this.state.csrf} modalActive={this.state.login} loginToggle={this.loginToggle} WhoAmIQuery={this.WhoAmIQuery} GetHandler={this.GetHandler} errorToggle={this.errorToggle} />
                    <Revl />
                </div>
            </div>
        )
    },
});

ReactDOM.render((
    <App></App>
    ), document.getElementById('content'))
