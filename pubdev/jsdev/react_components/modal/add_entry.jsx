'use strict';
var React    = require('react')
var Dropdown = require('../../../node_modules/react-dropdown')
var Frame    = require('../../../node_modules/react-frame')
var Modal    = require('../../../node_modules/react-modal')
var TinyMCE  = require('react-tinymce')
var marksave = false
var addentrydata = true
var Dropzone = require('../../../node_modules/react-dropzone')
var finalfiles = []
var ReactTime = require('react-time')

const  customStyles = {
        content : {
        top     : '1%',
        right   : '60%',
        bottom  : 'auto',
	left	: '10%',
	width: '80%'
//	height: '80%'
    }
}

var reply = false
var timestamp = new Date()
var output = "By You ";
timestamp = new Date(timestamp.toString())
output  = output + timestamp.toLocaleString()
var AddEntryModal = React.createClass({
	getInitialState: function(){
	return {
	files: [], edit: false, stagecolor: '#000',enable: true, addentry: true, saved: false, enablesave: true, modaloptions: [{value:' Please Save Entry First', label:'Please Save Entry First'}]}
	},
	componentWillMount: function(){
	if(this.props.stage == 'Edit'){
	  reply = false;
      $.ajax({
	   type: 'GET',
	   url:  '/scot/api/v2/entry/'+ this.props.id
	   }).success(function(response){
	    $('#react-tinymce-addentry_ifr').contents().find("#tinymce").html(response.body_flair)
	    })
	}
	else if (this.props.title == 'Add Entry'){
	$('#react-tinymce-addentry_ifr').contents().find("#tinymce").text('')
	}
	else if(this.props.title == 'Reply Entry'){
	   reply = true
           $.ajax({
	   type: 'GET',
	   url:  '/scot/api/v2/entry/'+ this.props.id
	   }).success(function(response){
	      this.setState({subitem: response.body_flair})
	    }.bind(this))
		var newheight;
		newheight= document.getElementById('iframe_'+this.props.id).contentWindow.document.body.scrollHeight;
		newheight = newheight + 'px'
		this.setState({height: newheight})
	}
	},
	componentWillReceiveProps: function(){
	if(this.props.stage == 'Edit'){
	  $.ajax({
	   type: 'GET',
	   url:  '/scot/api/v2/entry/'+ this.props.id
	   }).success(function(response){
	    $('#react-tinymce-addentry_ifr').contents().find("#tinymce").text(response.body_plain)
	    })
	}
	else if (this.props.title == 'Add Entry'){
	$('#react-tinymce-addentry_ifr').contents().find("#tinymce").text('')
	var timestamp = new Date()
	var output = "By You ";
	timestamp = new Date(timestamp.toString())
	output  = output + timestamp.toLocaleString()
	}
	this.setState({})
        },
	render: function() {
	var item = this.state.subitem
 	$('#react-tinymce-addentry_ifr').contents().find("#tinymce").css('height', '394px')
        return (
 	React.createElement(Modal, {onRequestClose: this.props.addedentry, style: customStyles, isOpen: this.state.addentry}, 
	React.createElement("div", {className: "modal-content"}, 
	React.createElement("div", {className: "modal-header"}, 
	React.createElement("h4", {className: "modal-title"}, this.props.title), React.createElement('div', {className: 'entry-header-info-null', style: {top: '1px', width: '100%', background: '#FFF'}}, React.createElement('h2', {style: {color: '#6C2B2B', 'font-size':'24px', 'text-align': 'left'}}, this.props.header1 ? React.createElement("div" , {style: {display: 'inline-flex'}}, React.createElement("p", null, this.props.header1), React.createElement(ReactTime, { value: this.props.createdTime * 1000, format:"MM/DD/YYYY hh:mm:ss a"}) , React.createElement("p", null, this.props.header2), React.createElement(ReactTime, {value: this.props.updatedTime * 1000,format:"MM/DD/YYYY hh:mm:ss a"}), React.createElement("p", null, this.props.header3)): output)), reply ? React.createElement('div', null, React.createElement(Frame, {id: 'iframe_'+this.props.id, styleSheets: ['/css/sandbox.css'], style: {overflow:'auto',width:'100%', height:'300px'}, frameBorder: '1', sandbox: 'allow-popups allow-same-origin'}, React.createElement('div', {dangerouslySetInnerHTML : {__html:item}}))) : null 
	), 
	React.createElement("div", {className: "modal-body", style: {height: '90%'}}, 
	React.createElement(TinyMCE, {style: {height: '394px'}, content: "", className: "inputtext",config: {plugins: 'autolink link image lists print preview',toolbar: 'undo redo | bold italic | alignleft aligncenter alignright'},onChange: this.handleEditorChange}
	)), 
	React.createElement("div", {className: "modal-footer"}, React.createElement(Dropzone, {onDrop: this.onDrop, style: {'border-width': '2px','border-color':'#000','border-radius':'4px',margin:'30px' ,padding: '30px','border-style': 'dashed', 'text-align' : 'center'}}, React.createElement("div",null,"Drop some files here or click to  select files to upload")),
	this.state.files ? React.createElement("div", null, this.state.files.map((file) => React.createElement("ul", {style: {'list-style-type' : 'none', margin:'0', padding:'0'}}, React.createElement("li", null, React.createElement("a", {href:file.preview, target:"_blank"}, file.name),React.createElement('button', {style: {width: '2em', height: '1em', 'line-height':'1px'}, className: 'btn btn-info', id: file.name, onClick: this.Close}, 'x'))))): null, 
	React.createElement("button", {className: 'btn', onClick: this.onCancel}, " Cancel"), this.state.edit ? React.createElement(
'button', {className: 'btn btn-primary', onClick: this.Edit}, 'Edit') : null,
	this.state.saved ? React.createElement("button", {className: 'btn btn-info', onClick: this.submit}, 'Submit') : null,
        this.state.enablesave ? React.createElement('button', {className: 'btn btn-success', onClick: this.Save},'Save') : null
	)
	)
	) 
        )
    },
     clickable: function(){
	this.setState({addentry: false})
	},
    Edit: function(){
	$('#react-tinymce-addentry_ifr').contents().find("#tinymce").attr('contenteditable', true)
	this.setState({saved: false, edit: false, enablesave:true})    

    },
    onCancel: function(){
	     this.props.addedentry()
	     this.setState({change:false})
	     this.props.updated()
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
	if($('#react-tinymce-addentry_ifr').contents().find("#tinymce").text() == ""){
	alert("Please fill in Text")
	}
	else {
	$('#react-tinymce-addentry_ifr').contents().find("#tinymce").attr('contenteditable', false)
	this.state.modaloptions = [{value:'Move', label:'Move'}, {value: 'Delete', label: 'Delete'}, {value: 'Make Summary', label: 'Make Summary'}, {value: 'Make Task', label: 'Make Task'}, {value: 'Permissions', label: 'Permissions'}]
	
	this.setState({saved: true, edit: true, enablesave: false, modaloptions: this.state.modaloptions})
	}
        },
	submit: function(){
	if(this.props.stage == 'Reply')
	{
	var data = new Object()
	data = JSON.stringify({parent: Number(this.props.id), body: $('#react-tinymce-addentry_ifr').contents().find("#tinymce").text(), target_id:Number(this.props.targetid) , target_type: this.props.type})

	$.ajax({
	type: 'post',
	url: '/scot/api/v2/entry',
	data: data
	}).success(function(repsonse){
		    /*if(this.state.files.length > 0){
			for(var i = 0; i<this.state.files.length; i++){	
			var file = {file:this.state.files[i].name}
			data = JSON.stringify({upload: file, target_type: this.props.type, target_id: response.id, entry_id: ''})
			$.ajax({
			   type: 'PUT',
			   url: '/scot/api/v2/file',
			   data: data
			   }).success(function(response){
			   })
			}
			}*/
	})
	this.props.addedentry()
	this.props.updated()
	}
	else if (this.props.stage == 'Edit'){
	var data = {parent: Number(this.props.id), body: $('#react-tinymce-addentry_ifr').contents().find("#tinymce").text(), target_id: Number(this.props.targetid) , target_type: this.props.type}
	$.ajax({
	type: 'put',
	url: '/scot/api/v2/entry/'+this.props.id,
	data: JSON.stringify(data)
	}).success(function(response){
		    /*if(this.state.files.length > 0){
			for(var i = 0; i<this.state.files.length; i++){	
			var file = {file:this.state.files[i].name}
			data = JSON.stringify({upload: file, target_type: this.props.type, target_id: response.id, entry_id: ''})
			$.ajax({
			   type: 'PUT',
			   url: '/scot/api/v2/file',
			   data: data
			   }).success(function(response){
			   })
			}
			}*/
	})
	this.props.addedentry()
	this.props.updated()
	}
	else  if(this.props.type == 'alert'){ 
	 var data = new Object()
	 $('.z-selected').each(function(key,value){
	 $(value).find('.z-cell').each(function(x,y){
	    if($(y).attr('name') == 'id'){  
	     data = JSON.stringify({body: $('#react-tinymce-addentry_ifr').contents().find("#tinymce").text(), target_id: Number($(y).text()), target_type: 'alert',  parent: 0})
	     $.ajax({
		type: 'post', 
		url: '/scot/api/v2/entry',
		data: data
		}).success(function(response){
		/* 
		if(this.state.files !== undefined){
			for(var i = 0; i<this.state.files.length; i++){	
			var file = {file:this.state.files[i].name}
			data = JSON.stringify({upload: file, target_type: 'alert', target_id: response.id, entry_id: ''})
			$.ajax({
			   type: 'PUT',
			   url: '/scot/api/v2/file',
			   data: data
			   }).success(function(response){
			   })
			}
		}*/
		})
		}
		})
		})
		this.props.addedentry()
		this.props.updated()
	}	
	else {
    var data = new Object();
	data = {parent: 0, body: $('#react-tinymce-addentry_ifr').contents().find("#tinymce").text(), target_id: Number(this.props.targetid) , target_type: this.props.type}
    $.ajax({
	type: 'post',
	url: '/scot/api/v2/entry',
	data: JSON.stringify(data)
	}).success(function(repsonse){
		   /* if(this.state.files.length > 0){
			for(var i = 0; i<this.state.files.length; i++){	
			var file = {file:this.state.files[i].name}
			data = JSON.stringify({upload: file, target_type: this.props.type, target_id: response.id, entry_id: ''})
			$.ajax({
			   type: 'PUT',
			   url: '/scot/api/v2/file',
			   data: data
			   }).success(function(response){
			   })
			}
			}*/
	})
	this.props.addedentry()
	this.props.updated()
	}
	},
	modalonSelect: function (option){
	var newoptions
	var color;
	if(option.label == "Move"){
	}
	else if(option.label == "Delete"){
	}
	else if (option.label == "Make Summary"){
	 $('.z-selected').each(function(key,value){
	 $(value).find('.z-cell').each(function(x,y){
	    if($(y).attr('name') == 'id'){
		var json = {'summary': 0}
		$.ajax({
		type: 'PUT',
		url: '/scot/api/v2/entry/' + $(y).text(),
		data: json
		}).success(function(response){
		alert("Created Summary")
		})
		}
		})
		})
	}
	else if (option.label == "Make Task"){
	$('.z-selected').each(function(key,value){
	 $(value).find('.z-cell').each(function(x,y){
	    if($(y).attr('name') == 'id'){
		var data = {taskstatus: 'open', assignee: ''}
		$.ajax({
		type: 'PUT',
		url: '/scot/api/v2/entry/' + $(y).text(),
		data: JSON.stringify(data)
		}).success(function(response){
		alert("Made Task")
		})
		}
		})
		})
	newoptions = [{value: "Move", label: "Move"}, {value: "Delete", label: "Delete"}, {value: "Make Summary", label: "Make Summary"}, {value: "Close Task", label: "Close Task"}, {value:"Permissions", label: "Permissions"}, {value: "Assign taks to me", label: "Assign task to me"}]
	this.state.modaloptions = newoptions
	color = 'red'
	this.state.stagecolor = color 
	}
	else if(option.label == "Reopen Task"){
	 $('.z-selected').each(function(key,value){
	 $(value).find('.z-cell').each(function(x,y){
	    if($(y).attr('name') == 'id'){
		var data = {taskstatus: 'open', assignee: ''}
		$.ajax({
		type: 'PUT',
		url: '/scot/api/v2/entry/' + $(y).text(),
		data: JSON.stringify(data)
		}).success(function(response){
		alert("Reopened Task")
		})
		}
		})
		})
	newoptions = [{value: "Move", label: "Move"}, {value: "Delete", label: "Delete"}, {value: "Make Summary", label: "Make Summary"}, {value: "Close Task", label: "Close Task"}, {value:"Permissions", label: "Permissions"}, {value: "Assign taks to me", label: "Assign task to me"}]
	this.state.modaloptions = newoptions
	color = 'red'
	this.state.stagecolor = color
	}
	else if (option.label == "Close Task"){
	 $('.z-selected').each(function(key,value){
	 $(value).find('.z-cell').each(function(x,y){
	    if($(y).attr('name') == 'id'){
		var data = {taskstatus: 'completed', assignee: ''}
		$.ajax({
		type: 'PUT',
		url: '/scot/api/v2/entry/' + $(y).text(),
		data: JSON.stringify(data)
		}).success(function(response){
		alert("Assigned Task")
		})
		}
		})
		})
	newoptions = [{value: "Move", label: "Move"}, {value: "Delete", label: "Delete"}, {value: "Make Summary", label: "Make Summary"}, {value: "Reopen Task", label: "Reopen Task"}, {value:"Permissions", label: "Permissions"}]
	this.state.modaloptions = newoptions
	color = 'green'
	this.state.stagecolor = color
	}
	else if (option.label == "Assign task to me"){
	 $('.z-selected').each(function(key,value){
	 $(value).find('.z-cell').each(function(x,y){
	    if($(y).attr('name') == 'id'){
		var data = {taskstatus: 'assigned', assignee: ''}
		$.ajax({
		type: 'PUT',
		url: '/scot/api/v2/entry/' + $(y).text(),
		data: JSON.stringify(data)
		}).success(function(response){
		alert("Assigned Task")
		})
		}
		})
		})
	color = '#C0C000'
	this.state.stagecolor = color 
	}	
	else if (option.label == "Permissions"){
	}

	this.setState({modaloptions: this.state.modaloptions, stagecolor : this.state.stagecolor })
	}
    });

module.exports = AddEntryModal

