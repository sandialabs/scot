'use strict';
var ReactDOM	    = require('react-dom')
var React           = require('react')
var Navbar          = require('react-bootstrap/lib/Navbar.js');
var Nav             = require('react-bootstrap/lib/Nav.js');
var NavItem         = require('react-bootstrap/lib/NavItem.js');
var NavDropdown     = require('react-bootstrap/lib/NavDropdown.js');
var MenuItem        = require('react-bootstrap/lib/MenuItem.js');
var LinkContainer   = require('react-router-bootstrap/lib/LinkContainer.js');
var ListView        = require('../list/list-view.jsx');
//var ListView        = require('../ListView/index.jsx').default;
var Router	        = require('react-router-dom').Router
var Route	        = require('react-router-dom').Route
var Link	        = require('react-router-dom').Link
var customHistory   = require('history').createBrowserHistory
var Switch          = require('react-router-dom').Switch;
var HashRouter      = require('react-router-dom').HashRouter;
var BrowserRouter   = require('react-router-dom').BrowserRouter;
var Listener        = require('../activemq/listener.jsx')
var Store           = require('../activemq/store.jsx');
var SelectedContainer = require('../detail/selected_container.jsx')
var AMQ             = require('../debug-components/amq.jsx');
var Wall            = require('../debug-components/wall.jsx');
var Search          = require('../components/esearch.jsx');
var Revl            = require('../components/visualization/revl.coffee');
var Gamification    = require('../components/dashboard/gamification.jsx');
var Status          = require('../components/dashboard/status.jsx');
var Online          = require('../components/dashboard/online.jsx');
import { ReportDashboard, ReportPage, SingleReport } from '../components/dashboard/report';
var Notification    = require('react-notification-system');
var Login           = require('../modal/login.jsx').default;

{
	window.React = React;	
	var $ = window.$;

}

