'use strict';
var React       = require('react')
var Dropdown    = require('../../../node_modules/react-dropdown')
var Frame       = require('../../../node_modules/react-frame')
var Modal       = require('../../../node_modules/react-modal')
var TinyMCE     = require('react-tinymce')
var Dropzone    = require('../../../node_modules/react-dropzone')
var ReactTime   = require('react-time')
var AppActions  = require('../flux/actions.jsx');
var Activekey   = require('../activemq/handleupdate.jsx')
var Button      = require('react-bootstrap/lib/Button.js');
var marksave = false
var addentrydata = true
var finalfiles = []

var recently_updated = 0

var reply = false
var timestamp = new Date()
var output = "By You ";
timestamp = new Date(timestamp.toString())
output  = output + timestamp.toLocaleString()
var AddEntryModal = React.createClass({
	getInitialState: function(){
	return {
	    files: [], edit: false, stagecolor: '#000',enable: true, addentry: true, saved: true, enablesave: true}
	},
	componentWillMount: function(){
	if(this.props.stage == 'Edit'){
	    finalfiles = []
        reply = false;
        $.ajax({
	        type: 'GET',
	        url:  '/scot/api/v2/entry/'+ this.props.id
	        }).success(function(response){
                recently_updated = response.updated
                if(response.body_flair == ""){
	                $('#' + this.props.id + '_ifr').contents().find("#tinymce").html(response.body)
                }
                else{
	                $('#' + this.props.id + '_ifr').contents().find("#tinymce").html(response.body_flair)
                }
	        }.bind(this))
	}
	else if (this.props.title == 'Add Entry'){
	    finalfiles = []
        reply = false
	    $('#' + this.props.id + '_ifr').contents().find("#tinymce").text('')
    }
	else if(this.props.title == 'Reply Entry'){
	    finalfiles = []
        reply = true
        $.ajax({
	        type: 'GET',
	        url:  '/scot/api/v2/entry/'+ this.props.id
	   }).success(function(response){
	        if (response.body_flair == '') {
                this.setState({subitem: response.body});
            } else {
                this.setState({subitem: response.body_flair});
            }
	    }.bind(this))
		var newheight;
		newheight= document.getElementById('iframe_'+this.props.id).contentWindow.document.body.scrollHeight;
		newheight = newheight + 'px'
		this.setState({height: newheight})
	}
    },
	/*componentWillReceiveProps: function(){
	if(this.props.stage == 'Edit'){
	    reply = false
        finalfiles = []
        $.ajax({
	        type: 'GET',
	        url:  '/scot/api/v2/entry/'+ this.props.id
	   }).success(function(response){
            recently_updated = response.updated
            if(response.body_flair == ""){
	            $('#' + this.props.id + '_ifr').contents().find("#tinymce").html(response.body)
        }
            else{
	            $('#' + this.props.id + '_ifr').contents().find("#tinymce").html(response.body_flair)
        }
        })
	}
	else if (this.props.title == 'Add Entry'){
    	reply = false
        finalfiles = []
        $('#' + this.props.id + '_ifr').contents().find("#tinymce").text('')
	    var timestamp = new Date()
	    var output = "By You ";
	    timestamp = new Date(timestamp.toString())
	    output  = output + timestamp.toLocaleString()
	}
	this.setState({})
    },*/
    componentDidMount: function() {
        $('#' + this.props.id + '_ifr').css('height', '130px')
        $('.entry-wrapper').scrollTop($('.entry-wrapper').scrollTop() + $('#not_saved_entry_'+this.props.id).position().top)
    },
	render: function() {
	var item = this.state.subitem
    var not_saved_entry_id = 'not_saved_entry_'+this.props.id
        return (
            <div id={not_saved_entry_id}>
                <div className={'row-fluid entry-outer'} style={{marginLeft: 'auto', marginRight: 'auto', width:'99.3%'}}>
                    <div className={'row-fluid entry-header'}>
                        <div className="entry-header-inner">[<a style={{color:'black'}} href={"#/not_saved_0"}>Not_Saved_0</a>]by {whoami}
                            <span className='pull-right' style={{display:'inline-flex',paddingRight:'3px'}}>
                                <Button bsSize={'xsmall'} onClick={this.submit}>Submit</Button>
                                <Button bsSize={'xsmall'} onClick={this.onCancel}>Cancel</Button>
                            </span>
                        </div>
                    </div>
                    <TinyMCE id={this.props.id} content={""} className={'inputtext'} config={{plugins: 'autolink charmap media link image lists print preview insertdatetime code table spellchecker imagetools paste', paste_remove_styles: false, paste_word_valid_elements:'all', paste_retain_style_properties: 'all', paste_data_images:true, toolbar: 'spellchecker | image | insertdatetime | undo redo | bold italic | alignleft aligncenter alignright'}} onChange={this.handleEditorChange} /> 
                <Dropzone onDrop={this.onDrop} style={{'border-width':'2px','border-color':'#000','border-radius':'4px',padding: '30px','border-style': 'dashed', 'text-align' : 'center'}}><div style={{fontSize:'16px',color:'blue'}}>'Drop some files here or click to select files to upload'</div></Dropzone>
                {this.state.files ? <div> {this.state.files.map((file) => <ul style={{'list-style-type' : 'none', margin:'0', padding:'0'}}><li><p style={{display:'inline'}}>{file.name}</p><button style={{'line-height':'1px'}} className='btn btn-info' id={file.name} onClick={this.Close}>x</button></li></ul>)}</div> : null} 
                </div>    
            </div>
        )
    },
    clickable: function(){
	this.setState({addentry: false})
	},
    Edit: function(){
	$('#'+this.props.id+'_ifr').contents().find("#tinymce").attr('contenteditable', true)
	this.setState({saved: false, edit: false, enablesave:true})    
    },
    onCancel: function(){
	finalfiles = []
    this.props.addedentry()
	this.setState({change:false})
	AppActions.updateItem(this.props.targetid, 'headerUpdate')
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
	Save: function() {
	if($('#' + this.props.id + '_ifr').contents().find("#tinymce").text() == ""){
	    alert("Please fill in Text")
	}
	else {
	    $('#' + this.props.id + '_ifr').contents().find("#tinymce").attr('contenteditable', false)
	    this.setState({saved: true, edit: true, enablesave: false})
	}
        },
	submit: function(){
	if($('#' + this.props.id + '_ifr').contents().find("#tinymce").text() == ""){
	    alert("Please Add Some Text")
	}
    else {    
        if(this.props.stage == 'Reply')
	    {
    	    var data = new Object()
	        $('#' + this.props.id + '_ifr').contents().find("#tinymce").each(function(x,y){
            $(y).find('p').each(function(r,s){
                $(s).find('img').each(function(key, value){ 
                    var canvas = document.createElement('canvas')
                    var set = new Image()
                    set = $(value)
                    canvas.width =  set[0].width
                    canvas.height = set[0].height
                    var ctx = canvas.getContext('2d')
                    ctx.drawImage(set[0], 0, 0)
                    var dataURL = canvas.toDataURL("image/png")
                    //dataURL = dataURL.replace(/^data:image\/(png|jpg);base64,/,"")
                    $(value).attr('src', dataURL)
              })
        })
    })

    data = JSON.stringify({parent: Number(this.props.id), body: $('#' + this.props.id + '_ifr').contents().find("#tinymce").html(), target_id:Number(this.props.targetid) , target_type: this.props.type})

	$.ajax({
	    type: 'post',
	    url: '/scot/api/v2/entry',
	    data: data
	}).success(function(response){
        if(finalfiles.length > 0){
			for(var i = 0; i<finalfiles.length; i++){	
			    var file = {file : finalfiles[i].name}
                data  = new FormData()
                data.append('upload', finalfiles[i])
                data.append('target_type',this.props.type)
                data.append('target_id',Number(this.props.targetid))
                data.append('entry_id',response.id)
			    $.ajax({
			        type: 'POST',
			        url: '/scot/api/v2/file',
                    data: data,
                    processData: false,
                    contentType: false,
                    dataType: 'json',
                    cache: false
            }).success(function(response){
			   }.bind(this))
			}
		}
	}.bind(this))
	this.props.addedentry()
	AppActions.updateItem(this.props.targetid,'headerUpdate')
	}
	else if (this.props.stage == 'Edit'){

    $.ajax({
        type: 'GET',
        url: '/scot/api/v2/entry/'+this.props.id
    }).success(function(response){
    if(recently_updated != response.updated){
        this.forEdit(false)
        var set = false
        var Confirm = {
            launch: function(set){
            this.forEdit(set)
        }.bind(this)
    }
        $.confirm({
            icon: 'glyphicon glyphicon-warning',
            confirmButtonClass: 'btn-info',
            cancelButtonClass: 'btn-info',
            confirmButton: 'Yes, override change?',
            cancelButton: 'No, Keep change from ' + response.owner + '?',
            content: response.owner+"'s edit:" +'\n\n'+response.body,
            backgroundDismiss: false,
            title: "Edit Conflict" + '\n\n',
            confirm: function(){
            Confirm.launch(true)
            },
            cancel: function(){
            return 
            }
        })
        }
        else {
            this.forEdit(true)
        }
    }.bind(this))
    }
	else  if(this.props.type == 'alert'){ 
     var data;
	$('#' + this.props.id + '_ifr').contents().find("#tinymce").each(function(x,y){
        $(y).find('p').each(function(r,s){
                $(s).find('img').each(function(key, value){ 
                    var canvas = document.createElement('canvas')
                    var set = new Image()
                    set = $(value)
                    canvas.width =  set[0].width
                    canvas.height = set[0].height
                    var ctx = canvas.getContext('2d')
                    ctx.drawImage(set[0], 0, 0)
                    var dataURL = canvas.toDataURL("image/png")
                    //dataURL = dataURL.replace(/^data:image\/(png|jpg);base64,/,"")
                    $(value).attr('src', dataURL)
              })
        })
    })
    
     
	            data = JSON.stringify({body: $('#' + this.props.id + '_ifr').contents().find("#tinymce").html(), target_id: Number(this.props.targetid), target_type: 'alert',  parent: 0})
	            $.ajax({
		        type: 'post', 
		        url: '/scot/api/v2/entry',
		        data: data
		        }).success(function(response){
                    if(finalfiles.length > 0){
			            for(var i = 0; i<finalfiles.length; i++){	
                            var file = {file : finalfiles[i].name}
                            data  = new FormData()
                            data.append('upload', finalfiles[i])
                            data.append('target_type','alert')
                            data.append('target_id',Number($(y).text()))
                            data.append('entry_id',response.id)
                                $.ajax({
                                type: 'POST',
                                url: '/scot/api/v2/file',
                                data: data,
                                processData: false,
                                contentType: false,
                                dataType: 'json',
                                cache: false
                                }).success(function(response){
                                })
		}
		}
		})
		this.props.addedentry()
		AppActions.updateItem(this.props.targetid,'headerUpdate');
	}	
	else {
    var data = new Object();
	$('#' + this.props.id + '_ifr').contents().find("#tinymce").each(function(x,y){
        $(y).find('p').each(function(r,s){
                $(s).find('img').each(function(key, value){ 
                    var canvas = document.createElement('canvas')
                    var set = new Image()
                    set = $(value)
                    canvas.width =  set[0].width
                    canvas.height = set[0].height
                    var ctx = canvas.getContext('2d')
                    ctx.drawImage(set[0], 0, 0)
                    var dataURL = canvas.toDataURL("image/png")
                    //dataURL = dataURL.replace(/^data:image\/(png|jpg);base64,/,"")
                    $(value).attr('src', dataURL)
                })
        })
    })
    data = {parent: 0, body: $('#' + this.props.id + '_ifr').contents().find("#tinymce").html(), target_id: Number(this.props.targetid) , target_type: this.props.type}
    $.ajax({
	type: 'post',
	url: '/scot/api/v2/entry',
	data: JSON.stringify(data)
	}).success(function(response){
		   if(finalfiles.length > 0){
		        for(var i = 0; i<finalfiles.length; i++){	
                    data  = new FormData()
                    data.append('upload', finalfiles[i])
                    data.append('target_type',this.props.type)
                    data.append('target_id',Number(this.props.targetid))
                    data.append('entry_id',response.id)
                        $.ajax({
                        type: 'POST',
                        url: '/scot/api/v2/file',
                        data: data,
                        processData: false,
                        contentType: false,
                        dataType: 'json',
                        cache: false
                        }).success(function(response){
                        }.bind(this))
			}
			}
	}.bind(this))
	this.props.addedentry()
	AppActions.updateItem(this.props.targetid,'headerUpdate');
    }
	}
    },
    forEdit: function(set){
    if(set){
	$('#' + this.props.id + '_ifr').contents().find("#tinymce").each(function(x,y){
        $(y).find('p').each(function(r,s){
                $(s).find('img').each(function(key, value){ 
                    var canvas = document.createElement('canvas')
                    var set = new Image()
                    set = $(value)
                    canvas.width =  set[0].width
                    canvas.height = set[0].height
                    var ctx = canvas.getContext('2d')
                    ctx.drawImage(set[0], 0, 0)
                    var dataURL = canvas.toDataURL("image/png")
                    //dataURL = dataURL.replace(/^data:image\/(png|jpg);base64,/,"")
                    $(value).attr('src', dataURL)
                })
        })
    })

    var data = {
        parent: Number(this.props.parent), 
        body: $('#' + this.props.id + '_ifr').contents().find("#tinymce").html(), 
        target_id: Number(this.props.targetid) , 
        target_type: this.props.type
    }
	$.ajax({
        type: 'put',
        url: '/scot/api/v2/entry/'+this.props.id,
        data: data
        }).success(function(response){
            if(finalfiles.length > 0){
                for(var i = 0; i<finalfiles.length; i++){	
                    var file = {file : finalfiles[i].name}
                    data  = new FormData()
                    data.append('upload', finalfiles[i])
                    data.append('target_type',this.props.type)
                    data.append('target_id',Number(this.props.targetid))
                    data.append('entry_id',response.id)
                    $.ajax({
                        type: 'POST',
                        url: '/scot/api/v2/file',
                        data: data,
                        processData: false,
                        contentType: false,
                        dataType: 'json',
                        cache: false
                    }).success(function(response){
                        }.bind(this))
                }
            }
	}.bind(this))
	this.props.addedentry()
	AppActions.updateItem(this.props.targetid, 'headerUpdate')
    }
    }
});

module.exports = AddEntryModal

