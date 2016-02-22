'use strict';
var ReactDOM	    = require('react-dom')
var React           = require('react')
var ExpandableNav   = require('../../../node_modules/react-expandable-nav')
var Alerts          = require('./alert.jsx')
var Events          = require('./events.jsx')
var Incidents       = require('./incidents.jsx')
var Tasks           = require('./tasks.jsx')
var Router	    = require('../../../node_modules/react-router').Router
var Route	    = require('../../../node_modules/react-router').Route
var Link	    = require('../../../node_modules/react-router').Link
var browserHistory  = require('../../../node_modules/react-router/').hashHistory
var ExpandableNavContainer = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavContainer.js')
var ExpandableNavbar = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavbar.js')
var ExpandableNavHeader = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavHeader.js')
var ExpandableNavMenu = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavMenu.js')
var ExpandableNavMenuItem = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavMenuItem.js')
var ExpandableNavPage = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavPage.js')
var ExpandableNavToggleButton = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavToggleButton.js')
var SelectedContainer = require('../entry/selected_container.jsx')
var sethome = false
var setalerts = false
var setevents = false
var setincidents = false
var setintel = false
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
	setintel = true
	setalerts = false
	setincidents = false
	setevents = false
	}
	else if( this.props.params.value.toLowerCase() == "alerts"){
	state = 1
	setalerts = true
	setintel = true
	sethome = false
	setincidents = false
	setevents = false
	}
	else if(this.props.params.value.toLowerCase() == "events"){
	state = 2
	if(this.props.params.id != null) {
	if($.isNumeric(this.props.params.id)){
	state = 5	
	array.push(this.props.params.id)
	}
	}
	setevents = true	
	setintel = true
	sethome = false
	setalerts = false
	setincidents = false
	}
	else if (this.props.params.value.toLowerCase() == "incidents"){
	state = 3
	setincidents = true
	setintel = true
	sethome = false
	setalerts = false
	setevents = false
	}
	else if(this.props.params.value.toLowerCase() == "intel") {
	state = 4
	setintel = true
	sethome = false
	setalerts = false
	setincidents = false
	setevents = false
	}
	else {
	state = 0
	sethome = true
	setalerts = false
	setevents = false
	setincidents = false
	setintel = false
	}
}
else {
this.props.params.value = ''
state = 0
}
	return{ids: array,set: state, handler: "Scot"}
	
   },

   componentWillMount: function() {
	$.ajax({
	    type: 'get',
	    url: '/scot/api/v2/handler?current=1'
	}).success(function(response){
	    this.setState({handler: response.records['username']})
	}.bind(this))
   },

   render: function() {
	var headerFull = <a href='/#'>Scot3</a>
	var headerSmall = ""
	var menuItemsSmall = [
	<span className = "glyphicon glyphicon-home"></span>,
        <span className = "glyphicon glyphicon-user"></span>,
        <span className = "glyphicon glyphicon-warning-sign"></span>,
        <span className = "glyphicon glyphicon-list-alt"></span>,
        <span className = "glyphicon glyphicon-screenshot"></span>,
	<span className = "glyphicon glyphicon-edit"></span>,
	<span className = "glyphicon glyphicon-th"></span>,
	<span className = "glyphicon glyphicon-comment"></span>,
	<span className = "glyphicon glyphicon-pencil"></span>,
	<span className = "glyphicon glyphicon-cog"></span>

	]	

	var menuItemsFull = [
	<span>Home</span>,
	<span>Incident Handler : {this.state.handler}</span>,
	<span>Alerts</span>,
	<span>Events</span>,
	<span>Incidents</span>,
	<span>Tasks</span>,
	<span>Intel</span>,
	<span>Chat</span>,
	<span>NotePad</span>,
	<span>Plugin</span>
	];
	var headerStyle = { paddingLeft: 5 };
	var fullStyle   = { paddingLeft: 50};

	return (
React.createElement(ExpandableNavContainer, {expanded: false}, 
        React.createElement(ExpandableNavbar, {fullClass: "full", smallClass: "small"}, 
          React.createElement(ExpandableNavHeader, {small: headerSmall, full: headerFull, headerStyle: headerStyle, fullStyle: fullStyle}), 
           
	React.createElement(ExpandableNavMenu, null, React.createElement(ExpandableNavMenuItem, {url: '#/home',active: sethome,small: menuItemsSmall[0], full: menuItemsFull[0], tooltip: "Home", jquery: window.$ ,onClick : this.handleHome}), 
            React.createElement(ExpandableNavMenuItem, {small: menuItemsSmall[1], full: menuItemsFull[1], tooltip: "Incident Handler", jquery: window.$, onClick: this.handleHandler}), 
            React.createElement(ExpandableNavMenuItem, {url: '#/alerts', active:setalerts ,small: menuItemsSmall[2], full: menuItemsFull[2], tooltip: "Alerts", jquery: window.$, onClick: this.handleAlerts}),
	    React.createElement(ExpandableNavMenuItem, {url: '#/events', active: setevents,small: menuItemsSmall[3], full: menuItemsFull[3], tooltip: "Events", jquery: window.$,onClick: this.handleEvents}),
	    React.createElement(ExpandableNavMenuItem, {url: '#/incidents',active: setincidents,small: menuItemsSmall[4], full: menuItemsFull[4], tooltip: "Incidents", jquery: window.$, onClick: this.handleIncidents}),
            React.createElement(ExpandableNavMenuItem, {url: '#/tasks', small: menuItemsSmall[5], full: menuItemsFull[5], tooltip: "Tasks", jquery: window.$, onClick: this.handleTasks}),
		React.createElement(ExpandableNavMenuItem, {url: '#/intel', active: setintel,small: menuItemsSmall[6], full: menuItemsFull[6], tooltip: "Intel", jquery: window.$, onClick: this.handleTasks}),
            React.createElement(ExpandableNavMenuItem, {small: menuItemsSmall[7], full: menuItemsFull[7], tooltip: "Chat", jquery: window.$, onClick: this.handleChat}),
            React.createElement(ExpandableNavMenuItem, {small: menuItemsSmall[8], full: menuItemsFull[8], tooltip: "Note Pad", jquery: window.$, onClick:this.handlePad}),
            React.createElement(ExpandableNavMenuItem, {small: menuItemsSmall[9], full: menuItemsFull[9], tooltip: "Plugin", jquery: window.$, onClick: this.handlePlugin})
         )),
        React.createElement(ExpandableNavToggleButton, {smallClass: "s", className: "shared"}),
        this.state.set == 0 
	?
React.createElement(ExpandableNavPage, null, React.createElement('div', {className: 'Text'}, React.createElement('img', {src: 'scot.png', style: {width:'350px', height: '320px','margin-left':'auto', 'margin-right':'auto', display: 'block'}}), React.createElement('h1', null, "Sandia Cyber Omni Tracker, v. 3.5"), React.createElement('h1', null, 'Official Use Only')))  
	:
	this.state.set == 1
	?	
	 React.createElement(ExpandableNavPage, null, React.createElement(Alerts, null))	
	:
        this.state.set == 2
	?
	 React.createElement(ExpandableNavPage, null, React.createElement(Events, null))	
	:
        this.state.set == 3
	?
	 React.createElement(ExpandableNavPage, null, React.createElement(Incidents, null))	
	:
	this.state.set == 5
	?
	React.createElement(ExpandableNavPage, null, React.createElement(SelectedContainer, {ids: this.state.ids, type: 'event'}))
	:	
 React.createElement(ExpandableNavPage, null, React.createElement(Tasks, null))	

	)	
    );

  },
    handleHome: function(){
        this.setState({set:0})
    }, 
    handleHandler: function(){
	window.open('incident_handler.html')
    },
    handleAlerts: function(){
	this.setState({set : 1})
    },
    handleEvents: function(){
	this.setState({set: 2})
    },
    handleIncidents: function(){
	this.setState({set : 3})
    },
    handleTasks: function(){
	this.setState({set: 4})
    },
    handleChat: function (){
	window.open('/scot/chat/irt')
    },

    handlePad: function(){
	window.open('scratchpad.html')
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
    </Router>
), document.getElementById('content'))



