'use strict';

var React = require('react')
var DataGrid = require('../../../node_modules/alert-react-datagrid/react-datagrid');
var SORT_INFO;
var colsort = "id"
var valuesort = 1
var SELECTED_ID = {}
var SELECTED_ID_GRID = {}
var filter = {}
var passids = {}
var storealertids = []
var ids = 'none'
var numberofids;
var getColumn;
var backtoview = false
var changestate = false; 
var datasource;
var exportarray = []
var url = '/scot/api/v2/alertgroup'
var datacolumns = [] 
var Subgrid = require('../../../node_modules/react-datagrid')
var Dropdown = require('../../../node_modules/react-dropdown')
var ReactPanels = require('../../../node_modules/react-panels')
var Panel = ReactPanels.Panel;
var Tab = ReactPanels.Tab;
var Toolbar = ReactPanels.Toolbar;
var Content = ReactPanels.Content;
var Footer = ReactPanels.Footer;
var Textarea = require('../../../node_modules/react-textarea-autosize')
var marksave = false;
var addentrydata = false;
var viewmodalwithdata = false;
var Modal = require('../../../node_modules/react-modal')
var entrydict = []
var savedopen = false;
var alertgroup = []
var stage = false
var Editor = require('../../../node_modules/react-medium-editor')
var columns = 
[
    { name: 'id', style: {color: 'black'}},
    { name: 'status'},
    { name: 'created', style: {color: 'black'}},
    { name: 'sources', style: {color: 'black'}},
    { name: 'subject', width: 300, style: {color: 'black'}},
    { name: 'tags', style: {color: 'black'}},
    { name: 'views', style: {color: 'black'}}
]

const  customStyles = {
        content : {
        top     : '50%',
        left    : '50%',
        right   : 'auto',
        bottom  : 'auto',
        marginRight: '-50%',
        transform:  'translate(-50%, -50%)'
    }
}
function getColumns()
{
    return $.ajax({
	type: 'GET',
	url: url,
	data: {
	alertgroup: JSON.stringify(passids)
	}
	}).success(function(data){
		datacolumns = data
	});
}

