'use strict';

require('./index.styl')

var React = require('react')
var LoadMask = require('./src')

var VISIBLE = true

var App = React.createClass({

    render: function(){

        return <LoadMask visible={VISIBLE} onMouseDown={this.handleMouseDown} size={50}/>
    },

    handleMouseDown: function(){
        VISIBLE = !VISIBLE

        this.setState({})
    }
})

React.render((
    <App />
), document.getElementById('content'))