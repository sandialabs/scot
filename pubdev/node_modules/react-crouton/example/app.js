/**
 * @jsx React.DOM
 */

var React = window.React = require('react')
  , assign = require('react/lib/Object.assign')
  , Crouton = require('../')
  , CodeMirror = require('codemirror')

require('codemirror/mode/javascript/javascript')

var Code = React.createClass({

  displayName: 'Crouton-Code',

  getDefaultProps: function() {
    return {
      readOnly: true,
      mode: 'javascript'
    }
  },

  componentDidMount: function() {
    CodeMirror(this.getDOMNode(), {
      value: this.props.doc,
      mode: this.props.mode,
      theme: 'eclipse',
      lineNumbers: true,
      matchBrackets: true,
      readOnly: this.props.readOnly
    });
  },

  render: function() {
    return React.createElement('div', assign({}, this.props))
  }
})

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
        <Code
          doc={'<Crouton\n ' +
            (Object.keys(this.props.data).map(function(key){
                  var v = this.props.data[key];
                  return key + '="' + (typeof v === 'string' ? v : JSON.stringify(v)) + '"'
            }, this).join('\n ')) +
            '/>'} />
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
      }, {
        message: 'Simple example with one button',
        type: 'info',
        buttons: 'close',
        onDismiss: 'onDismiss'
      },{
        message: 'Simple example with one button and listener',
        type: 'info',
        buttons: [{
          name: 'close',
          listener: 'listener'
        }],
        onDismiss: 'onDismiss'
      },,{
        message: 'Simple example with one custom class button and listener',
        type: 'info',
        buttons: [{
          name: 'close',
          className: 'btn close',
          listener: 'listener'
        }],
        onDismiss: 'onDismiss'
      },{
        message: 'Simple example with two button and listener',
        type: 'info',
        buttons: [{
          name: 'retry',
          listener: 'listener'
        },{
          name: 'close'
        }],
        onDismiss: 'onDismiss'
      },{
        message: 'Simple example with two custom class button and listener',
        type: 'info',
        buttons: [{
          name: 'retry',
          listener: 'listener'
        },{
          name: 'close',
          className: 'btn close'
        }],
        onDismiss: 'onDismiss'
      },{
        message: 'Simple example with two button and listener',
        type: 'info',
        buttons: [{
          name: 'retry',
          listener: 'listener'
        },{
          name: 'close',
          listener: 'listener'
        }],
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

React.render(<App />, document.getElementById('crouton-example'))

