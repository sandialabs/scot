import React from 'react';
import { render } from 'react-dom';
import brace from 'brace';
import AceEditor from 'react-ace';
import Button from 'react-bootstrap/lib/Button.js';
import DropdownButton from 'react-bootstrap/lib/DropdownButton.js';
import OverlayTrigger from 'react-bootstrap/lib/OverlayTrigger.js';
import ButtonGroup from 'react-bootstrap/lib/ButtonGroup.js';
import MenuItem from 'react-bootstrap/lib/MenuItem.js';
import Popover from 'react-bootstrap/lib/Popover.js';
import Store from '../activemq/store.jsx';
import Grid from 'react-bootstrap/lib/Grid.js';
import Row from 'react-bootstrap/lib/Grid.js';
import Col from 'react-bootstrap/lib/Grid.js';
import Clearfix from 'react-bootstrap/lib/Grid.js';


import 'brace/mode/javascript';
import 'brace/mode/java';
import 'brace/mode/python';
import 'brace/mode/xml';
import 'brace/mode/ruby';
import 'brace/mode/sass';
import 'brace/mode/markdown';
import 'brace/mode/mysql';
import 'brace/mode/json';
import 'brace/mode/html';
import 'brace/mode/c_cpp';
import 'brace/mode/csharp';
import 'brace/mode/perl';
import 'brace/mode/powershell';
import 'brace/mode/yaml';
import 'brace/theme/github';
import 'brace/theme/monokai';
import 'brace/theme/kuroir';
import 'brace/theme/solarized_dark';
import 'brace/theme/solarized_light';
import 'brace/theme/terminal';
import 'brace/theme/textmate';
import 'brace/theme/tomorrow';
import 'brace/theme/twilight';
import 'brace/theme/xcode';
import 'brace/keybinding/vim';
import 'brace/keybinding/emacs';

