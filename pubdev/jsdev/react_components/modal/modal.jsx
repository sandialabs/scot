var Modal = require('../../../node_modules/react-modal')
var React = require('react')



var Modalcomp = React.createClass({
	getInitialState: function(){
	return {isOpen: true}
	},

	render: function(){

	return (	
	
	React.createElement(Modal, {style: customStyles, className: "Modal__Bootstrap modal-dialog", isOpen: this.isOpen}, 
	React.createElement("div", {className: "modal-content"}, 
	React.createElement("div", {className: "modal-header"}, 
	React.createElement("h4", {className: "modal-title"}, {this.props.title})
	), 
	React.createElement("div", {className: "modal-body"}, 
	React.createElement(TinyMCE, {content: "", config: {plugins: 'autolink link image lists print printview',toolbar: 'undo redo | bold italic | alignleft aligncenter alignright'},className: "inputtext", rows: "4", cols: "50", style: {overflow:"auto", border: this.state.stagecolor,resize: 'none',width: '523px', height: '300px'}}
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


})

module.exports = Modalcomp




