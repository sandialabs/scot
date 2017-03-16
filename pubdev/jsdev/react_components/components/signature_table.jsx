import React from 'react';
import { render } from 'react-dom';
import brace from 'brace';
import AceEditor from 'react-ace';

import 'brace/mode/java';
import 'brace/mode/c_cpp';
import 'brace/theme/github';
import 'brace/keybinding/vim'

var SignatureMetaData = React.createClass({
    getInitialState: function() {
        var inputArrayType = ['description','type', 'status', 'prod_sigbody_id','qual_sigbody_id', 'signature_group']
        var inputArrayTypeDisplay = ['Description','Type', 'Status', 'Production Signature Body Version','Quality Signature Body Version', 'Signature Group'] 
        return {
            descriptionValue: this.props.signatureData.description,
            inputArrayType: inputArrayType,
            inputArrayTypeDisplay: inputArrayTypeDisplay,
            description: this.props.signatureData.description,
            type: this.props.signatureData.type,
            status: this.props.signatureData.status,
            prod_sigbody_id: this.props.signatureData.prod_sigbody_id,
            qual_sigbody_id: this.props.signatureData.qual_sigbody_id,
            signature_group: this.props.signatureData.signature_group,
        }
    },
    componentDidMount: function() {
        
    },
    InputChange: function(event) {
        var key = event.target.id;
        var newValue = {}
        newValue[key] = event.target.value;
        this.setState(newValue);
    },
    submitMetaData: function(event) {
        var k  = event.target.id;
        var v = event.target.value;
        var json = {};
        json[k] = v;
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/signature/' + this.props.id,
            data: JSON.stringify(json),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                console.log('successfully changed incident data');
            }.bind(this),
            error: function() {
                this.props.errorToggle('Failed to updated signature metadata')
            }.bind(this)
        }) 
    },
    render: function() {
        var inputArray = [];
        for (var i=0; i < this.state.inputArrayType.length; i++) {
            var value = this.state[this.state.inputArrayType[i]];
            inputArray.push(
                <div> 
                    <span className='signatureTableWidth'>
                        {this.state.inputArrayTypeDisplay[i]}:
                    </span>
                    <span>
                        <input id={this.state.inputArrayType[i]} onBlur={this.submitMetaData} onChange={this.InputChange} value={value}/>
                    </span>
                </div> 
            )
        }
        return (
            <div id='signatureTable' className='signatureTable'>
                <div>
                   {inputArray} 
                </div>
            </div>
        )
    },
});

var SignatureTable = React.createClass({
    getInitialState: function() {
        return {
            readOnly: false,
            value: '',
            signatureData: {},
            loaded: false,
        }
    },
    onChange: function(value) {
        this.setState({value:value});
    },
    submitSigBody: function(signature) {
        //var json = {};
        //json[this.props.id] = signature;
        $.ajax({
            type: 'post',
            url: 'scot/api/v2/sigbody/',
            data: JSON.stringify({signature_id:this.props.id, body:this.state.value}),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                console.log('successfully changed signature data');
            }.bind(this),
            error: function() {
            }.bind(this)
        })
    },
    componentDidMount: function() {
        $.ajax({
            type: 'GET',
            url: '/scot/api/v2/signature/' + this.props.id,
            success: function(data) {
                this.setState({signatureData: data, loaded: true});
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('failed to get signature data');
            }.bind(this),
        });
    },
    render: function() {
        return (
            <div id={'signatureDetail'} className='signatureDetail'>
                {this.state.loaded ?
                    <div> 
                        <SignatureMetaData signatureData={this.state.signatureData} type={this.props.type} id={this.props.id}/>
                        <AceEditor
                            mode        = "c_cpp"
                            theme       = "github"
                            onChange    = {this.onChange}
                            name        = "signatureEditor"
                            editorProps = {{$blockScrolling: true}}
                            keyboardHandler = 'vim'
                            value       = {this.state.value}
                            height      = '400px'
                            readOnly    = {this.state.readOnly}
                        />
                    </div> 
                    : 
                    <div>
                        Loading Signature Data...
                    </div>
                }
            </div>
        )
    }
});



module.exports = SignatureTable;
