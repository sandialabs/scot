'use strict';
var ReactDOM	    = require('react-dom')
var React           = require('react')
var Navbar          = require('react-bootstrap/lib/Navbar.js');
var Nav             = require('react-bootstrap/lib/Nav.js');
var NavItem         = require('react-bootstrap/lib/NavItem.js');
var NavDropdown     = require('react-bootstrap/lib/NavDropdown.js');
var MenuItem        = require('react-bootstrap/lib/MenuItem.js');
var ListView        = require('../list/list-view.jsx');
var Router	        = require('../../../node_modules/react-router').Router
var Route	        = require('../../../node_modules/react-router').Route
var Link	        = require('../../../node_modules/react-router').Link
var browserHistory  = require('../../../node_modules/react-router/').hashHistory
var Listener        = require('../activemq/listener.jsx')
var Store           = require('../activemq/store.jsx');
var SelectedContainer = require('../detail/selected_container.jsx')
var EntityDetail      = require('../modal/entity_detail.jsx')
var AMQ             = require('../debug-components/amq.jsx');
var Wall            = require('../debug-components/wall.jsx');
var Search          = require('../components/esearch.jsx');
var Revl            = require('../components/visualization/revl.coffee');
var Gamification    = require('../components/dashboard/gamification.jsx');
var Status          = require('../components/dashboard/status.jsx');
var Online          = require('../components/dashboard/online.jsx');
var Report          = require('../components/dashboard/report.jsx');
var Notification    = require('react-notification-system');
var isalert = false
{
	window.React = React;	
	var $ = window.$;

}

