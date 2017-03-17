import React from 'react';
import { render } from 'react-dom';
import brace from 'brace';
import AceEditor from 'react-ace';
import Button from 'react-bootstrap/lib/Button.js';
import DropdownButton from 'react-bootstrap/lib/DropdownButton.js';
import MenuItem from 'react-bootstrap/lib/MenuItem.js';
import Store from '../activemq/store.jsx';

import 'brace/mode/java';
import 'brace/mode/c_cpp';
import 'brace/theme/github';
import 'brace/keybinding/vim'

var SignatureTable = React.createClass({
    getInitialState: function() {
        var key = new Date();
        key = key.getTime();
        return {
            readOnly: true,
            value: '',
            signatureData: {},
            loaded: false,
            viewVersionid: null,
            key: key,
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
                this.setState({readOnly:true});
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
                this.setState({signatureData: data, loaded: true, value:data.body[data.prod_sigbody_id].body, viewVersionid: data.prod_sigbody_id });
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('failed to get signature data');
            }.bind(this),
        });
        Store.storeKey(this.props.id);
        Store.storeKey(this.SignatureUpdated);
    },
    SignatureUpdated: function() {
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
    editSigBody: function() {
        this.setState({readOnly: false});    
    },
    createNewSigBody: function() {
        this.setState({readOnly: false, viewVersionid: null, value:''});
    },
    Cancel: function() {
        this.setState({readOnly:true, value: this.state.signatureData.body[this.state.viewVersionid].body});
    },
    viewSigBody: function(e) {
        if (this.state.readOnly == true) {  //only allow button click if you can't edit the signature
            this.setState({value:this.state.signatureData.body[e.target.id].body, viewVersionid:e.target.id});
        }
    },
    render: function() {
        var versionsArray = []
        var not_saved_signature_entry_id = 'not_saved_signature_entry_' + this.state.key;
        if (!jQuery.isEmptyObject(this.state.signatureData)) {
            for (var key in this.state.signatureData.body) {
                var versionid = this.state.signatureData.body[key].id
                var disabled;
                if (this.state.readOnly == true) { disabled = false;} else { disabled = true;};
                versionsArray.push(<MenuItem id={versionid} key={versionid} onClick={this.viewSigBody} eventKey={versionid} bsSize={'xsmall'} disabled={disabled}>{versionid}</MenuItem>)
            }
        }
        return (
            <div id={'signatureDetail'} className='signatureDetail'>
                {this.state.loaded ?
                    <div>
                        <SignatureMetaData signatureData={this.state.signatureData} type={this.props.type} id={this.props.id}/>
                        <div id={not_saved_signature_entry_id} className={'not_saved_signature_entry'}>
                            <div className={'row-fluid signature-entry-outer'} style={{marginLeft: 'auto', marginRight: 'auto'}}>          
                                <div className={'row-fluid signature-entry-header'}>
                                    <div className="signature-entry-header-inner">[<a style={{color:'black'}} href={"#/not_saved_0"}>Not_Saved_0</a>]by {whoami}
                                        <span className='pull-right' style={{display:'inline-flex',paddingRight:'3px'}}>
                                            <DropdownButton bsSize={'xsmall'} title={this.state.viewVersionid} id='bg-nested-dropdown'>
                                                {versionsArray}
                                            </DropdownButton> 
                                            {this.state.readOnly ? 
                                                <span>
                                                    
                                                    <Button bsSize={'xsmall'} onClick={this.createNewSigBody}>Create new version</Button>
                                                    <Button bsSize={'xsmall'} onClick={this.editSigBody}>Edit displayed version</Button>
                                                </span>
                                            :
                                                <span>
                                                    <Button bsSize={'xsmall'} onClick={this.submitSigBody}>Submit new version</Button>
                                                    <Button bsSize={'xsmall'} onClick={this.Cancel}>Cancel</Button>
                                                </span>
                                            }
                                        </span>
                                    </div>
                                </div> 
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
                        </div>
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
                    <span className='signatureTableWidth'>
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



module.exports = SignatureTable;
