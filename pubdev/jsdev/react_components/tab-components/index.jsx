'use strict';
var ReactDOM	    = require('react-dom')
var React           = require('react')
var ExpandableNav   = require('../../../node_modules/react-expandable-nav')
//var Alerts          = require('./alert.jsx')
//var Events          = require('./events.jsx')
//var Incidents       = require('./incidents.jsx')
//var Tasks           = require('./tasks.jsx')
//var Intel           = require('./intel.jsx')
var ListView        = require('./list-view.jsx');
var Router	        = require('../../../node_modules/react-router').Router
var Route	        = require('../../../node_modules/react-router').Route
var Link	        = require('../../../node_modules/react-router').Link
var browserHistory  = require('../../../node_modules/react-router/').hashHistory
var Listener        = require('../activemq/listener.jsx')
var Store           = require('../flux/store.jsx')
//var Guide           = require('./guide.jsx')
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
	            //array = this.props.params.id.split('+')
	            //array.push(this.props.params.type)
                //array.push(this.props.params.typeid)
                id = this.props.params.id
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
	            //array = this.props.params.id.split('+')
	            id = this.props.params.id
            }
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
	            id = this.props.params.id.split('+');
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
	    }
	    else if(this.props.params.value.toLowerCase() == "intel") {
	        state = 4
	        if(this.props.params.id != null) {
	            state = 4
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
	        return{id: id, id2: id2, set: state, handler: "Scot", viewMode:'default'}	
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
	        window.location.hash = '#/' + statetype + '/'
	        window.location.href = window.location.hash
	    })
	    var headerFull = <a href='/'>Scot3</a>
        var headerSmall = ""
        var menuItemsSmall = [
        <span className = "home"></span>,
        <span className = "intel"><i className="fa fa-lightbulb-o" aria-hidden="true"></i></span>,
        <span className = "fa fa-a"></span>,
        <span className = "fa fa-e"></span>,
        <span className = "fa fa-i"></span>,
        <span className = "fa fa-t"></span>,
        <span className = "fa fa-g"></span>,
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
                
            React.createElement(ExpandableNavMenu, null, 
            
                    React.createElement(ExpandableNavMenuItem, {active:setalerts ,small: menuItemsSmall[2], full: menuItemsFull[2], tooltip: "Alert", jquery: window.$, onClick: this.handleAlerts}),
                React.createElement(ExpandableNavMenuItem, {active: setevents,small: menuItemsSmall[3], full: menuItemsFull[3], tooltip: "Event", jquery: window.$,onClick: this.handleEvents}),
                React.createElement(ExpandableNavMenuItem, {active: setincidents,small: menuItemsSmall[4], full: menuItemsFull[4], tooltip: "Incident", jquery: window.$, onClick: this.handleIncidents}),
                    React.createElement(ExpandableNavMenuItem, {active: settask, small: menuItemsSmall[5], full: menuItemsFull[5], tooltip: "Task", jquery: window.$, onClick: this.handleTasks}),
            React.createElement(ExpandableNavMenuItem, {active: setguide, small: menuItemsSmall[6], full: menuItemsFull[6], tooltip: "Guide", jquery: window.$, onClick: this.handleGuide}),
        //            React.createElement(ExpandableNavMenuItem, {small: menuItemsSmall[7], full: menuItemsFull[7], tooltip: "Admin", jquery: window.$, onClick:this.handlePad}),
            React.createElement(ExpandableNavMenuItem, {active: setintel,small: menuItemsSmall[1], full: menuItemsFull[1], tooltip: "Intel", jquery: window.$, onClick: this.handleIntel}),
            React.createElement(ExpandableNavMenuItem, {small: menuItemsSmall[7], full: menuItemsFull[7], tooltip: "Incident Handler:  " + this.state.handler, jquery: window.$, onClick: this.handleHandler}) 
                )

            ),
            this.state.set == 0 
        ?
        React.createElement(ExpandableNavPage, null, React.createElement('div', {className: 'Text'}, React.createElement('img', {src: '/images/scot-600h.png', style: {width:'350px', height: '320px','margin-left':'auto', 'margin-right':'auto', display: 'block'}}), React.createElement('h1', null, "Sandia Cyber Omni Tracker, v. 3.5"), React.createElement('h1', null, 'Official Use Only')))  
            :
        this.state.set == 1
        ?	
        React.createElement(ExpandableNavPage, null, React.createElement(ListView, {isalert: isalert ? 'isalert' : '', id: this.state.id, viewMode: this.state.viewMode, type:statetype}))	
        :
            this.state.set == 2
        ?
        React.createElement(ExpandableNavPage, null, React.createElement(ListView, {id: this.state.id, id2: this.state.id2, viewMode: this.state.viewMode, type:'event'}))	
        :
            this.state.set == 3
        ?
        React.createElement(ExpandableNavPage, null, React.createElement(ListView, {id: this.state.id, id2: this.state.id2, viewMode: this.state.viewMode, type:'incident'}))	
        :
        this.state.set == 5
        ?
        React.createElement(ExpandableNavPage, null, React.createElement(SelectedContainer, {id: this.state.id, type: statetype, viewMode: this.state.viewMode}))
        :
        this.state.set == 4
        ?
        React.createElement(ExpandableNavPage, null, React.createElement(ListView, {id: this.state.id, id2: this.state.id2, viewMode: this.state.viewMode, type: 'intel'}))
        :
        this.state.set == 6
        ?	
        React.createElement(ExpandableNavPage, null, React.createElement(ListView, {viewMode: this.state.viewMode, type:'task'}))	
        :
        this.state.set == 7
        ?
        React.createElement(ExpandableNavPage, null, React.createElement(ListView, {id: this.state.id, viewMode: this.state.viewMode, type:'guide'}))
        :
        this.state.set == 8
        ?
        React.createElement(ExpandableNavPage, null, React.createElement(EntityDetail, {entityid: this.state.id, entitytype: 'entity', id: this.state.id, type: 'entity', viewMode: this.state.viewMode}))
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

