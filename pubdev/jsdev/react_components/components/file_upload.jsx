'use strict';
var React       = require('react')
var TinyMCE     = require('react-tinymce')
var Dropzone    = require('../../../node_modules/react-dropzone')
var Button      = require('react-bootstrap/lib/Button.js');
var Link        = require('react-router-dom').Link;
var finalfiles = []

var timestamp = new Date()
var output = "By You ";
timestamp = new Date(timestamp.toString())
output  = output + timestamp.toLocaleString()
var FileUpload = React.createClass({
	getInitialState: function(){
	return {
	    files: [], edit: false, stagecolor: '#000',enable: true, addentry: true, saved: true, enablesave: true, whoami: undefined}
	},

    componentDidMount: function() {
        var whoami = getSessionStorage('whoami');
        if ( whoami ) {
            this.setState({whoami:whoami});
        }  

        $('.entry-wrapper').scrollTop($('.entry-wrapper').scrollTop() + $('#not_saved_entry_'+this.props.id).position().top);

    },

	render: function() {
        var not_saved_entry_id = 'not_saved_entry_'+this.props.id
            return (
                <div id={not_saved_entry_id}>
                    <div className={'row-fluid entry-outer'} style={{border: '3px solid blue',marginLeft: 'auto', marginRight: 'auto', width:'99.3%'}}>
                        <div className={'row-fluid entry-header'}>
                            <div className="entry-header-inner">[<Link style={{color:'black'}} to={"not_saved_0"}>Not_Saved_0</Link>]by {this.state.whoami}
                                <span className='pull-right' style={{display:'inline-flex',paddingRight:'3px'}}>
                                    <Button bsSize={'xsmall'} onClick={this.submit}>Submit</Button>
                                    <Button bsSize={'xsmall'} onClick={this.onCancel}>Cancel</Button>
                                </span>
                            </div>
                        </div>
                        <Dropzone onDrop={this.onDrop} style={{'border-width':'2px','border-color':'#000','border-radius':'4px','border-style': 'dashed', 'text-align' : 'center','background-color':'azure'}}><div style={{fontSize:'16px',color:'black',margin:'5px'}}>Click or Drop files here to upload</div></Dropzone>
                        {this.state.files ? <div> {this.state.files.map(function(file) { return  <ul style={{'list-style-type' : 'none', margin:'0', padding:'0'}}><li><p style={{display:'inline'}}>{file.name}</p><button style={{'line-height':'1px'}} className='btn btn-info' id={file.name} onClick={this.Close}>x</button></li></ul>}.bind(this))}</div> : null} 
                    </div>    
                </div>
            )
    },
    onCancel: function(){
        finalfiles = []
        this.props.fileUploadToggle()
    },
   	Close: function(i) {
        for(var x = 0; x< finalfiles.length; x++){
            if(i.target.id == finalfiles[x].name){
                finalfiles.splice(x,1)
            }
        }
        this.setState({files:finalfiles})
	},
    onDrop: function(files){
	for(var i = 0; i<files.length; i++){
		finalfiles.push(files[i])
	   }	
    this.setState({files: finalfiles})
    },
	submit: function(){
        if(finalfiles.length > 0){
			for(var i = 0; i<finalfiles.length; i++){	
			    var file = {file : finalfiles[i].name}
                var data  = new FormData()
                data.append('upload', finalfiles[i])
                data.append('target_type',this.props.type)
                data.append('target_id',Number(this.props.targetid))
                if (this.props.entryid != null) {data.append('entry_id',this.props.entryid)}
			    var xhr = new XMLHttpRequest();
                xhr.addEventListener("progress", this.uploadProgress)
                xhr.addEventListener("load", this.uploadComplete);
                xhr.addEventListener("error", this.uploadFailed);
                xhr.addEventListener("abord", this.uploadCancelled);
                xhr.open("POST", "/scot/api/v2/file");
                xhr.send(data); 
            }
        } else {
            alert('Select a file to upload before submitting.')
        }
	    
	},
    uploadComplete: function() {
        this.onCancel();
    },
    uploadFailed: function() {
        this.props.errorToggle('An error occured. Upload failed.')
    },
    uploadProgress: function() {
        //TODO add progress bar
    },
    uploadCancelled: function() {
        //this.props.errorToggle('Upload Cancelled');
    }
});

module.exports = FileUpload
