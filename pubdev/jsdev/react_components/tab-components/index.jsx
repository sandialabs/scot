'use strict';
var ReactDOM	    = require('react-dom')
var React           = require('react')
var ExpandableNav   = require('../../../node_modules/react-expandable-nav')
var Alerts          = require('./alert.jsx')
var Events          = require('./events.jsx')
var Incidents       = require('./incidents.jsx')
var Tasks           = require('./tasks.jsx')
var ExpandableNavContainer = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavContainer.js')
var ExpandableNavbar = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavbar.js')
var ExpandableNavHeader = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavHeader.js')
var ExpandableNavMenu = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavMenu.js')
var ExpandableNavMenuItem = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavMenuItem.js')
var ExpandableNavPage = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavPage.js')
var ExpandableNavToggleButton = require('../../../node_modules/react-expandable-nav/build/components/ExpandableNavToggleButton.js')

{
	window.React = React;	
	var $ = window.$;

}

var App = React.createClass({

   getInitialState: function(){
	return{set: 0, handler: "Scot"}
	
   },

   componentDidMount: function() {
	$.ajax({
	    type: 'get',
	    url: '/scot/current_handler'
	}).done(function(response){
	    this.setState({handler: response.handler})
	})
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
          React.createElement(ExpandableNavMenu, null, 
            React.createElement(ExpandableNavMenuItem, {small: menuItemsSmall[0], full: menuItemsFull[0], tooltip: "Home", jquery: window.$ ,onClick : this.handleHome}), 
            React.createElement(ExpandableNavMenuItem, {small: menuItemsSmall[1], full: menuItemsFull[1], tooltip: "Incident Handler", jquery: window.$, onClick: this.handleHandler}), 
            React.createElement(ExpandableNavMenuItem, {small: menuItemsSmall[2], full: menuItemsFull[2], tooltip: "Alerts", jquery: window.$, onClick: this.handleAlerts}),
	    React.createElement(ExpandableNavMenuItem, {small: menuItemsSmall[3], full: menuItemsFull[3], tooltip: "Events", jquery: window.$,onClick: this.handleEvents}),
	    React.createElement(ExpandableNavMenuItem, {small: menuItemsSmall[4], full: menuItemsFull[4], tooltip: "Incidents", jquery: window.$, onClick: this.handleIncidents}),
            React.createElement(ExpandableNavMenuItem, {small: menuItemsSmall[5], full: menuItemsFull[5], tooltip: "Tasks", jquery: window.$, onClick: this.handleTasks}),
            React.createElement(ExpandableNavMenuItem, {small: menuItemsSmall[6], full: menuItemsFull[6], tooltip: "Chat", jquery: window.$, onClick: this.handleChat}),
            React.createElement(ExpandableNavMenuItem, {small: menuItemsSmall[7], full: menuItemsFull[7], tooltip: "Note Pad", jquery: window.$, onClick:this.handlePad}),
            React.createElement(ExpandableNavMenuItem, {small: menuItemsSmall[8], full: menuItemsFull[8], tooltip: "Plugin", jquery: window.$, onClick: this.handlePlugin})
         )),
        React.createElement(ExpandableNavToggleButton, {smallClass: "s", className: "shared"}),
        this.state.set == 0 
	?
React.createElement(ExpandableNavPage, null, React.createElement('div', {className: 'Text'}, React.createElement('h1', null, "Sandia Cyber Omni Tracker, v. 3.5"), React.createElement('h1', null, 'Official Use Only')))  
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
    React.createElement(App, null)
), document.getElementById('content'))



