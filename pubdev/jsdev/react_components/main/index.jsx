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
var SelectedContainer = require('../detail/selected_container.jsx')
var EntityDetail      = require('../modal/entity_detail.jsx')
var AMQ             = require('../debug-components/amq.jsx');
var Search          = require('../components/esearch.jsx');
var Visualization   = require('../components/visualization.jsx');
var sethome = false
var setalerts = false
var setevents = false
var setincidents = false
var setintel = false
var settask = false
var setguide = false
var setsignature = false
var setamq = false
var setvisualization = false
var isalert = false
var supertableid = [];
var statetype = ''
var eventtableid = []
{
	window.React = React;	
	var $ = window.$;

}

var App = React.createClass({

    getInitialState: function(){
	    var state;
	    var id;
        var id2;
        if(this.props.params.value  != null){
            if(this.props.params.value.toLowerCase() == "home"){
                state = 0;
                sethome = true
                setintel = false
                setalerts = false
                setincidents = false
                setevents = false
                settask = false
                setguide = false
                setamq = false
                setsignature = false
                setvisualization = false
            }
           
            else if( this.props.params.value.toLowerCase() == "alert"){
                if(this.props.params.id != null){
                    id = this.props.params.id
                    //array = this.props.params.id.split('+')
                }
                statetype = 'alert'
                state = 1
                isalert = true
                setalerts = true
                setintel = false
                sethome = false
                setincidents = false
                setevents = false
                settask = false
                setguide = false
                setamq = false
                setsignature = false
                setvisualization = false
                //if the url is just /alert/ with no id - default to alertgroup
                if (this.props.params.id == null) {
                    id = null;
                    statetype = 'alertgroup'
                    isalert = false
                }
            }
            else if( this.props.params.value.toLowerCase() == "alertgroup"){
                if(this.props.params.id != null){
                    //array = this.props.params.id.split('+')
                    id = this.props.params.id;
                }
                statetype='alertgroup'
                isalert = false
                state = 1
                setalerts = true
                setintel = false
                sethome = false
                setincidents = false
                setevents = false
                settask = false
                setguide = false
                setamq = false
                setsignature = false
                setvisualization = false
            }
            else if(this.props.params.value.toLowerCase() == "event"){
                state = 2
                if(this.props.params.id != null) {
                    state = 2
                    statetype = 'event'	
                    //array = this.props.params.id.split('+')
                    id = this.props.params.id
                    id2 = this.props.params.id2
                }
                setevents = true	
                setintel = false
                sethome = false
                setalerts = false
                setincidents = false
                settask = false
                setguide = false
                setamq = false
                setsignature = false
                setvisualization = false
            }
            else if (this.props.params.value.toLowerCase() == "incident"){
                state = 3
                if(this.props.params.id != null) {
                    state = 3
                    statetype = 'incident'	
                    //array = this.props.params.id.split('+')
                    id = this.props.params.id
                    id2 = this.props.params.id2
                }
                setguide = false
                setincidents = true
                setintel = false
                sethome = false
                setalerts = false
                setevents = false
                settask = false
                setamq = false
                setsignature = false
                setvisualization = false
            }
            
            else if(this.props.params.value.toLowerCase() == "task")  {
                state = 4
                setguide = false
                sethome = false
                setalerts = false
                setevents = false
                setincidents = false
                setintel = false
                settask = true
                setamq = false
                setsignature = false
                setvisualization = false
            }  
            else if(this.props.params.value.toLowerCase() == 'guide'){
                setguide = true
                setevents = false	
                setintel = false
                sethome = false
                setalerts = false
                setincidents = false
                settask = false
                setamq = false
                setsignature = false
                setvisualization = false
                state = 5
                statetype = 'guide'
                if(this.props.params.id != null) {
                    state = 5
                    statetype = 'guide'	
                    //array = this.props.params.id.split('+')
                    id = this.props.params.id
                }
            }
            else if(this.props.params.value.toLowerCase() == "intel") {
                state = 6
                if(this.props.params.id != null) {
                    state = 6
                    statetype = 'intel'	
                    //array = this.props.params.id.split('+')
                    id = this.props.params.id
                    id2 = this.props.params.id2
                }
                setguide = false
                setintel = true
                sethome = false
                setalerts = false
                setincidents = false
                setevents = false
                settask = false
                setamq = false
                setsignature = false
                setvisualization = false
            }
            else if(this.props.params.value.toLowerCase() == "signature") {
                state = 7
                if(this.props.params.id != null) {
                    state = 7
                    statetype = 'signature'
                    //array = this.props.params.id.split('+')
                    id = this.props.params.id
                    id2 = this.props.params.id2
                }
                setguide = false
                setintel = true
                sethome = false
                setalerts = false
                setincidents = false
                setevents = false
                settask = false
                setamq = false
                setsignature = true
                setvisualization = false
            }
            else if(this.props.params.value.toLowerCase() == 'visualization'){
                state = 8
                setguide = false
                setintel = false
                sethome = false
                setalerts = false
                setincidents = false
                setevents = false
                settask = false
                setamq = false
                setsignature = false
                setvisualization = true
            }
            else if(this.props.params.value.toLowerCase() == 'entity'){
                setguide = false
                setevents = false	
                setintel = false
                sethome = false
                setalerts = false
                setincidents = false
                settask = false
                setamq = false
                setsignature = false
                setvisualization = false
                if(this.props.params.id != null) {
                    state = 98
                    //array = this.props.params.id.split('+')
                    //array.push(this.props.params.type)
                    //array.push(this.props.params.typeid)
                    id = this.props.params.id
                }
            }
            else if (this.props.params.value.toLowerCase() == "amq") {
                state = 99
                setguide = false
                sethome = false
                setalerts = false
                setevents = false
                setincidents = false
                setintel = false
                settask = false
                setamq = true
                setsignature = false
                setvisualization = false
            }
            else {
                state = 0
                sethome = true
                setalerts = false
                setevents = false
                setincidents = false
                setintel = false
                settask = false
                setguide = false
                setamq = false
                setsignature = false
                setvisualization = false
            }
        }
        else {
            this.props.params.value = ''
            state = 0
        }
        setTimeout(function(){Listener.activeMq()}, 3000)
        return{id: id, id2: id2, set: state, handler: "Scot", viewMode:'default'}	
    },
    componentDidMount: function() {
	    $.ajax({
	        type: 'get',
	        url: '/scot/api/v2/handler?current=1'
	    }).success(function(response){
	        this.setState({handler: response.records[0].username})
	        }.bind(this))
    },
    componentWillMount: function() {
        //Get landscape/portrait view if the cookie exists
        var viewModeSetting = checkCookie('viewMode');
        var NotificationSetting = checkCookie('Notification');
        var listViewFilterSetting = checkCookie('listViewFilter'+this.props.params.value.toLowerCase());
        var listViewSortSetting = checkCookie('listViewSort'+this.props.params.value.toLowerCase());
        var listViewPageSetting = checkCookie('listViewPage'+this.props.params.value.toLowerCase());
        this.setState({viewMode:viewModeSetting, Notification:NotificationSetting, listViewFilter:listViewFilterSetting,listViewSort:listViewSortSetting, listViewPage:listViewPageSetting})
    },
   render: function() {
        var IH = 'Incident Handler: ' + this.state.handler;
        return (
            <div>
                <Navbar inverse fixedTop={true} fluid={true}>
                    <Navbar.Header>
                        <Navbar.Brand>
                            <a href='#' style={{margin:'0', padding:'0'}}><img src='scot.png' style={{width:'50px', margin:'0', padding:'0'}} /></a>
                        </Navbar.Brand>
                        <Navbar.Toggle />
                    </Navbar.Header>
                    <Navbar.Collapse>
                        <Nav onSelect={this.handleSelect}>
                            <NavItem eventKey={1} href="#/alertgroup" active={setalerts}>Alert</NavItem>
                            <NavItem eventKey={2} href="#/event" active={setevents}>Event</NavItem>
                            <NavItem eventKey={3} href="#/incident" active={setincidents}>Incident</NavItem>
                            <NavItem eventKey={4} href="#/task" active={settask}>Task</NavItem>
                            <NavItem eventKey={5} href="#/guide" active={setguide}>Guide</NavItem>
                            <NavItem eventKey={6} href="#/intel" active={setintel}>Intel</NavItem>
                            {/*<NavItem eventKey={7} href="#/signature" active={setsignature} disabled>Signature</NavItem>*/}
                            {/*<NavItem eventKey={8} href="#/visualization" active={setvisualization}>Visualization</NavItem>*/}
                            <NavItem eventKey={9} href="incident_handler">{IH}</NavItem>
                        </Nav>
                            <span id='ouo_warning' className='ouo-warning'>{sensitivity}</span>
                            <div className='col-sm-1 col-md-1 pull-right'>
                                <Search />
                            </div>
                    </Navbar.Collapse>
                </Navbar>
                <div style={{paddingTop:'50px'}}>
                    {this.state.set == 0 ? 
                    <div>
                        <img src='/images/scot-600h.png' style={{width:'350px', height: '320px',marginLeft:'auto', marginRight:'auto', display: 'block'}}/>
                        <h1>Sandia Cyber Omni Tracker 3.5</h1>
                        <h1>{sensitivity}</h1>
                    </div>
                    :
                    null}
                    {this.state.set == 1 ?
                        <ListView isalert={isalert ? 'isalert' : ''} id={this.state.id} viewMode={this.state.viewMode} type={statetype} Notification={this.state.Notification} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} />
                    :
                    null}
                    {this.state.set == 2 ? 
                        <ListView id={this.state.id} id2={this.state.id2} viewMode={this.state.viewMode} type={'event'} Notification={this.state.notification} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} />
                    :
                    null}
                    {this.state.set == 3 ? 
                        <ListView id={this.state.id} id2={this.state.id2} viewMode={this.state.viewMode} type={'incident'}  Notification={this.state.Notification} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} />
                    :
                    null}
                    {this.state.set == 4 ?
                        <ListView id={this.state.id} id2={this.state.id2} viewMode={this.state.viewMode} type={'task'} Notification={this.state.Notification} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} />
                    :
                    null}
                    {this.state.set == 5 ?
                        <ListView id={this.state.id} type={'guide'} viewMode={this.state.viewMode} Notification={this.state.Notification} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} />
                    :
                    null}
                    {this.state.set == 6 ?
                        <ListView id={this.state.id} id2={this.state.id2} viewMode={this.state.viewMode} type={'intel'} Notification={this.state.Notification} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} /> 
                    :
                    null}
                    {this.state.set == 7 ?
                        <ListView id={this.state.id} id2={this.state.id2} viewMode={this.state.viewMode} type={'signature'} Notification={this.state.Notification} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} /> 
                    :
                    null}
                    {this.state.set == 8 ?
                        <Visualization value={this.props.params.value} type={this.props.params.id} id={this.props.params.type} depth={this.props.params.typeid} viewMode={this.state.viewMode} Notification={this.state.Notification} /> 
                    :
                    null}
                    {this.state.set == 98 ?
                        <EntityDetail entityid={this.state.id} entitytype={'entity'} id={this.state.id} type={'entity'} viewMode={this.state.viewMode} Notification={this.state.Notification} listViewFilter={this.state.listViewFilter} listViewSort={this.state.listViewSort} listViewPage={this.state.listViewPage} fullScreen={true} />
                    :
                    null}
                    {this.state.set == 99 ?
                        <AMQ type='amq' />
                    :
                    null}
                </div>
            </div>
        )
    },
    handleSelect: function(selectedKey) {
        switch(selectedKey) {
            case 0:
                this.setState({set:0});
                break;
            case 1:
                window.location.hash = '#/alertgroup';
                window.location.href = window.location.hash;
                break;
            case 2:
                window.location.hash = '#/event';
                window.location.href = window.location.hash;
                break;
            case 3:
                window.location.hash = '#/incident';
                window.location.href = window.location.hash;
                break;
            case 4:
                window.location.hash = '#/task';
                window.location.href = window.location.hash;
                break;
            case 5:
                window.location.hash = '#/guide';
                window.location.href = window.location.hash;
                break;
            case 6:
                window.location.hash = '#/intel';
                window.location.href = window.location.hash;
                break;
            case 7:
                window.location.hash = '#/signature';
                window.location.href = window.location.hash;
                break;
            case 8:
                window.location.hash = '#/visualization';
                window.location.href = window.location.hash;
                break;
            case 9:
                window.open('incident_handler.html');
                break;
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