var App = React.createClass({

    getInitialState: function(){
        Listener.activeMq();   //register for amq updates
        return{handler: undefined, viewMode:'default', notificationSetting: 'on', eestring: '', login: false, csrf: '', origurl: '', sensitivity: '', whoami: undefined, }	
    },

    componentDidMount: function() {
        this.GetHandler();
        this.WhoAmIQuery();    
        
        Store.storeKey('wall');
        Store.addChangeListener(this.wall);
        Store.storeKey('notification');
        Store.addChangeListener(this.notification);
       
        //ee
        if (this.props.match.url == '/') {
            $(document.body).keydown(function(e) {
                this.ee(e);
            }.bind(this))   
        }
    },

    componentWillReceiveProps: function (nextProps) {
        var viewModeSetting = checkCookie('viewMode');
        var notificationSetting = checkCookie('notification');
        if (nextProps.match.params.value) {
            var listViewFilterSetting = checkCookie('listViewFilter'+nextProps.match.params.value.toLowerCase());
            var listViewSortSetting = checkCookie('listViewSort'+nextProps.match.params.value.toLowerCase());
            var listViewPageSetting = checkCookie('listViewPage'+nextProps.match.params.value.toLowerCase());
        }
        if (notificationSetting == undefined) {
            notificationSetting = 'on';
        }
        
        if ( !this.state.handler ) { 
            this.GetHandler();
        }
        
        if ( !this.state.whoami ) {
            this.WhoAmIQuery();
        }

        this.setState({viewMode:viewModeSetting, notificationSetting:notificationSetting, listViewFilter:listViewFilterSetting,listViewSort:listViewSortSetting, listViewPage:listViewPageSetting})
    },

    ee: function(e) {
        var ee = '837279877769847269697171';
        if (ee.includes(this.state.eestring)) {
            if (this.state.eestring + e.keyCode == ee) {
                this.eedraw();
                setTimeout(this.eeremove,2000);    
            } else {
                if ($('input').is(':focus')) {return};
                if (e.ctrlKey != true && e.metaKey != true) {
                    var eestring = this.state.eestring + e.keyCode;
                    this.setState({eestring: eestring});
                }
            }
        } else {
            this.setState({eestring: ''});
        }
    },

    eedraw: function() {
        $('#content').css('transform','rotateX(20deg)');
        $(document.body).prepend('<span id="ee">Lbh sbhaq gur rtt. Cbfg gb gur jnyy "V sbhaq gur rtt, pna lbh?"</span>');
    },

    eeremove: function() {
        $('#content').css('transform','rotateX(0deg)');
        $('#ee').remove();
    },

    componentWillUnmount: function() {
        removeSessionStorage('whoami');
    },

    componentWillMount: function() {
        //Get landscape/portrait view if the cookie exists
        var viewModeSetting = checkCookie('viewMode');
        var notificationSetting = checkCookie('notification');
        if (this.props.match.params.value) {
            var listViewFilterSetting = checkCookie('listViewFilter'+this.props.match.params.value.toLowerCase());
            var listViewSortSetting = checkCookie('listViewSort'+this.props.match.params.value.toLowerCase());
            var listViewPageSetting = checkCookie('listViewPage'+this.props.match.params.value.toLowerCase());
            globalFilter = listViewFilterSetting;
            globalPage = listViewPageSetting;
            globalSort = listViewSortSetting;
        }
        if (notificationSetting == undefined) {
            notificationSetting = 'on';
        }
        this.setState({viewMode:viewModeSetting, notificationSetting:notificationSetting, listViewFilter:listViewFilterSetting,listViewSort:listViewSortSetting, listViewPage:listViewPageSetting})
    },
    notification: function() {
        //Notification display in update as it will run on every amq message matching 'main'.
        var notification = this.refs.notificationSystem
        //not showing notificaiton on entity due to "flooding" on an entry update that has many entities causing a storm of AMQ messages
        if(activemqwho != 'scot-alerts' && activemqwho != 'scot-admin' && activemqwho!= 'scot-flair' && notification != undefined && activemqwho != this.state.whoami &&activemqwho != "" &&  activemqwho != 'api' && activemqwall != true && activemqtype != 'entity' && this.state.notificationSetting == 'on'){  
            notification.addNotification({
                message: activemqwho + activemqmessage + activemqid,
                level: 'info',
                autoDismiss: 5,
                action: activemqstate != 'delete' ? {
                    label: 'View',
                    callback: function(){
                        window.open('/#/' + activemqtype + '/' + activemqid)
                    }
                } : null
            })
        }
    },
    wall: function() {
        var notification = this.refs.notificationSystem
        var date = new Date(activemqwhen * 1000);
        date = date.toLocaleString();
        if (activemqwall == true) {
            notification.addNotification({
                message: date + ' ' + activemqwho + ': ' + activemqmessage,
                level: 'warning',
                autoDismiss: 0,
            })
            activemqwall = false;
        }
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
        
        if ( this.props.match.params.value ) {
            type = this.props.match.params.value.toLowerCase();   
        }

        return (
            <div>
                <Navbar inverse fixedTop={true} fluid={true}>
                    <Navbar.Header>
                        <Navbar.Brand>
                            <Link to='/' style={{margin:'0', padding:'0'}}><img src='/images/scot.png' style={{width:'50px'}} /></Link>
                        </Navbar.Brand>
                        <Navbar.Toggle />
                    </Navbar.Header>
                    <Navbar.Collapse>
                        <Nav>
                            <LinkContainer to='/alertgroup' activeClassName='active'>
                                <NavItem>Alert</NavItem>
                            </LinkContainer>
                            <LinkContainer to='/event' activeClassName='active'>
                                <NavItem>Event</NavItem>
                            </LinkContainer>
                            <LinkContainer to='/incident' activeClassName='active'>
                                <NavItem>Incident</NavItem>
                            </LinkContainer>
                            <LinkContainer to='/intel' activeClassName='active'>
                                <NavItem>Intel</NavItem>
                            </LinkContainer>
                            <NavDropdown id='nav-dropdown' title={'More'}>
                                <LinkContainer to='/task' activeClassName='active'>
                                    <MenuItem>Task</MenuItem>
                                </LinkContainer>
                                <LinkContainer to='/guide' activeClassName='active'>
                                    <MenuItem>Guide</MenuItem>
                                </LinkContainer>
                                <MenuItem href='/revl.html#/visualization'>Visualization</MenuItem>
                                <LinkContainer to='/signature' activeClassName='active'>
                                    <MenuItem>Signature</MenuItem>
                                </LinkContainer>
                                <LinkContainer to='/entity' activeClassName='active'>
                                    <MenuItem>Entity</MenuItem>
                                </LinkContainer>
                                <LinkContainer to='/reports' activeClassName='active'>
                                    <MenuItem>Reports</MenuItem>
                                </LinkContainer>
                                <MenuItem divider />
                                <MenuItem href='/admin/index.html'>Administration</MenuItem>
                                <MenuItem href='/docs/index.html'>Documentation</MenuItem>
                                <MenuItem divider />
                                <MenuItem href='/cyberchef.htm'>Cyber Chef</MenuItem>
                                <MenuItem divider />
                                <MenuItem href='/#/' onClick={this.LogOut} >Log Out</MenuItem>
                            </NavDropdown>
                            <NavItem href='/incident_handler.html'>{IH}</NavItem>
                        </Nav>
                        <span id='ouo_warning' className='ouo-warning'>{this.state.sensitivity}</span>
                        <Search errorToggle={this.errorToggle} />
                    </Navbar.Collapse>
                </Navbar>
                <div className='mainNavPadding'>
                    <Login csrf={this.state.csrf} modalActive={this.state.login} loginToggle={this.loginToggle} WhoAmIQuery={this.WhoAmIQuery} GetHandler={this.GetHandler} errorToggle={this.errorToggle} />
                    <Notification ref='notificationSystem' />
                    {!type || type == 'home' ? 
                    <div className="homePageDisplay">
                        <div className='col-md-4'>
                            <img src='/images/scot-600h.png' style={{maxWidth:'350px',width:'100%',marginLeft:'auto', marginRight:'auto', display: 'block'}}/>
                            <h1>Sandia Cyber Omni Tracker 3.5</h1>
                            <h1>{this.state.sensitivity}</h1>
                            { !this.state.login ? 
                                <Status errorToggle={this.errorToggle} />
                            :
                                null
                            }
                        </div>
                        { !this.state.login ? 
                            <div>
                                <Gamification errorToggle={this.errorToggle} />
                                <Online errorToggle={this.errorToggle} />
                                <ReportDashboard />
                            </div>
                        :
                            null
                        }
                    </div>
                    :
                    null}
                    { type == 'alert' ? 
                        <ListView id={this.props.match.params.id} id2={this.props.match.params.id2} viewMode={this.state.viewMode} type={type} notificationToggle={this.notificationToggle} notificationSetting={this.state.notificationSetting} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} errorToggle={this.errorToggle} history={this.props.history}/>
                    :
                    null}
                    { type == 'alertgroup' ? 
                        <ListView id={this.props.match.params.id} id2={this.props.match.params.id2} viewMode={this.state.viewMode} type={type} notificationToggle={this.notificationToggle} notificationSetting={this.state.notificationSetting} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} errorToggle={this.errorToggle} history={this.props.history}/>
                    :
                    null}
                    { type == 'entry' ?
                        <ListView id={this.props.match.params.id} id2={this.props.match.params.id2} viewMode={this.state.viewMode} type={type} notificationToggle={this.notificationToggle} notificationSetting={this.state.notificationSetting} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} errorToggle={this.errorToggle} history={this.props.history}/>
                    :
                    null}
                    {type == 'event' ?
                        <ListView id={this.props.match.params.id} id2={this.props.match.params.id2} viewMode={this.state.viewMode} type={type} notificationToggle={this.notificationToggle} notificationSetting={this.state.notificationSetting} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} errorToggle={this.errorToggle} history={this.props.history}/>
                    :
                    null}
                    {type == 'incident' ?
                        <ListView id={this.props.match.params.id} id2={this.props.match.params.id2} viewMode={this.state.viewMode} type={type} notificationToggle={this.notificationToggle} notificationSetting={this.state.notificationSetting} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} errorToggle={this.errorToggle} history={this.props.history}/>
                    :
                    null} 
                    {type == 'task' ?
                        <ListView isTask={true} queryType={this.props.match.params.type} viewMode={this.state.viewMode} type={this.props.match.params.value} id={this.props.match.params.id} id2={this.props.match.params.id2} notificationToggle={this.notificationToggle} notificationSetting={this.state.notificationSetting} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} errorToggle={this.errorToggle} history={this.props.history}/>
                    :
                    null}
                    {type == 'guide' ?
                        <ListView id={this.props.match.params.id} id2={this.props.match.params.id2} viewMode={this.state.viewMode} type={type} notificationToggle={this.notificationToggle} notificationSetting={this.state.notificationSetting} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} errorToggle={this.errorToggle} history={this.props.history}/>
                    :
                    null}
                    {type == 'intel' ?
                        <ListView id={this.props.match.params.id} id2={this.props.match.params.id2} viewMode={this.state.viewMode} type={type} notificationToggle={this.notificationToggle} notificationSetting={this.state.notificationSetting} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} errorToggle={this.errorToggle} history={this.props.history}/>
                    :
                    null}
                    {type == 'signature' ?
                        <ListView id={this.props.match.params.id} id2={this.props.match.params.id2} viewMode={this.state.viewMode} type={type} notificationToggle={this.notificationToggle} notificationSetting={this.state.notificationSetting} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} errorToggle={this.errorToggle} history={this.props.history}/>
                    :
                    null}
                    {type == 'entity' ?
                        <ListView id={this.props.match.params.id} id2={this.props.match.params.id2} viewMode={this.state.viewMode} type={type} notificationToggle={this.notificationToggle} notificationSetting={this.state.notificationSetting} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} errorToggle={this.errorToggle} history={this.props.history}/>
                    :
                    null}
                    {type == 'visualization' ?
                        <Revl value={type} type={this.props.match.params.type} id={this.props.match.params.id} depth={this.props.match.params.id2} viewMode={this.state.viewMode} Notification={this.state.Notification} />
                    :
                    null}
                    {type === 'reports' && !this.props.match.params.id &&
                        <ReportPage />
                    }
					{type === 'reports' && this.props.match.params.id &&
						<SingleReport reportType={this.props.match.params.id} />
					}
                    {type == 'amq' ?
                        <AMQ type='amq' errorToggle={this.errorToggle} />
                    :
                    null}
                    {type == 'wall' ?
                        <Wall errorToggle={this.errorToggle} />
                    :
                    null}
                </div>
            </div>
        )
    },
});

    ReactDOM.render((
        <HashRouter history={customHistory()}>
            <Switch>
                <Route exact path = '/' component = {App} />
                <Route exact path = '/:value' component = {App} />
                <Route exact path = '/:value/:id' component = {App} />
                <Route exact path = '/:value/:id/:id2' component = {App} />
                <Route path = '/:value/:type/:id/:id2' component = {App} />
            </Switch>
        </HashRouter>
    ), document.getElementById('content'))

