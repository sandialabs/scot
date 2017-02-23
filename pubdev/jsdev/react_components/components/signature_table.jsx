import React from 'react';
import { render } from 'react-dom';
import brace from 'brace';
import AceEditor from 'react-ace';

import 'brace/mode/java';
import 'brace/mode/c_cpp';
import 'brace/theme/github';
import 'brace/keybinding/vim'

var SignatureTable = React.createClass({
    onChange: function(signature) {
        var json = {};
        json[this.props.id] = signature;
        /*$.ajax({
            type: 'put',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
            data: JSON.stringify(json),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                console.log('successfully changed signature data');
            }.bind(this),
            error: function() {
                this.props.errorToggle('Failed to updated incident data') 
            }.bind(this)
        })*/
    },
    render: function() {
        return (
            <div id={'signatureTable'} className='signatureTable'>
                Test Signature Ace Editor
                <AceEditor
                    mode        = "c_cpp"
                    theme       = "github"
                    onChange    = {this.onChange}
                    name        = "signatureTable"
                    editorProps = {{$blockScrolling: true}}
                    keyboardHandler = 'vim'
                />
            </div>
        )
    }
});

module.exports = SignatureTable;