var SignatureTable = React.createClass({
    getInitialState: function() {
        var key = new Date();
        key = key.getTime();
        var value = '';
        var currentKeyboardHandler = 'none';
        var currentLanguageMode = 'java';
        var currentEditorTheme = 'github';
        var viewVersionid = this.props.headerData.prod_sigbody_id;
        if (checkCookie('signatureKeyboardHandler') != undefined) {
            currentKeyboardHandler = checkCookie('signatureKeyboardHandler');
        }
        if (checkCookie('signatureLanguageMode') != undefined) {
            currentLanguageMode = checkCookie('signatureLanguageMode');
        }
        if (checkCookie('signatureEditorTheme') != undefined) {
            currentEditorTheme = checkCookie('signatureEditorTheme');
        }
        if (!jQuery.isEmptyObject(this.props.headerData.body)) {
            if (this.props.headerData.body[this.props.headerData.prod_sigbody_id] != undefined || this.props.headerData.body[this.props.headerData.prod_sigbody_id] == 0) {
                value = this.props.headerData.body[this.props.headerData.prod_sigbody_id].body;
            } else {
                for (var key in this.props.headerData.body) {
                    if (key < viewVersionid) {
                        continue;
                    } else {
                        viewVersionid = key;
                        value = this.props.headerData.body[key].body;    
                    }
                } 
            }
        }
        return {
            readOnly: true,
            value: value,
            signatureData: this.props.headerData,
            loaded: true,
            viewVersionid: viewVersionid,
            lastViewVersionid: null,
            key: key,
            cursorEnabledDisabled: 'cursorDisabled',
            keyboardHandlers: ['none', 'vim', 'emacs'],
            currentKeyboardHandler: currentKeyboardHandler,
            languageModes: ['csharp', 'c_cpp','html', 'javascript', 'java','json', 'markdown', 'mysql','perl', 'powershell', 'python', 'ruby', 'sass','xml','yaml'],
            currentLanguageMode: currentLanguageMode,
            editorThemes: ['github', 'monokai', 'kuroir', 'solarized_dark','solarized_light' ,'terminal', 'textmate', 'tomorrow', 'twilight', 'xcode'],
            currentEditorTheme: currentEditorTheme,
            ajaxType: null,    
        }
    },
    onChange: function(value) {
        this.setState({value:value});
    },
    submitSigBody: function(e) {
        var url = 'scot/api/v2/sigbody/';
        if (this.state.ajaxType == 'put') {
            url = 'scot/api/v2/sigbody/' + this.state.viewVersionid;
        }
        $.ajax({
            type: this.state.ajaxType,
            url: url,
            data: JSON.stringify({signature_id:parseInt(this.props.id), body:this.state.value}),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                console.log('successfully changed signature data');
                this.setState({readOnly:true, cursorEnabledDisabled: 'cursorDisabled', ajaxType:null, viewVersionid:data.id});
            }.bind(this),
            error: function() {
                this.props.errorToggle('Failed to create/update sigbody');
            }.bind(this)
        })
    },
    componentWillReceiveProps: function(nextProps) {
        this.setState({signatureData: nextProps.headerData});
    },
    editSigBody: function() {
        this.setState({readOnly: false, lastViewVersionid: this.state.viewVersionid, cursorEnabledDisabled: 'cursorEnabled', ajaxType:'put'});    
    },
    createNewSigBody: function() {
        this.setState({readOnly: false, viewVersionid: null, lastViewVersionid:this.state.viewVersionid , value:'', cursorEnabledDisabled: 'cursorEnabled', ajaxType:'post'});
    },
    createNewSigBodyFromSig: function() {
        this.setState({readOnly:false, lastViewVersionid: this.state.viewVersionid, cursorEnabledDisabled:'cursorEnabled', ajaxType:'post', viewVersionid: null});
    },
    Cancel: function() {
        var value = '';
        if (!jQuery.isEmptyObject(this.state.signatureData.body)) {
            if (this.state.signatureData.body[this.state.signatureData.prod_sigbody_id] != undefined) {
                value = this.state.signatureData.body[this.state.lastViewVersionid].body;
            }
        }
        this.setState({readOnly:true, value:value , viewVersionid: this.state.lastViewVersionid, cursorEnabledDisabled: 'cursorDisabled', ajaxType:null});
    },
    viewSigBody: function(e) {
        if (this.state.readOnly == true) {  //only allow button click if you can't edit the signature
            this.setState({value:this.state.signatureData.body[e.target.id].body, viewVersionid:e.target.id});
        }
    },
    keyboardHandlerUpdate: function(e) {
        setCookie('signatureKeyboardHandler',e.target.text,1000)
        this.setState({currentKeyboardHandler: e.target.text});
    },
    languageModeUpdate: function(e) {
        setCookie('signatureLanguageMode',e.target.text,1000);
        this.setState({currentLanguageMode: e.target.text});
    },
    editorThemeUpdate: function(e) {
        setCookie('signatureEditorTheme',e.target.text,1000);
        this.setState({currentEditorTheme: e.target.text});
    },
    render: function() {
        var versionsArray = [];
        var keyboardHandlersArray = [];
        var languageModesArray = [];
        var editorThemesArray = [];
        var not_saved_signature_entry_id = 'not_saved_signature_entry_' + this.state.key;
        var currentKeyboardHandlerApplied = this.state.currentKeyboardHandler;
        var viewVersionid = [];
        var highestVersionid = 0;
        if (!jQuery.isEmptyObject(this.state.signatureData)) {
            if (!jQuery.isEmptyObject(this.state.signatureData.body)){
                for (var key in this.state.signatureData.body) {
                    var versionid = this.state.signatureData.body[key].id;
                    var versionidprodqual = this.state.signatureData.body[key].id;
                    if (this.state.signatureData.prod_sigbody_id == versionid) {versionidprodqual = versionid + ' - Production'} else if (this.state.signatureData.qual_sigbody_id == versionid) {versionidprodqual = versionid + ' - Quality'}; //add production and quality text to identify current status on the menu
                    var disabled;
                    if (this.state.readOnly == true) { disabled = false;} else { disabled = true;};
                    versionsArray.push(<MenuItem id={versionid} key={versionid} onClick={this.viewSigBody} eventKey={versionid} bsSize={'xsmall'} disabled={disabled}>{versionidprodqual}</MenuItem>)
                    if (versionid > highestVersionid) {highestVersionid = versionid};
                }
            }
        }
        
        if (this.state.keyboardHandlers != undefined) {
            for (var i=0; i < this.state.keyboardHandlers.length; i++) {
                keyboardHandlersArray.push(<MenuItem id={i} key={i} onClick={this.keyboardHandlerUpdate} eventKey={i} bsSize={'xsmall'}>{this.state.keyboardHandlers[i]}</MenuItem>);
            }
        }
        
        if (this.state.currentKeyboardHandler == 'none' ) {
            currentKeyboardHandlerApplied = null;
        }
        
        if (this.state.languageModes != undefined) {
            for (var i=0; i < this.state.languageModes.length; i++) {
                languageModesArray.push(<MenuItem id={i} key={i} onClick={this.languageModeUpdate} eventKey={i} bsSize={'xsmall'}>{this.state.languageModes[i]}</MenuItem>);
            }
        }

        if (this.state.editorThemes != undefined) {
            for (var i=0; i < this.state.editorThemes.length; i++) {
                editorThemesArray.push(<MenuItem id={i} key={i} onClick={this.editorThemeUpdate} eventKey={i} bsSize={'xsmall'}>{this.state.editorThemes[i]}</MenuItem>);
            }
        }
        if (this.state.signatureData.prod_sigbody_id == this.state.viewVersionid) { 
            viewVersionid.push(<span className='signature_production_color'>{this.state.viewVersionid} - Production</span>) 
        } else if (this.state.signatureData.qual_sigbody_id == this.state.viewVersionid) {
            viewVersionid.push(<span className='signature_quality_color'>{this.state.viewVersionid} - Quality</span>)
        } else {
            viewVersionid.push(<span>{this.state.viewVersionid}</span>)
        }
        return (
            <div id={'signatureDetail'} className='signatureDetail'>
                {this.state.loaded ?
                    <div>
                        <SignatureMetaData signatureData={this.state.signatureData} type={this.props.type} id={this.props.id} currentLanguageMode={this.state.currentLanguageMode} currentEditorTheme={this.state.currentEditorTheme} currentKeyboardHandlerApplied={currentKeyboardHandlerApplied} errorToggle={this.props.errorToggle}/>
                        <div id={not_saved_signature_entry_id} className={'not_saved_signature_entry'}>
                            <div className={'row-fluid signature-entry-outer'} style={{marginLeft: 'auto', marginRight: 'auto'}}>          
                                <div className={'row-fluid signature-entry-header'}>
                                    <div className="signature-entry-header-inner">
                                        Signature Body: {viewVersionid} 
                                        <span className='pull-right' style={{display:'inline-flex',paddingRight:'3px'}}>
                                            Editor Theme:
                                            <DropdownButton bsSize={'xsmall'} title={this.state.currentEditorTheme} id='bg-nested-dropdown' style={{marginRight:'10px'}}>
                                                {editorThemesArray}
                                            </DropdownButton>
                                            Language Handler:
                                            <DropdownButton bsSize={'xsmall'} title={this.state.currentLanguageMode} id='bg-nested-dropdown' style={{marginRight:'10px'}}>
                                                {languageModesArray}
                                            </DropdownButton>
                                            
                                            Keyboard Handler: 
                                            <DropdownButton bsSize={'xsmall'} title={this.state.currentKeyboardHandler} id='bg-nested-dropdown' style={{marginRight:'10px'}}>
                                                {keyboardHandlersArray}
                                            </DropdownButton>
                                            
                                            Signature Body Version:  
                                            <DropdownButton bsSize={'xsmall'} title={viewVersionid} id='bg-nested-dropdown' style={{marginRight:'10px'}}>
                                                {versionsArray}
                                            </DropdownButton>
                                        {this.state.readOnly ? 
                                            <span>
                                                <Button bsSize={'xsmall'} onClick={this.createNewSigBody} bsStyle={'success'}>Create new version</Button>
                                                {this.state.viewVersionid != 0 ? 
                                                    <span><Button bsSize={'xsmall'} onClick={this.createNewSigBodyFromSig}>Create new version using this base</Button>
                                                    <Button bsSize={'xsmall'} onClick={this.editSigBody}>Update displayed version</Button></span> 
                                                : 
                                                    null 
                                                }
                                            </span>
                                        :
                                            <span>
                                                <Button bsSize={'xsmall'} onClick={this.submitSigBody}>Submit</Button>
                                                <Button bsSize={'xsmall'} onClick={this.Cancel}>Cancel</Button>
                                            </span>
                                        }
                                        </span>
                                    </div>
                                </div> 
                                <AceEditor
                                    mode            = {this.state.currentLanguageMode}
                                    theme           = {this.state.currentEditorTheme}
                                    onChange        = {this.onChange}
                                    name            = "signatureEditor"
                                    editorProps     = {{$blockScrolling: true}}
                                    keyboardHandler = {currentKeyboardHandlerApplied}
                                    value           = {this.state.value}
                                    height          = '250px'
                                    width           = '100%'
                                    readOnly        = {this.state.readOnly}
                                    className       = {this.state.cursorEnabledDisabled}
                                    showPrintMargin = {false}
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
        var inputArrayType = ['description','type', 'prod_sigbody_id','qual_sigbody_id', 'signature_group', 'target']
        var inputArrayTypeDisplay = ['Description','Type', 'Production Signature Body Version','Quality Signature Body Version', 'Signature Group', 'Target'] 
        var target = this.props.signatureData.target;
        if (this.props.signatureData.target == undefined) {
            target = {};
            target['id'] = null;
            target['type'] = null;
        }
        return {
            descriptionValue: this.props.signatureData.description,
            inputArrayType: inputArrayType,
            inputArrayTypeDisplay: inputArrayTypeDisplay,
            description: this.props.signatureData.description,
            type: this.props.signatureData.type,
            prod_sigbody_id: this.props.signatureData.prod_sigbody_id,
            qual_sigbody_id: this.props.signatureData.qual_sigbody_id,
            signature_group: this.props.signatureData.signature_group,
            optionsValue: JSON.stringify(this.props.signatureData.options),
            target: target,
            showSignatureOptions: false,
        }
    },
    InputChange: function(event) {
        var key = event.target.id;
        var newValue = {}
        newValue[key] = event.target.value;
        this.setState(newValue);
    },
    TargetInputChange: function(event) {
        var currentTarget = this.state.target;
        var key = event.target.id;
        currentTarget[key] = event.target.value;
        this.setState({target:currentTarget});
    },
    submitMetaData: function(event) {
        var k  = event.target.id;
        var v = event.target.value;
        if (k == 'options' || k == 'target') { 
            try{v = JSON.parse(v)} 
            catch(err) {this.props.errorToggle('Failed to convert string to object. Try adding quotation marks around the key and values'); return; }
            var optionsType = typeof(v);
            if (optionsType !== 'object') { this.props.errorToggle('options need to be an object but were detected as: ' + optionsType ); return; };
        }; //Convery v to JSON for options as its type is JSON
        var json = {};
        json[k] = v;
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/signature/' + this.props.id,
            data: JSON.stringify(json),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                console.log('successfully changed signature data');
            }.bind(this),
            error: function() {
                this.props.errorToggle('Failed to update signature metadata')
            }.bind(this)
        }) 
    },
    onOptionsChange: function(optionsValue) {
        this.setState({optionsValue:optionsValue});
    },
    showSignatureOptions: function() {
        if (this.state.showSignatureOptions == false) {
            this.setState({showSignatureOptions: true});
        } else {
            this.setState({showSignatureOptions: false});
        }
    },
    render: function() {
        var inputArray = [];
        for (var i=0; i < this.state.inputArrayType.length; i++) {
            var value = this.props.signatureData[this.state.inputArrayType[i]];
            if (this.state.inputArrayType[i] == 'prod_sigbody_id' || this.state.inputArrayType[i] == 'qual_sigbody_id') {
              var sigBodyVersionArray = [];
              var productionNewerVersionExists = false;
              if (!jQuery.isEmptyObject(this.props.signatureData)) {
                    for (var key in this.props.signatureData.body) {
                        var versionid = this.props.signatureData.body[key].id
                        var versionidprodqual = this.props.signatureData.body[key].id;
                        if (this.props.signatureData.prod_sigbody_id == versionid) {versionidprodqual = versionid + ' - Production'} else if (this.props.signatureData.qual_sigbody_id == versionid) {versionidprodqual = versionid + ' - Quality'}; //add production and quality text to identify current status on the menu
                        sigBodyVersionArray.push(<Button id={this.state.inputArrayType[i]} key={versionid} onClick={this.submitMetaData} eventKey={versionid} bsSize={'xsmall'} value={versionid}>{versionidprodqual}</Button>)        
                        if (value < versionid) {productionNewerVersionExists = true;}; //check if the production/quality versions are the highest, if not, show warning.
                    }
                } 
                inputArray.push(
                    <div className='col-lg'> 
                        <span className='signatureTableWidth'>
                            {this.state.inputArrayTypeDisplay[i]}:
                        </span>
                        <span className='signatureTableWidth'>
                            <OverlayTrigger trigger='focus' placement='bottom' overlay={<Popover id='sigversionpicker'><ButtonGroup vertical>{sigBodyVersionArray}</ButtonGroup></Popover>}>
                                <input id={this.state.inputArrayType[i]} onChange={this.InputChange} value={value} onBlur={this.submitMetaData}/>
                            </OverlayTrigger>  
                        </span>
                        {productionNewerVersionExists == true && this.state.inputArrayType[i] == 'prod_sigbody_id' ? <div style={{color:'red'}}>A higher signature body version exists, do you want to apply it?</div> : null }
                    </div> 
                )
            } else if (this.state.inputArrayType[i] == 'target') {
                inputArray.push(
                    <div className='col-lg'> 
                        <span className='signatureTableWidth'>
                            <span>Target Type: </span><input id={'target.type'} onChange={this.TargetInputChange} value={this.state.target.type} placeholder={'event, intel, entry... (only type one)'} onBlur={this.submitMetaData}/>
                            <span>Target ID: </span><input id={'target.id'} onChange={this.TargetInputChange} value={this.state.target.id} placeholder={'ID of above'} onBlur={this.submitMetaData}/>
                        </span>
                    </div>
                )
            } else {
                inputArray.push(
                    <div className='col-lg'> 
                        <span className='signatureTableWidth'>
                            {this.state.inputArrayTypeDisplay[i]}:
                        </span>
                        <span className='signatureTableWidth'>
                            <input id={this.state.inputArrayType[i]} onChange={this.InputChange} value={this.state[this.state.inputArrayType[i]]} onBlur={this.submitMetaData}/>
                        </span>
                    </div> 
                )
            }
        }
        return (
            <div>
                <div id='signatureTable' className='signatureTable'>
                    <div className="row">
                        {inputArray}
                        <div className='col-lg-1' style={{backgroundColor:'#EEE', marginTop:'15px'}}>
                            <Button type='submit' bsSize='xsmall' bsStyle='warning' onClick={this.showSignatureOptions} id={10}>View Custom Options</Button>
                        </div>
                    </div>
                </div>
                {this.state.showSignatureOptions ? 
                    <div id='signatureTable2' className='signatureTableOptions'>
                        <div className={'row-fluid signature-entry-outer'} style={{marginLeft: 'auto', marginRight: 'auto'}}>          
                            <div className={'row-fluid signature-entry-header'}>
                                <div className="signature-entry-header-inner">
                                    Signature Options  
                                    <Button type='submit' bsSize='xsmall' bsStyle='success' onClick={this.submitMetaData} id={'options'} value={this.state.optionsValue}>Apply</Button>
                                </div>
                            </div> 
                            <AceEditor
                                mode            = 'json'
                                theme           = {this.props.currentEditorTheme}
                                onChange        = {this.onOptionsChange}
                                name            = "signatureEditorOptions"
                                editorProps     = {{$blockScrolling: true}}
                                keyboardHandler = {this.props.currentKeyboardHandlerApplied}
                                value           = {this.state.optionsValue}
                                height          = '200px'
                                width           = '100%'
                                readOnly        = {false} 
                                showPrintMargin = {false}
                            />
                        </div>
                    </div> 
                : 
                    null 
                }
            </div>
        )
    },
});

module.exports = SignatureTable;
