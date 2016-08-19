'use strict';
var ReactDOM	    = require('react-dom')
var React           = require('react')
var ExpandableNav   = require('../../../node_modules/react-expandable-nav')
var Alerts          = require('./alert.jsx')
var Events          = require('./events.jsx')
var Incidents       = require('./incidents.jsx')
var Tasks           = require('./tasks.jsx')
var Intel           = require('./intel.jsx')
var Router	        = require('../../../node_modules/react-router').Router
var Route	        = require('../../../node_modules/react-router').Route
var Link	        = require('../../../node_modules/react-router').Link
var browserHistory  = require('../../../node_modules/react-router/').hashHistory
var Listener        = require('../activemq/listener.jsx')
var Store           = require('../flux/store.jsx')
var Guide           = require('./guide.jsx')
var ExpandableNavContainer = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavContainer.js')
var ExpandableNavbar = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavbar.js')
var ExpandableNavHeader = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavHeader.js')
var ExpandableNavMenu = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavMenu.js')
var ExpandableNavMenuItem = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavMenuItem.js')
var ExpandableNavPage = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavPage.js')
var ExpandableNavToggleButton = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavToggleButton.js')
var SelectedContainer = require('../entry/selected_container.jsx')
var EntityDetail      = require('../modal/entity_detail.jsx')
var sethome = false
var setalerts = false
var setevents = false
var setincidents = false
var setintel = false
var settask = false
var setguide = false
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
	    var array = []
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
            }
        else if(this.props.params.value.toLowerCase() == 'entity'){
            setguide = false
            setevents = false	
            setintel = false
            sethome = false
            setalerts = false
            setincidents = false
            settask = false
            if(this.props.params.id != null) {
	            state = 8
	            array = this.props.params.id.split('+')
	            array.push(this.props.params.type)
                array.push(this.props.params.typeid)
            }
        }
        else if(this.props.params.value.toLowerCase() == 'guide'){
            setguide = true
            setevents = false	
            setintel = false
            sethome = false
            setalerts = false
            setincidents = false
            settask = false
            state = 7
            if(this.props.params.id != null) {
	            state = 7
	            statetype = 'guide'	
	            array = this.props.params.id.split('+')
	        }
        }
	    else if( this.props.params.value.toLowerCase() == "alert"){
	        if(this.props.params.id != null){
	            supertableid = this.props.params.id.split('+')
	        }
	        state = 1
            isalert = true
	        setalerts = true
	        setintel = false
	        sethome = false
	        setincidents = false
	        setevents = false
	        settask = false
            setguide = false
	    }
	    else if( this.props.params.value.toLowerCase() == "alertgroup"){
	        if(this.props.params.id != null){
	            supertableid = this.props.params.id.split('+')
	        }
            isalert = false
	        state = 1
	        setalerts = true
	        setintel = false
	        sethome = false
	        setincidents = false
	        setevents = false
	        settask = false
            setguide = false
	    }
	    else if(this.props.params.value.toLowerCase() == "event"){
	        state = 2
	        if(this.props.params.id != null) {
	            state = 2
	            statetype = 'event'	
	            array = this.props.params.id.split('+')
	        }
	        setevents = true	
	        setintel = false
	        sethome = false
	        setalerts = false
	        setincidents = false
	        settask = false
	        setguide = false
        }
	    else if (this.props.params.value.toLowerCase() == "incident"){
	        state = 3
	        if(this.props.params.id != null) {
	            state = 3
	            statetype = 'incident'	
	            array = this.props.params.id.split('+')
	        }
            setguide = false
            setincidents = true
            setintel = false
            sethome = false
            setalerts = false
            setevents = false
            settask = false
	    }
	    else if(this.props.params.value.toLowerCase() == "intel") {
	        state = 4
	        if(this.props.params.id != null) {
	            state = 4
	            statetype = 'intel'	
	            array = this.props.params.id.split('+')
	        }
            setguide = false
            setintel = true
            sethome = false
            setalerts = false
            setincidents = false
            setevents = false
            settask = false
	    }
	    else if(this.props.params.value.toLowerCase() == "task")  {
            state = 6
            setguide = false
            sethome = false
            setalerts = false
            setevents = false
            setincidents = false
            setintel = false
            settask = true
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
        }
    }
        else {
            this.props.params.value = ''
            state = 0
        }
	        return{ids: array,set: state, handler: "Scot", viewMode:'default'}	
    },
   componentWillMount: function() {
	    $.ajax({
	        type: 'get',
	        url: '/scot/api/v2/handler?current=1'
	    }).success(function(response){
	        this.setState({handler: response.records['username']})
	        }.bind(this))
        //Get landscape/portrait view if the cookie exists
        var viewModeSetting = checkCookie('viewMode');
        this.setState({viewMode:viewModeSetting})
    },
   render: function() {
	    var array = []
	    var id = window.location.hash
	    array = id.split('/')	
	    $('.active').on('click', function(){
	        window.location.hash = '#/' + array[1] + '/'
	        window.location.href = window.location.hash
	    })
	    var headerFull = <a href='/'>Scot3</a>
        var headerSmall = ""
        var menuItemsSmall = [
        <span className = "glyphicon glyphicon-home"></span>,
        <span className = "glyphicon glyphicon-eye-open"></span>,
        <span className = "glyphicon glyphicon-warning-sign"></span>,
        <span className = "glyphicon glyphicon-list-alt"></span>,
        <span className = "glyphicon glyphicon-screenshot"></span>,
        <span className = "glyphicon glyphicon-edit"></span>,
        <span className = "glyphicon glyphicon-pencil"></span>,
      //  <span className = "glyphicon glyphicon-cog"></span>,
        <span className = "glyphicon glyphicon-user"></span>,
        ]	

        var menuItemsFull = [
        <span>Home</span>,
        <span>Intel</span>,
        <span>Alert</span>,
        <span>Event</span>,
        <span>Incident</span>,
        <span>Tasks</span>,
        <span>Guide</span>,
        //<span>Admin</span>,
        <span>Incident Handler : {this.state.handler}</span>,
        ];
        var headerStyle = { paddingLeft: 5 };
        var fullStyle   = { paddingLeft: 50};
        
        setTimeout(function(){Listener.activeMq()}, 3000)

    return (
        React.createElement(ExpandableNavContainer, {expanded: false}, React.createElement(ExpandableNavToggleButton, {smallClass: "s", className: "shared"}),
                React.createElement(ExpandableNavbar, {fullClass: "full", smallClass: "small"}, 
                React.createElement(ExpandableNavHeader, {small: headerSmall, full: headerFull, headerStyle: headerStyle, fullStyle: fullStyle}), 
                
            React.createElement(ExpandableNavMenu, null, React.createElement(ExpandableNavMenuItem, {url: '#/home',active: sethome,small: menuItemsSmall[0], full: menuItemsFull[0], tooltip: "Home", jquery: window.$ ,onClick : this.handleHome}),
            React.createElement(ExpandableNavMenuItem, {active: setintel,small: menuItemsSmall[1], full: menuItemsFull[1], tooltip: "Intel", jquery: window.$, onClick: this.handleIntel}),
                    React.createElement(ExpandableNavMenuItem, {active:setalerts ,small: menuItemsSmall[2], full: menuItemsFull[2], tooltip: "Alert", jquery: window.$, onClick: this.handleAlerts}),
                React.createElement(ExpandableNavMenuItem, {active: setevents,small: menuItemsSmall[3], full: menuItemsFull[3], tooltip: "Event", jquery: window.$,onClick: this.handleEvents}),
                React.createElement(ExpandableNavMenuItem, {active: setincidents,small: menuItemsSmall[4], full: menuItemsFull[4], tooltip: "Incident", jquery: window.$, onClick: this.handleIncidents}),
                    React.createElement(ExpandableNavMenuItem, {active: settask, small: menuItemsSmall[5], full: menuItemsFull[5], tooltip: "Task", jquery: window.$, onClick: this.handleTasks}),
            React.createElement(ExpandableNavMenuItem, {active: setguide, small: menuItemsSmall[6], full: menuItemsFull[6], tooltip: "Guide", jquery: window.$, onClick: this.handleGuide}),
        //            React.createElement(ExpandableNavMenuItem, {small: menuItemsSmall[7], full: menuItemsFull[7], tooltip: "Admin", jquery: window.$, onClick:this.handlePad}),
                    React.createElement(ExpandableNavMenuItem, {small: menuItemsSmall[7], full: menuItemsFull[7], tooltip: "Incident Handler:  " + this.state.handler, jquery: window.$, onClick: this.handleHandler}) 
                )

            ),
            this.state.set == 0 
        ?
        React.createElement(ExpandableNavPage, null, React.createElement('div', {className: 'Text'}, React.createElement('img', {src: 'scot.png', style: {width:'350px', height: '320px','margin-left':'auto', 'margin-right':'auto', display: 'block'}}), React.createElement('h1', null, "Sandia Cyber Omni Tracker, v. 3.5"), React.createElement('h1', null, 'Official Use Only')))  
            :
        this.state.set == 1
        ?	
        React.createElement(ExpandableNavPage, null, React.createElement(Alerts, {isalert: isalert ? 'isalert' : '', supertable: supertableid, viewMode: this.state.viewMode}))	
        :
            this.state.set == 2
        ?
        React.createElement(ExpandableNavPage, null, React.createElement(Events, {ids: this.state.ids, viewMode: this.state.viewMode}))	
        :
            this.state.set == 3
        ?
        React.createElement(ExpandableNavPage, null, React.createElement(Incidents, {ids: this.state.ids, viewMode: this.state.viewMode}))	
        :
        this.state.set == 5
        ?
        React.createElement(ExpandableNavPage, null, React.createElement(SelectedContainer, {ids: this.state.ids, type: statetype, viewMode: this.state.viewMode}))
        :
        this.state.set == 4
        ?
        React.createElement(ExpandableNavPage, null, React.createElement(Intel, {ids: this.state.ids, viewMode: this.state.viewMode}))
        :
        this.state.set == 6
        ?	
        React.createElement(ExpandableNavPage, null, React.createElement(Tasks, {viewMode: this.state.viewMode}))	
        :
        this.state.set == 7
        ?
        React.createElement(ExpandableNavPage, null, React.createElement(Guide, {ids: this.state.ids, viewMode: this.state.viewMode}))
        :
        this.state.set == 8
        ?
        React.createElement(ExpandableNavPage, null, React.createElement(EntityDetail, {entityid: this.state.ids[0], type: this.state.ids[1], id: this.state.ids[2], viewMode: this.state.viewMode}))
        :
        null
        )	
        );

    },
    handleGuide: function(){
        window.location.hash = '#/guide/'
        window.location.href = window.location.hash
    },
    handleIntel: function(){
        window.location.hash = '#/intel/'
        window.location.href = window.location.hash
    },
    handleHome: function(){
        this.setState({set:0})
    }, 
    handleHandler: function(){
	    window.open('incident_handler.html')
    },
    handleAlerts: function(){
        window.location.hash = '#/alertgroup/'
        window.location.href = window.location.hash
    },
    handleEvents: function(){
        window.location.hash = '#/event/'
        window.location.href = window.location.hash
    },
    handleIncidents: function(){
        window.location.hash = '#/incident/'
        window.location.href = window.location.hash
    },
    handleTasks: function(){
        window.location.hash = '#/task/'
        window.location.href = window.location.hash
    },
    handleChat: function (){
	    window.open('/scot/chat/irt')
    },
    handlePad: function(){
	    //window.open('scratchpad.html')
    },
    handlePlugin: function(){
	    window.open('plugin.html')
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