var App = React.createClass({

    getInitialState: function(){
	    var id;
        var id2;
        var type = this.props.params.value;
        var activeKey = 0;
        if(type != null){
            if( type.toLowerCase() == "alert"){
                if(this.props.params.id != null){
                    id = this.props.params.id
                    type = 'alert'
                }
                //if the url is just /alert/ with no id - default to alertgroup
                else { 
                    id = null;
                    type = 'alertgroup'
                    isalert = false
                }
                activeKey = 1;
            }
            else if( type.toLowerCase() == "alertgroup"){
                activeKey = 1;
            }
            else if (type.toLowerCase() == "event"){
                activeKey = 2;
            }
            else if (type.toLowerCase() == "incident"){
                activeKey = 3;
            }
            else if(type.toLowerCase() == "task")  {
                activeKey = 4;
            }  
            else if(type.toLowerCase() == 'guide'){
                activeKey = 5;
            }
            else if(type.toLowerCase() == "intel") {
                activeKey = 6;    
            }
            else if(type.toLowerCase() == "signature") {
                activeKey = 7;
            }
            else if(type.toLowerCase() == 'visualization'){
                activeKey = 8;
            }
            else if(type.toLowerCase() == 'entity'){
                activeKey = 10;        
            }
            else if (type.toLowerCase() == 'report') {
                activeKey = 12;
            }
            else if (type.toLowerCase() == "amq") {
                activeKey = 99; 
            }
            else if (type.toLowerCase() == 'wall') {
                activeKey = 100;
            }
            else {
               type = ''; 
            }
        }
        else {
            type = ''
        }
        Listener.activeMq();   //register for amq updates
        return{id: this.props.params.id, id2: this.props.params.id2, handler: "Scot", viewMode:'default', notificationSetting: 'on', eestring: '', type:type.toLowerCase(), activeKey:activeKey}	
    },
    componentDidMount: function() {
	    $.ajax({
	        type: 'get',
	        url: '/scot/api/v2/handler?current=1'
	    }).success(function(response){
	        this.setState({handler: response.records[0].username})
	    }.bind(this))
        Store.storeKey('wall');
        Store.addChangeListener(this.wall);
        Store.storeKey('notification');
        Store.addChangeListener(this.notification);
       
        //ee
        if (this.state.type == '') {
            $(document.body).keydown(function(e) {
                this.ee(e);
            }.bind(this))   
        }
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
        $(document.body).prepend('<span id="ee">Lbh sbhaq gur egg. Cbfg gb gur jnyy "V sbhaq gur rtt, pna lbh?"</span>');
    },
    eeremove: function() {
        $('#content').css('transform','rotateX(0deg)');
        $('#ee').remove();
    },
    componentWillMount: function() {
        //Get landscape/portrait view if the cookie exists
        var viewModeSetting = checkCookie('viewMode');
        var notificationSetting = checkCookie('notification');
        var listViewFilterSetting = checkCookie('listViewFilter'+this.state.type.toLowerCase());
        var listViewSortSetting = checkCookie('listViewSort'+this.state.type.toLowerCase());
        var listViewPageSetting = checkCookie('listViewPage'+this.state.type.toLowerCase());
        if (notificationSetting == undefined) {
            notificationSetting = 'on';
        }
        this.setState({viewMode:viewModeSetting, notificationSetting:notificationSetting, listViewFilter:listViewFilterSetting,listViewSort:listViewSortSetting, listViewPage:listViewPageSetting})
    },
    notification: function() {
        //Notification display in update as it will run on every amq message matching 'main'.
        var notification = this.refs.notificationSystem
        //not showing notificaiton on entity due to "flooding" on an entry update that has many entities causing a storm of AMQ messages
        if(activemqwho != 'scot-alerts' && activemqwho != 'scot-admin' && activemqwho!= 'scot-flair' && whoami != activemqwho && notification != undefined && activemqwho != "" &&  activemqwho != 'api' && activemqwall != true && activemqtype != 'entity' && this.state.notificationSetting == 'on'){  
            notification.addNotification({
                message: activemqwho + activemqmessage + activemqid,
                level: 'info',
                autoDismiss: 5,
                action: activemqstate != 'delete' ? {
                    label: 'View',
                    callback: function(){
                        if(activemqtype == 'entry' || activemqtype == 'alert'){
                            activemqid = activemqsetentry
                            activemqtype = activemqsetentrytype
                        }
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
    errorToggle: function(string) {
        var notification = this.refs.notificationSystem
        notification.addNotification({
            message: string,
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
   render: function() {
        var IH = 'Incident Handler: ' + this.state.handler;
        var type = this.state.type;
        return (
            <div>
                <Navbar inverse fixedTop={true} fluid={true}>
                    <Navbar.Header>
                        <Navbar.Brand>
                            <a href='/#' style={{margin:'0', padding:'0'}}><img src='/images/scot.png' style={{width:'50px'}} /></a>
                        </Navbar.Brand>
                        <Navbar.Toggle />
                    </Navbar.Header>
                    <Navbar.Collapse>
                        <Nav onSelect={this.handleSelect} activeKey={this.state.activeKey}>
                            <NavItem eventKey={1} href="/#/alertgroup">Alert</NavItem>
                            <NavItem eventKey={2} href="/#/event">Event</NavItem>
                            <NavItem eventKey={3} href="/#/incident">Incident</NavItem>
                            <NavItem eventKey={6} href="/#/intel" >Intel</NavItem>
                            <NavDropdown eventKey={10} id='nav-dropdown' title={'More'}>
                                <MenuItem eventKey={4} href="/#/task">Task</MenuItem>
                                <MenuItem eventKey={5} href="/#/guide">Guide</MenuItem>
                                <MenuItem eventKey={8} href="/revl.html/#/visualization">Visualization</MenuItem>
                                <MenuItem eventKey={7} href="/#/signature">Signature</MenuItem>
                                <MenuItem eventKey={10} href="/#/entity">Entity</MenuItem>
                                <MenuItem eventKey={12} href="/#/report">Report</MenuItem>
                                <MenuItem divider />
                                <MenuItem eventKey={11.1} href='/admin/index.html'>Administration</MenuItem>
                                <MenuItem eventKey={11.2} href='/docs/index.html'>Documentation</MenuItem>
                            </NavDropdown>
                            <NavItem eventKey={9} href="/incident_handler">{IH}</NavItem>
                        </Nav>
                        <span id='ouo_warning' className='ouo-warning'>{sensitivity}</span>
                        <Search errorToggle={this.errorToggle} />
                    </Navbar.Collapse>
                </Navbar>
                <div className='mainNavPadding'>
                    <Notification ref='notificationSystem' />
                    {this.state.type == '' || this.state.type == 'home' ? 
                    <div className="homePageDisplay">
                        <div className='col-md-4'>
                            <img src='/images/scot-600h.png' style={{maxWidth:'350px',width:'100%',marginLeft:'auto', marginRight:'auto', display: 'block'}}/>
                            <h1>Sandia Cyber Omni Tracker 3.5</h1>
                            <h1>{sensitivity}</h1>
                            <Status />
                        </div>
                        <Gamification />
                        <Online />
                        <Report frontPage={true} />
                    </div>
                    :
                    null}
                    {this.state.type == 'alert' || this.state.type == 'alertgroup' ?
                        <ListView isalert={isalert ? 'isalert' : ''} id={this.state.id} viewMode={this.state.viewMode} type={this.state.type} notificationToggle={this.notificationToggle} notificationSetting={this.state.notificationSetting}  listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} errorToggle={this.errorToggle}/>
                    :
                    null}
                    {this.state.type == 'event' || this.state.type == 'incident' || this.state.type == 'task' || this.state.type == 'guide' || this.state.type == 'intel' || this.state.type == 'signature' || this.state.type == 'entity' ? 
                        <ListView id={this.state.id} id2={this.state.id2} viewMode={this.state.viewMode} type={this.state.type} notificationToggle={this.notificationToggle} notificationSetting={this.state.notificationSetting} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} errorToggle={this.errorToggle}/>
                    :
                    null}
                    {this.state.type == 'visualization' ?
                        <Revl value={this.props.params.value} type={this.props.params.id} id={this.props.params.type} depth={this.props.params.typeid} viewMode={this.state.viewMode} Notification={this.state.Notification} />
                    :
                    null}
                    {this.state.type == 'report' ?
                        <Report id={this.state.id} id2={this.state.id2} viewMode={this.state.viewMode} type={this.state.type} notificationToggle={this.notificationToggle} notificationSetting={this.state.notificationSetting} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} errorToggle={this.errorToggle}/>
                    :
                    null}
                    {this.state.type == 'amq' ?
                        <AMQ type='amq' />
                    :
                    null}
                    {this.state.type == 'wall' ?
                        <Wall />
                    :
                    null}
                </div>
            </div>
        )
    },
    handleSelect: function(selectedKey) {
        switch(selectedKey) {
            case 0:
                this.setState({type:''});
                break;
            case 1:
                window.open('/#/alertgroup','_self');
                //window.location.hash = '/#/alertgroup';
                //window.location.href = window.location.hash;
                break;
            case 2:
                window.open('/#/event','_self');
                //window.location.hash = '/#/event';
                //window.location.href = window.location.hash;
                break;
            case 3:
                window.open('/#/incident','_self');
                //window.location.hash = '/#/incident';
                //window.location.href = window.location.hash;
                break;
            case 4:
                window.open('/#/task','_self');
                //window.location.hash = '/#/task';
                //window.location.href = window.location.hash;
                break;
            case 5:
                window.open('/#/guide','_self');
                //window.location.hash = '/#/guide';
                //window.location.href = window.location.hash;
                break;
            case 6:
                window.open('/#/intel','_self');
                //window.location.hash = '/#/intel';
                //window.location.href = window.location.hash;
                break;
            case 7:
                window.open('/#/signature','_self');
                //window.location.hash = '/#/signature';
                //window.location.href = window.location.hash;
                break;
            case 8:
                //window.location.hash = 'revl.html/#/visualization';
                //window.location.href = window.location.hash;
                window.open('/revl.html/#/visualization','_self');
                break;
            case 9:
                window.open('/incident_handler.html','_self');
                break;
            case 10:
                window.open('/#/entity','_self');
                //window.location.hash = '/#/entity';
                //window.location.href = window.location.hash;
       }
    },
});

    ReactDOM.render((
        <Router history = {browserHistory}>
        <Route path = '/' component = {App} />
        <Route path = '/:value' component = {App} />
        <Route path = '/:value/:id' component = {App} />
        <Route path = '/:value/:id/:id2' component = {App} />
        <Route path = '/:value/:id/:type/:typeid' component = {App} />
        </Router>
    ), document.getElementById('content'))