var Viewentry = React.createClass({
	getInitialState: function() {
	return{edit:true,stagecolor : '5px solid #000',enable:true, reload: false, enablesave: false, modaloptions: [{value:"Please Save Entry First", label:"Please Reply to Entry First"}], open: true}
	},
	componentDidMount: function() {
	$('.viewtext').val(entrydict[storealertids.length - 1])
	this.setState({})
	},
	render: function() { 
	return (
	this.state.reload ? React.createElement(Link, null) :  
	React.createElement("div", {className: "modal-grid"}, 
	React.createElement(Modal, {style: customStyles, className: "Modal__Bootstrap modal-dialog", isOpen: this.state.open}, 
	React.createElement("div", {className: "modal-content"}, 
	React.createElement("div", {className: "modal-header"}, 
	React.createElement("h4", {className: "modal-title"}, " View Entry")
	), 
	React.createElement("div", {className: "modal-body"}, 
	React.createElement("textarea", {disabled: this.state.edit, className: "viewtext", rows: "4", cols: "50", style: {border: this.state.stagecolor,resize: 'none',width: '523px', height: '300px'}}
	)
	), 
	React.createElement("div", {className: "modal-footer"}, 
	React.createElement("button", {type: "button", onClick: this.onCancel}, "Close"),this.state.enablesave ? null :  	
	React.createElement("button", {type: "button", onClick: this.onReply}, "Reply"), React.createElement("button", {type: "button", className: "btn-danger", onClick: this.onSave}, "Save") , 	
	React.createElement(Dropdown, {options: this.state.modaloptions, onChange: this.modalonSelect})
	)
	)
	)
	)
	)
	},
	Edit: function(){
	this.setState({edit: false,enablesave:false,enable:true})
	},
	onCancel: function(){
	 if(confirm('Are you sure you want to close this entry?')){
		$('.btn-success').show()
	        $('.Subgrid').show()
	        $('.subtable').show()
	     this.setState({open:false})
	    }
	else{

	}
	},
	onSave: function(){
	if(confirm('Are you sure you want to Save this Reply')){
	$('.btn-sucess').show()
	$('.Subgrid').show()
	$('.Dropdown').show()
	    this.state.open = false
	    this.state.edit = true
	    this.state.enablesave = true
	}
	else {
	    this.state.open = true
	    this.state.edit = false
	    this.state.enablesave = false
	}
	addentrydata = true
	this.setState({open:this.state.open,edit:this.state.edit, enable:false, enablesave: this.state.enablesave})
	},
	onReply: function() {	

	this.state.modaloptions = [{value: "Move", label: "Move"}, {value: "Delete", label: "Delete"}, {value: "Mark as Summary", label: "Mark as Summary"}, {value: "Make Task", label: "Make Task"}, {value:"Permissions", label: "Permissions"}]
	$('.viewtext').val($('.inputtext').val() + "\n\n" + "Re:  " )
	this.setState({modaloptions: this.state.modaloptions, edit: false,enablesave: true})	
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

function dataSource(query)
{
	var getID = []	
      	var finalarray = [];
	var sortarray = {}
	sortarray[colsort] = valuesort
	if(changestate){
	var count = 0
	return $.ajax({
	type: 'GET',
	url: url,
	data: {
	alertgroup: JSON.stringify(passids)
	}
	}).then(function(response){
  	datasource = response
	$.each(datasource.records, function(key, value){
	finalarray[key] = {}
	
	$.each(value, function(num, item){	
	if(num == 'when')
	{
	    var date = new Date(1000 * item)
	    finalarray[key][num] = date.toLocaleString()
	}

	else{
	if(num == 'alertgroup'){
	 getID.push(item)
	}	
	var Link = React.createClass({
	render:function(){
	return(
	<div> 
  	<div className = "sub render" dangerouslySetInnerHTML = {{__html:item}} ></div>
	</div>	
	)
	}
	})
        finalarray[key][num] = React.createElement(Link, null)
	}
	})
	finalarray[key]["id"] = count
	count++

	})
	if(addentrydata){
	viewmodalwithdata = true
	var Viewalerts = React.createClass({
	getInitialState: function(){
	return{view: backtoview, reload: false}
	},
	render: function(){
	return (
	 this.state.reload ? React.createElement('div', {className: "Reload"}, React.createElement('button', {onClick: this.Reload}, 'Re Open Entry'), React.createElement(Viewentry, null)) : 
	 this.state.view ? React.createElement('div', {className: "Entries"}, React.createElement(Viewentry, null), React.createElement('button', {onClick: this.Reload}, 'Re Open Entry')) : React.createElement('button', {onClick: this.viewAlert}, 'View Entry')
	)
	},
	viewAlert: function(){
        $('.Entries').show()	
	$('.btn-success').hide()
	$('.Subgrid').hide()
	$('.subtable').hide() 
	this.setState({view:true})
	},
	Reload: function() {
	$('.btn-success').hide()
	$('.Subgrid').hide()
	$('.subtable').hide()
	savedopen = true
	this.setState({reload: true})
	}
	});

	for(var i = 0; i<entrydict.length; i++){
	
	$.each(entrydict[i], function(key, value){
	if(key != undefined){
	console.log(key)
	finalarray[key]["Entry"] = React.createElement(Viewalerts, null)
	}
	});
	}
	}
	return {
	data:  finalarray,	
	count: response.totalRecordCount,
	columns: response.columns
	}
	})
    }
    else {
	return $.ajax({
	type: 'GET',
	url: url,
	data: {
	limit: query.pageSize,
	offset: query.skip,
	sort:  JSON.stringify(sortarray),
	match: JSON.stringify(filter)
	}
	}).then(function(response){
  	datasource = response
	$.each(datasource.records, function(key, value){
	finalarray[key] = {}
	$.each(value, function(num, item){	
	if(num == 'created' || num == 'updated' || num == 'discovered' || num == 'occurred' || num == 'reported')
	{
	    var date = new Date(1000 * item)
	    finalarray[key][num] = date.toLocaleString()
	}
	else{
	 finalarray[key][num] = item
	}
	})
	})
	return {
	data: finalarray,	
	count: response.totalRecordCount
	}
	})
	}
}

function configureTable(data, props){
    var style = {}
    if(data.status == "open")
	{
	    style.color = 'red'
	}
    else if(data.status == "closed")
	{
	    style.color = 'green'
	}
    else if(data.status == "promoted")
	{
	    style.color = 'orange'
	}
    else 
	{
	    style.color = ''
	}	

	return style;
}

var Subtable = React.createClass({
	
    getInitialState: function(){
        return {
history: false, edit: false, stagecolor : '5px solid #000',enable:true, enablesave: false, modaloptions: [{value:"Please Save Entry First", label:"Please Save Entry First"}],addentry: false, reload: false, data: dataSource, back: false, columns: [],oneview: false,options:[ {value: 'Flair Off', label: 'Flair Off'}, {value: 'View Guide', label: 'View Guide'}, {value: 'View Source', label: 'View Source'}, {value:'View History', label: 'View History'}, {value: 'Add Entry', label: 'Add Entry'}, {value: 'Open Selected', label: 'Open Selected'}, {value:'Closed Selected', label: 'Closed Selected'}, {value:'Promote Selected', label:'Promote Selected'}, {value: 'Add Selected to existing event', label: 'Add Selected to existing event'}, {value: 'Export to CSV', label: 'Export to CSV'}, {value: 'Delete Selected', label: 'Delete Selected'}]}
    },
   componentDidMount: function(){
	var project = getColumns()
	project.success(function(realData){
	var last = realData.columns
	if(this.isMounted()){
	var newarray = []
	if(addentrydata){
	newarray[0] = {name:"Entry", width: 180, style: {color: 'black'}}
	for(var i = 1; i<last.length; i++) {
	newarray[i] = {name:last[i-1],width: 200, style:{color:'black'}}
	}}
	else
	{
	for(var i = 0; i<last.length; i++) {
	newarray[i] = {name:last[i],width: 200, style:{color:'black'}}
	}	    
	}
	this.setState({columns: newarray})
	}
	}.bind(this));
	},
  componentWillReceiveProps: function(){
  	var project = getColumns()
	project.success(function(realData){
	var last = realData.columns
	if(this.isMounted()){
	var newarray = []
	if(addentrydata){
	newarray[0] = {name:"Entry", width: 180, style: {color: 'black'}}
	for(var i = 1; i<last.length; i++) {
	newarray[i] = {name:last[i-1],width: 200, style:{color:'black'}}
	}}
	else
	{
	for(var i = 0; i<last.length; i++) {
	newarray[i] = {name:last[i],width: 200, style:{color:'black'}}
	}	    
	}
	this.setState({data: dataSource, columns: newarray})
	}
	}.bind(this));
	},

    onColumnResize: function(firstCol, firstSize, secondCol, secondSize){
         firstCol.width = firstSize
         this.setState({})
   },
	render: function(){	
	var isCtrl = false
	$(document).keyup(function(e){
	    if(e.which == 17 || e.which == 224 || e.which == 91 || e.which == 93) isCtrl = false;
	}).keydown(function(e){
	   if(e.which == 17 || e.which == 224 || e.which == 91 || e.which == 93) isCtrl = true;
	   if(e.which == 67 && isCtrl == true){
		$('.z-column-header').each(function(key,value){
		$(value).find('.z-content').each(function(x,y){
		    console.log($(y).text())
		})
		})
	    }
	})	
	    
	return (
	this.state.history ? 
 	React.createElement(Modal, {style: customStyles, className: "Modal__Bootstrap modal-dialog", isOpen: this.state.history}, 
	React.createElement("div", {className: "modal-content"}, 
	React.createElement("div", {className: "modal-header"}, 
	React.createElement("h4", {className: "modal-title"}, "Current History")
	), 
	React.createElement("div", {className: "modal-body"}, 
	React.createElement("textarea", {disabled: true, className: "historytext", rows: "4", cols: "50", style: {resize: 'true',width: '523px', height: '300px'}}
	)
	)
	), React.createElement("div", {className: "modal-footer"}, React.createElement('button', {className: "btn-danger", onClick: this.closeHistory}, 'Close'))
	) : 
	this.state.addentry  ?  	
	
	React.createElement(Modal, {style: customStyles, className: "Modal__Bootstrap modal-dialog", isOpen: this.state.addentry}, 
	React.createElement("div", {className: "modal-content"}, 
	React.createElement("div", {className: "modal-header"}, 
	React.createElement("h4", {className: "modal-title"}, " Add Entry")
	), 
	React.createElement("div", {className: "modal-body"}, 
	React.createElement(Editor, {disabled: this.state.edit, options: {toolbar:{buttons:['bold','italic','underline']}},className: "editable medium-editor-textarea inputtext", rows: "4", cols: "50", style: {overflow:"auto", border: this.state.stagecolor,resize: 'none',width: '523px', height: '300px'}}
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
	 :
	this.state.reload ? React.createElement(Subtable, {className: "MainSubtable"},null) :  
	this.state.back ? React.createElement(Maintable, null) : React.createElement("div" , {className: "subtable"}, React.createElement('button', {className: 'btn-success', onClick: this.goBack}, 'Back'), this.state.oneview ? React.createElement(Dropdown, {placeholder: 'Select an option', options: this.state.options, onChange: this.onSelect}) : null ,  React.createElement(Subgrid, {className: "Subgrid",
            ref: "dataGrid", 
            idProperty: "id",
	    setColumns: true, 
            dataSource: this.state.data, 
            columns: this.state.columns, 
	    onColumnResize: this.onColumnResize, 
	    selected: SELECTED_ID_GRID, 
	    onSelectionChange: this.onSelectionChange, 
	    defaultPageSize:20 ,
	    onColumnOrderChange: this.handleColumnOrderChange, 
	    pagination: false, 
	    paginationToolbarProps: {pageSizes: [5,10,20]},  
	    withColumnMenu: true, 
	    showCellBorders: true,
	    sortable: false,
	    rowHeight: 100,
	    rowStyle: configureTable,
	    onFilter: this.handleFilter}
	)
        )
	);
   },
    handleFilter: function(column, value, allFilterValues){
	/*
	var data = {}
	Object.keys(allFilterValues).forEach(function(name){
	    var columnFilter = (allFilterValues[name] + '').toUpperCase()
	    $('.z-table').each(function(key,value) {
	        $(value).find('.z-cell').each(function(x,y){
		    if($(y).attr('name').toUpperCase() == name.toUpperCase()) {
			if(columnFilter == $(y).text().toUpperCase()){
			    $('.z-table').each(function(key,value){
				$(value).find('.z-cell').each(function(x,y){
				    var Link = React.createClass({
					render:function(){
					return(
					<div>
	  					<div className = "sub render" dangerouslySetInnerHTML={{__html:$(y).html()}} ></div>	
					</div>
					)
			}
			})
				    data[x] = {}
				    data[x][$(y).attr('name')] = React.createElement(Link, null)
			})
		})
		}
		}
		})
		})
		})
	console.log(data)
    	this.setState({data: data,reload:false})
	*/
    },
    goBack : function(){
	stage = false
	SELECTED_ID_GRID = {}
	changestate = false
	passids = {}
	url = '/scot/api/v2/alertgroup'	
	this.setState({columns: [], back: true})
    },
    handleColumnOrderChange : function(index, dropIndex){
	var col = this.state.columns[index]
	this.state.columns.splice(index,1)
	this.state.columns.splice(dropIndex, 0, col)
	this.setState({})
	},
    onSelectionChange: function(newSelection, data){
	SELECTED_ID_GRID = newSelection
	var selected = []
	Object.keys(newSelection).forEach(function(id){
	selected.push(newSelection[id].id)
	})
	var ids = selected.length? selected.join(',') : 'none'
	storealertids = ids.split(',')	
	this.setState({oneview:true})
	},
    closeHistory: function(){
	this.setState({history: false, reload: true})	
    },
    onSelect: function(option){
	if(option.label == "Flair Off"){
	$('.z-selected').each(function(key, value){
	    $(value).find('.z-cell').each(function(num,content){
		var con = $(content).find('.entity')
		con.each(function(x,y){
		    $(y).addClass('entity-off');
		    $(y).removeClass('entity')
	});
	});
	});

	this.state.options = [{value: 'Flair On', label: 'Flair On'}, {value: 'View Guide', label: 'View Guide'}, {value: 'View Source', label: 'View Source'}, {value:'View History', label: 'View History'}, {value: 'Add Entry', label: 'Add Entry'}, {value: 'Open Selected', label: 'Open Selected'}, {value:'Closed Selected', label: 'Closed Selected'}, {value:'Promote Selected', label:'Promote Selected'}, {value: 'Add Selected to existing event', label: 'Add Selected to existing event'}, {value: 'Export to CSV', label: 'Export to CSV'}, {value: 'Delete Selected', label: 'Delete Selected'}]
	this.setState({options: this.state.options})
	}

	else if(option.label == "Flair On"){
	$('.z-selected').each(function(key, value){
	    $(value).find('.z-cell').each(function(num,content){
		var con = $(content).find('.entity-off')
		con.each(function(x,y){
		    $(y).addClass('entity');
		    $(y).removeClass('entity-off')
	});
	});
	});

	this.state.options = [{value: 'Flair Off', label: 'Flair Off'}, {value: 'View Guide', label: 'View Guide'}, {value: 'View Source', label: 'View Source'}, {value:'View History', label: 'View History'}, {value: 'Add Entry', label: 'Add Entry'}, {value: 'Open Selected', label: 'Open Selected'}, {value:'Closed Selected', label: 'Closed Selected'}, {value:'Promote Selected', label:'Promote Selected'}, {value: 'Add Selected to existing event', label: 'Add Selected to existing event'}, {value: 'Export to CSV', label: 'Export to CSV'}, {value: 'Delete Selected', label: 'Delete Selected'}]
	
	this.setState({options:this.state.options})
	}
	else if(option.label == "View Guide"){
	    window.open('/guide.html#' + 1);
	}
	else if(option.label == "View Source"){
	var win = window.open('viewSource.html', '_blank')
	var html = $('.z-selected').html()
	
	var plain = $('.z-selected').text()
	win.onload = function() {   if(html != undefined){
	$(win.document).find('#html').text(html)
	} else {$(win.document).find('.html').remove() }
	if(plain != undefined) {
	$(win.document).find('#plain').text(plain)
	} else { $(win.document).find('.plain').remove() }
	}
	}
	else if (option.label == "View History"){
	/*$.ajax({
	    type: 'GET',
	    url: 'url',
    	   }).done(function(response){
	    $(response.data.history).each(function(index,history_entry) {
	      $('.historytext').append( getHistory)
	     });
	})*/
	this.setState({history: true})
	}	
	else if(option.label == "Add Entry"){
	this.setState({addentry: true})
	}
	else if (option.label == "Open Selected"){
	var data = new Object();
	$('.z-selected').each(function(key,value){
	$(value).find('.z-cell').each(function(x,y){
	    if($(y).attr('name') == "alertgroup"){
		data = JSON.stringify({status:'open'})
		$.ajax({
			type: 'PUT',
			url: '/scot/api/v2/alert/'+$(y).text(),
			data: data
		}).success(function(response){
	});
	}
	});
	});
	this.setState({reload: true})
        }
	else if (option.label == "Promote Selected"){
		//var getIDS = 
	 /*
	var data = new Object()
	 var total = ids.length
	 $(ids).each(function(index, alert) { 
	var type = 'PUT'
	var curr_date = Math.round(new Date().getTime()/1000);
		data = JSON.stringify({
		status:'open'
		})
	$.ajax({
	    type: type,
	    url: url
	    data: data
	}).success(function(response){
	 console.log(response)
	});
	})
	*/
	this.setState({reload: true})
	}
	else if(option.label == "Closed Selected"){
	var data = new Object();
	var curr = Math.round(new Date().getTime() / 1000);
	$('.z-selected').each(function(key,value){
	$(value).find('.z-cell').each(function(x,y){
	    if($(y).attr('name') == "alertgroup"){
		data = JSON.stringify({status:'closed', closed: curr})
		$.ajax({
			type: 'PUT',
			url: '/scot/api/v2/alert/'+$(y).text(),
			data: data
		}).success(function(response){
	});
	}
	});
	});
	this.setState({reload: true})
	}
	else if(option.label == "Add Selected to existing event"){
	var text = prompt("Please Enter Event ID to promote into")
	this.setState({reload: true})
	/*
	var ids = new Array()
	var data = { 
	id: selected,
	thing: 'alert'
	};
	$.ajax({
	type: 'PUT',
	url: url,
	data: JSON.stringify(data)
	}).done(function(response){
	if(response.status == 'ok'){
	window.location = '/#/event/' + response.id;}
	
	})
	*/
	}
	else if (option.label == "Export to CSV"){
	    var keys = []
	    $.each(this.state.columns, function(key, value){
		keys.push(value['name']);
	    });
	    var csv = ''
	    $('.z-selected').each(function(key, value){
                var storearray = []
		$(value).find('.z-content').each(function(x,y) {
		    var obj = $(y).text()
			obj = obj.replace(/,/g,'|')
		    storearray.push(obj)
		});
		csv += storearray.join() + '\n'
	    });

	    var result = keys.join() + "\n"
	    csv = result + csv;
	    var data_uri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv)
	    this.setState({reload: true})
	    window.open(data_uri)		
	}
	else {
	var data = new Object();
	var curr = Math.round(new Date().getTime() / 1000);
	$('.z-selected').each(function(key,value){
	$(value).find('.z-cell').each(function(x,y){
	    if($(y).attr('name') == "alertgroup"){
		$.ajax({
			type: 'DELETE',
			url: '/scot/api/v2/alert/'+$(y).text(),
			data: data
		}).success(function(response){
	});
	}
	});
	});
	this.setState({reload: true})	
	}
	
	},
	submit: function(){
	if(marksave)
	{
	    var store = {}
	    for(var i = 0; i<storealertids.length; i++){
		store[storealertids[i]] = {}
		store[storealertids[i]] = $('.inputtext').val()  	
	     }
	     entrydict.push(store)          
	    addentrydata = true
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
	var append_reply = '<div class = "Reply Entry"> <' + Dropdown + ' options = '+this.state.options+' onChange ='+this.onSelect+'/></div>'

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

var Maintable = React.createClass({

    getInitialState: function(){
           return {data: dataSource, showAlertbutton: false, viewAlert:false,csv:true};
         },
    onColumnResize: function(firstCol, firstSize, secondCol, secondSize){
        firstCol.width = firstSize
        this.setState({})
    },
    componentDidMount: function(){
	this.setState({})
    },
    componentWillReceiveProps: function(){

	this.setState({})
    },
    render: function() {
	return (
	    stage ?  React.createElement(Subtable, null) : 
	    React.createElement("div", {className: "allComponents"}, this.state.csv ? React.createElement('button', {onClick: this.exportCSV}, 'Export to CSV') : null , this.state.showAlertbutton ? React.createElement('button',{className: 'btn-success',onClick: this.viewAlerts},"View Alert(s)") : null, this.state.viewAlert ? React.createElement("div" , {className: "subtable"}, React.createElement(Subtable,null)) :  
	    React.createElement(DataGrid, {
            ref: "dataGrid", 
            idProperty: "id",
            dataSource: this.state.data, 
            columns: columns, 
            onColumnResize: this.onColumnResize, 
	    onFilter: this.handleFilter, 
	    selected: SELECTED_ID, 
	    onSelectionChange: this.onSelectionChange, 
	    defaultPageSize:20 ,  
	    pagination: true, 
	    paginationToolbarProps: {pageSizes: [5,10,20]}, 
	    onColumnOrderChange: this.handleColumnOrderChange, 
	    sortInfo: SORT_INFO, 
	    onSortChange: this.handleSortChange,
	    showCellBorders: true,
	    rowStyle: configureTable}
	)
        ));
    },
    exportCSV: function(){
        var keys = []
	$.each(columns, function(key, value){
            keys.push(value['name']);
	  });
	var csv = ''
	$('.z-even').each(function(key, value){
	var storearray = []
        $(value).find('.z-content').each(function(x,y) {
            var obj = $(y).text()
		obj = obj.replace(/,/g,'|')
		storearray.push(obj)
	});
	    csv += storearray.join() + '\n'
	});

	$('.z-odd').each(function(key, value){
        var storearray = []
        $(value).find('.z-content').each(function(x,y) {
            var obj = $(y).text()
		obj = obj.replace(/,/g,'|')
		storearray.push(obj)
	});
	    csv += storearray.join() + '\n'
	});
        var result = keys.join() + "\n"
	csv = result + csv;
	var data_uri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv)
	window.open(data_uri)		
    },
    viewAlerts: function(){
	stage = true
	changestate = true
	url = '/scot/api/v2/supertable'	
	this.setState({viewAlert: true, showAlertbutton:false,csv:false})
    },
    handleSortChange : function(sortInfo){
	SORT_INFO = sortInfo
	$.each(SORT_INFO, function(key,value){
	colsort = value['name']	
	valuesort = value['dir']
	})
	this.setState({})
	},
    handleColumnOrderChange : function(index, dropIndex){
	var col = columns[index]
	columns.splice(index,1)
	columns.splice(dropIndex, 0, col)
	this.setState({})
	},
    onSelectionChange: function(newSelection){
	SELECTED_ID = newSelection
	var selected = []
	Object.keys(newSelection).forEach(function(id){
	selected.push(newSelection[id].id)
	})
	ids = selected.length? selected.join(',') : 'none'
        passids['alertgroup'] = ids.split(",")
	numberofids = selected.length
	this.setState({showAlertbutton: true, viewAlert: false})
	},
    handleFilter: function(column, value, allFilterValues){
	filter = {}
	Object.keys(allFilterValues).forEach(function(name){
	var columnFilter = allFilterValues[name]
	if(columnFilter == ''){
	return
	}
	if(name == "id" || name == "views"){
	filter[name] = [columnFilter]
	}
	else if(name == "created"){
	filter[name] = columnFilter;
	}
	else{
	filter[name] = columnFilter
	
	}
	})
	this.setState({})
    }

});

module.exports = Maintable

/*
  React.createElement("div", {className: "btn-toolbar"}, React.createElement("div", {className: "btn-group"}, React.createElement("a", {className: "btn", alt: "bold", title: "bold"}, React.createElement("i", {className:"icon-bold"})), React.createElement("a", {className: "btn", alt: "italic", title: "italic"},React.createElement("i", {className:"icon-italic"})), React.createElement("span",{className: "dropdown"}, React.createElement("a", {className:"btn dropdown-toggle", "data-toggle":"dropdown", style: {"border-top-right-radius" : "0px","border-bottom-right-radius":"0px","border-right":"0px"}, alt: "Font Size", title: "Font Size"},"Font Size", React.createElement("span", {className:"caret")))))*/
