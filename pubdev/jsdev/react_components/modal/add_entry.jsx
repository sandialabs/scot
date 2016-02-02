var React    = require('react')
var Dropdown = require('../../../node_modules/react-dropdown')
var Modal    = require('../../../node_modules/react-modal')
var marksave = false
var addentrydata = false


const  customStyles = {
        content : {
        top     : '50%',
        left    : '50%',
        right   : 'auto',
        bottom  : 'auto',
        marginRight: '-50%',
        transform:  'translate(-50%, -50%)',
	width: '80%'
    }
}

var Addentrymodal = React.createClass({
	getInitialState: function(){
	return {
	edit: true, stagecolor: '5px solid #000',enable: true, addentry: true, enablesave: false, modaloptions: [{value:"Please Save Entry First", label:"Please Save Entry First"}]}
	},

	render: function() {
	return (
	React.createElement(Modal, {style: customStyles, className: "Modal__Bootstrap modal-dialog", isOpen: this.state.addentry}, 
	React.createElement("div", {className: "modal-content"}, 
	React.createElement("div", {className: "modal-header"}, 
	React.createElement("h4", {className: "modal-title"}, " Add Entry")
	), 
	React.createElement("div", {className: "modal-body", style: {height: '90%'}}, 
	React.createElement(TinyMCE, {content: "", config: {plugins: 'autolink link image lists print printview',toolbar: 'undo redo | bold italic | alignleft aligncenter alignright'},className: "inputtext", style: {overflow:"auto", border: this.state.stagecolor}}
	)), 
	React.createElement("div", {className: "modal-footer"}, React.createElement("input", {type: "file", name: "file_attach", className: "input-field attachfile"}), 
	React.createElement("button", {type: "button", onClick: this.onCancel}, " Cancel"), 
	this.state.enablesave ? null : React.createElement("button", {type: "button", onClick: this.onSave, disabled: this.state.enablesave}, "Save"), 	
 
	this.state.enablesave ? React.createElement("button", {type: "button", onClick: this.Edit, disabled: this.state.enable}, "Edit") : null, this.state.enablesave ?  
	React.createElement("button", {type: "button", className: "btn-success", onClick: this.submit, disabled: this.state.enable}, "Submit") : null, 
	React.createElement(Dropdown, {options: this.state.modaloptions, onChange: this.modalonSelect})
	)
	)
	)
	)
	},
	submit: function(){
	if(marksave)
	{
/*	    var store = {}
	    for(var i = 0; i<storealertids.length; i++){
		store[storealertids[i]] = {}
		store[storealertids[i]] = $('.inputtext').val()  	
	     }
	     entrydict.push(store)          
	    addentrydata = true

*/
	    this.setState({edit:false, addentry: false, reload:true})

	}
        },
	Edit: function(){
	$('.inputtext').attr("contenteditable", true)
	this.setState({edit: false,enablesave:false,enable:true})
	},
	onCancel: function(){
	 if(confirm('Are you sure you want to cancel this entry?')){
	     this.setState({reload: true, addentry: false})
	    }
	else{

	}
	},
	onSave: function(){
	if($('.inputtext').text() == "")	{
	alert("Please fill in Text")
	}
	else {
	console.log($('.attachfile').val())
	$('.inputtext').attr("contenteditable", false)
	marksave = true;	
	this.state.modaloptions = [{value: "Move", label: "Move"}, {value: "Delete", label: "Delete"}, {value: "Mark as Summary", label: "Mark as Summary"}, {value: "Make Task", label: "Make Task"}, {value:"Permissions", label: "Permissions"}]
	this.setState({reload: false, addentry: true,edit:true, modaloptions : this.state.modaloptions, enable:false, enablesave: true})
	}
	},

	onReply: function() {
	if(marksave){
	var domnode = this.getDOMNode();
	var append_reply = '<div class = "Reply Entry"> <' + Dropdown + ' options = '+this.state.modaloptions+' onChange ='+this.onSelect+'/></div>'

	$(domnode).append($(domnode).html())	


	}
	else {
	alert("You must save this entry before you can reply to it")
	}
	//var domnode = this.getDOMNode();
	//var dom = React.createElement(Addpanel, null)	

	//console.log($(domnode).html())
	//$(domnode).append($(domnode).html())
	},

	modalonSelect: function (option){
	var newoptions
	var color;
	//getEntry
	if(option.label == "Move"){
	}
	else if(option.label == "Delete"){
	}
	else if (option.label == "Mark as Summary"){
	}
	else if (option.label == "Make Task"){
	newoptions = [{value: "Move", label: "Move"}, {value: "Delete", label: "Delete"}, {value: "Mark as Summary", label: "Mark as Summary"}, {value: "Close Task", label: "Close Task"}, {value:"Permissions", label: "Permissions"}, {value: "Assign taks to me", label: "Assign task to me"}]
	this.state.modaloptions = newoptions
	color = '5px solid #933'
	this.state.stagecolor = color 
	}
	else if(option.label == "Reopen Task"){
	newoptions = [{value: "Move", label: "Move"}, {value: "Delete", label: "Delete"}, {value: "Mark as Summary", label: "Mark as Summary"}, {value: "Close Task", label: "Close Task"}, {value:"Permissions", label: "Permissions"}, {value: "Assign taks to me", label: "Assign task to me"}]
	this.state.modaloptions = newoptions
	color = '5px solid #933'
	this.state.stagecolor = color
	}
	else if (option.label == "Close Task"){
	newoptions = [{value: "Move", label: "Move"}, {value: "Delete", label: "Delete"}, {value: "Mark as Summary", label: "Mark as Summary"}, {value: "Reopen Task", label: "Reopen Task"}, {value:"Permissions", label: "Permissions"}]
	this.state.modaloptions = newoptions
	color = '5px solid #696'
	this.state.stagecolor = color
	}
	else if (option.label == "Assign task to me"){
	color = '5px solid #B8B800'
	this.state.stagecolor = color 
	}	
	else if (option.label == "Permissions"){
	console.log($('.inputtext').val())
	}

	this.setState({modaloptions: this.state.modaloptions, stagecolor : this.state.stagecolor })
	}
    });

module.exports = Addentrymodal

