'use strict';
var React    = require('react')
var Dropdown = require('../../../node_modules/react-dropdown')
var Modal    = require('../../../node_modules/react-modal')
var TinyMCE  = require('react-tinymce')
var marksave = false
var addentrydata = true
var Dropzone = require('../../../node_modules/react-dropzone')
var finalfiles = []
const  customStyles = {
        content : {
        top     : '50%',
        left    : '50%',
        right   : 'auto',
        bottom  : 'auto',
        marginRight: '-50%',
        transform:  'translate(-50%, -50%)',
	width: '80%',
	height: '80%'
    }
}

var timestamp = new Date()
var output = "By You ";
timestamp = new Date(timestamp.toString())
output  = output + timestamp.toLocaleString()
var AddEntryModal = React.createClass({
	getInitialState: function(){
	return {
	edit: true, stagecolor: '#000',enable: true, addentry: true, enablesave: false, modaloptions: [{value:'Move', label:'Move'}, {value: 'Delete', label: 'Delete'}, {value: 'Make Summary', label: 'Make Summary'}, {value: 'Make Task', label: 'Make Task'}, {value: 'Permissions', label: 'Permissions'}]}
	},
	render: function() {
	  
        return (
 	React.createElement(Modal, {style: customStyles, isOpen: this.state.addentry}, 
	React.createElement("div", {className: "modal-content"}, 
	React.createElement("div", {className: "modal-header"}, 
	React.createElement("h4", {className: "modal-title"}, this.props.title), React.createElement('div', {className: 'entry-header-info-null', style: {top: '1px', width: '100%', background: this.state.stagecolor}}, React.createElement('h2', {style: {color: 'white', 'font-size':'18px', 'text-align': 'left'}}, this.props.text ? this.props.text : output )) 
	), 
	React.createElement("div", {className: "modal-body", style: {height: '90%'}}, 
	React.createElement(TinyMCE, {content: "", className: "inputtext",config: {plugins: 'autolink link image lists print preview',toolbar: 'undo redo | bold italic | alignleft aligncenter alignright'},onChange: this.handleEditorChange}
	)), 
	React.createElement("div", {className: "modal-footer"}, React.createElement(Dropzone, {onDrop: this.onDrop, style: {'border-width': '2px','border-color':'#000','border-radius':'4px',margin:'30px', padding:'30px',width: '200px', 'border-style': 'dashed'}}, React.createElement("div",null,"Drop some files here or click to  select files to upload")),
	this.state.files ? React.createElement("div", null, this.state.files.map((file) => React.createElement("ul", {style: {'list-style-type' : 'none', margin:'0', padding:'0'}}, React.createElement("li", null, React.createElement("a", {href:file.preview, target:"_blank"}, file.name),React.createElement('button', {style: {width: '2em', height: '1em', 'line-height':'1px'}, className: 'btn btn-info', id: file.name, onClick: this.Close}, 'x'))))): null, 
	React.createElement("button", {className: 'btn btn-danger', onClick: this.onCancel}, " Cancel"), 
	React.createElement("button", {className: 'btn btn-success', onClick: this.submit}, 'Submit'), 	 
	React.createElement(Dropdown, {options: this.state.modaloptions, onChange: this.modalonSelect})
	)
	)
	) 
        )
    },
    onCancel: function(){
	 if(confirm('Are you sure you want to close this entry?')){
	     this.setState({addentry:false, change:false})
	    }
	else{

	}
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
	if($('#react-tinymce-addentry_ifr').contents().find("#tinymce").text() == ""){
	alert("Please fill in Text")
	}
	else if (confirm("Are you sure you want to submit?")) {
	 var data = new Object()
	 $('.z-selected').each(function(key,value){
	 $(value).find('.z-cell').each(function(x,y){
	    if($(y).attr('name') == 'id'){  
	     data = JSON.stringify({body: $('#react-tinymce-addentry_ifr').contents().find("#tinymce").text(), target_id: $(y).text(), target_type: 'alert', parent: 0})
	     $.ajax({
		type: 'PUT', 
		url: '/scot/api/v2/entry',
		data: data
		}).success(function(response){
		    console.log(response)
		    if(this.state.files.length > 0){
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
			}
		})
		}
	})
	})
	     for(var i = 0; i<this.state.files.length; i++){
		var file = {file:this.state.files[i].name}
		console.log(JSON.stringify({upload: file}))	
	     }
	     setTimeout(
	     function() {
	     }.bind(this),this.setState({edit:false, addentry: false, reload:true}),100)
	}
	else {
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
	}
	else if (option.label == "Make Task"){
	newoptions = [{value: "Move", label: "Move"}, {value: "Delete", label: "Delete"}, {value: "Make Summary", label: "Make Summary"}, {value: "Close Task", label: "Close Task"}, {value:"Permissions", label: "Permissions"}, {value: "Assign taks to me", label: "Assign task to me"}]
	this.state.modaloptions = newoptions
	color = 'red'
	this.state.stagecolor = color 
	}
	else if(option.label == "Reopen Task"){
	newoptions = [{value: "Move", label: "Move"}, {value: "Delete", label: "Delete"}, {value: "Make Summary", label: "Make Summary"}, {value: "Close Task", label: "Close Task"}, {value:"Permissions", label: "Permissions"}, {value: "Assign taks to me", label: "Assign task to me"}]
	this.state.modaloptions = newoptions
	color = 'red'
	this.state.stagecolor = color
	}
	else if (option.label == "Close Task"){
	newoptions = [{value: "Move", label: "Move"}, {value: "Delete", label: "Delete"}, {value: "Make Summary", label: "Make Summary"}, {value: "Reopen Task", label: "Reopen Task"}, {value:"Permissions", label: "Permissions"}]
	this.state.modaloptions = newoptions
	color = 'green'
	this.state.stagecolor = color
	}
	else if (option.label == "Assign task to me"){
	color = '#C0C000'
	this.state.stagecolor = color 
	}	
	else if (option.label == "Permissions"){
	}

	this.setState({modaloptions: this.state.modaloptions, stagecolor : this.state.stagecolor })
	}
    });

module.exports = AddEntryModal

