var Viewentry = React.createClass({
getInitialState: function() {
return{open: ventry}
},
componentWillMount: function(){
	this.setState({open:true})
	ventry = true
},
componentWillReceiveProps: function() {
	this.clickable1()
	ventry = true
},
render: function() {

return (
React.createElement("div", {className: "modal-grid"}, 
React.createElement(Modal, {onRequestClose: this.clickable1, style: customStyles, className: "Modal__Bootstrap modal-dialog", isOpen: this.state.open}, 
React.createElement("div", {className: "modal-content", style: {height: '100%'}}, 
React.createElement("div", {className: "modal-header"}, 
React.createElement("h4", {className: "modal-title"}, " View Entry")
), 
React.createElement("div", {className: "modal-body", style: {height: '80%'}}, 
React.createElement('div', {style: {height: '100%'}}, React.createElement(Alertentry, {type: 'alert', id: this.props.id}))
), 
React.createElement("div", {className: "modal-footer"}, 
React.createElement("button", {type: "button", onClick: this.onCancel, className: 'btn'}, "Close")
)
)
)
)
)
},
clickable1: function(){
if(!ventry){
this.setState({open: true})
} else{
this.setState({open:false})
}
},
onCancel: function(){
     this.setState({open:false, change:false})
}
});
