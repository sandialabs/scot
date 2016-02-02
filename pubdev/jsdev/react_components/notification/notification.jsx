var React                   = require('react');
var ReactDOM                = require('react-dom');
var Crouton                 = require('react-crouton');
/*
var Notification = React.createClass({
        getInitialState: function(){
            return { 
                notification:false, 
            }
        },
        /*notificationToggle: function(message) {
            if (this.state.notification == false) {
                var data = {
                    id: Date.now(),
                    type: 'error',
                    message: 'Hello React-Crouton',
                    autoMiss: true || false,
                    onDismiss: {this.onDismiss()},
                    buttons: [{
                        name: 'close',
                        listener: function() {

                        }
                    }],
                    hidden: false,
                    timeout: 2000
                }
            } else { 
                this.setState({notification:false});
            } 
        },
        onDismiss: function() {
            this.setState({notification:false});
        },
        render: function() {
            var data = {
                id: Date.now(),
                type: 'error',
                message: 'Hello React-Crouton'
            } 
            return (
                <div style={{marginTop: '200px'}}>
                    <Crouton id={data.id} message={data.message} type={data.type} />                
                </div>
            );
        } 
});
*/

var React = window.React = require('react')
  , assign = require('react/lib/Object.assign') 
  , CodeMirror = require('codemirror')

var Example = React.createClass({

  displayName: 'Crouton-Example',

  getInitialState: function(){
    return {}
  },

  getDefaultProps: function() {
    return {}
  },

  onDismiss: function() {
    this.setState({
      result: 'dismiss trigger'
    });
  },

  handleClick: function(event) {
    event.preventDefault();
    var data = this.props.data
    if (data['onDismiss']) {
      data['onDismiss'] = this.onDismiss
    }
    if (data.buttons) {
      if(typeof data.buttons !== 'string') {
        data.buttons = data.buttons.map(function(button){
          if(button.listener) {
            button.listener = this.listener;
          }
          return button;
        }, this)
      }
    }
    this.props.show(this.props.data)
  },

  listener: function(event) {
    event.preventDefault();
    this.setState({
      result: event.target.id + ' button click '
    });
  },

  render: function() {
    return (
      <div className='example'>
        <h3 className='title'>{this.props.data.message}</h3> 
        {this.props.data.onDismiss ? <span className='result'> { 'result: ' + (this.state.result || '') }</span>: null}
        <button className='show' onClick={this.handleClick}>Show</button>
      </div>)
  }
})

var App = React.createClass({

  displayName: 'Crouton-Demo',

  getInitialState: function() {
    return {
      crouton: {

      },
      examples: [{
        message: 'Simple example',
        type: 'error'
      },{
        message: 'Simple example with onDismiss listener',
        type: 'info',
        onDismiss: 'onDismiss'
      }]
    }
  },

  show: function(data) {
    data.hidden = false
    this.setState({
      crouton: data
    });
  },

  render: function() {
    return (
      <div>
        <div className='header'>
          <h1>React-Crouton</h1>
          <h4>A message component for reactjs</h4>
        </div>
        {
          this.state.crouton && this.state.crouton.message ?
          <Crouton
           id={Date.now()}
           message={this.state.crouton.message}
           type={this.state.crouton.type}
           autoMiss={this.state.crouton.autoMiss}
           onDismiss={this.state.crouton.onDismiss}
           buttons={this.state.crouton.buttons}
           hidden={this.state.crouton.hidden}
           timeout={this.state.crouton.timeout}
          /> : null
        }
        <div id='main'>
          {this.state.examples.map(function(example, i) {
            return <Example key={i} show={this.show} data={example}/>
          }, this)}
        </div>
      </div>
    )
  }
})

React.render(<App />, document.getElementById('notification'))

module.exports = Notification;
