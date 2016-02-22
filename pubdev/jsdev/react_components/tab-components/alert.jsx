'use strict';

var React = require('react')
var HistoryView = require('../modal/history.jsx')
var DataGrid = require('../../../node_modules/alert-react-datagrid/react-datagrid');
var SORT_INFO;
var colsort = "id"
var valuesort = 1
var SELECTED_ID = {}
var SELECTED_ID_GRID = {}
var filter = {}
var passids = {}
var storealertids = []
var historyview = ''
var ids = 'none'
var numberofids;
var getColumn;
var backtoview = false
var changestate = false; 
var datasource;
var exportarray = []
var url = '/scot/api/v2/alertgroup'
var savedfsearch;
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
var savedsearch = false
var stage = false
var tinycount = 0;
var Dropzone = require('../../../node_modules/react-dropzone');
var TinyMCE = require('../../../node_modules/react-tinymce')
var Crouton = require('../../../node_modules/react-crouton')
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
        transform:  'translate(-50%, -50%)',
	width: '80%'
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
	React.createElement("textarea", {disabled: this.state.edit, className: "viewtext", rows: "4", cols: "50", style: {border: this.state.stagecolor,resize: 'none',width: '1389px', height: '300px'}}
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
	else if (item == 'promoted'){
	
	var Promote = React.createClass({
	render: function() {
	return (
	React.createElement('button', {className: 'btn btn-warning', onClick: this.launch}, 'promoted')
	)
	},
	launch: function(){
	$('.z-selected').each(function(key, value){
	$(value).find('.z-cell').each(function(x,y){	  
	    if($(y).attr('name') == 'id'){
		$.ajax({
			type: 'GET',
			url: '/scot/api/v2/alert/'+$(y).text() + '/event'
		}).success(function(response){
		   $.each(response, function(x,y){
	           $.each(y, function(key, value){
		   $.each(value, function(r,s){
	           if(r == 'id'){
		    	window.location = '#/event/' + s
	              }
	           })
		})
		})
	
	});
	}
	});
	});
	}
	});
	finalarray[key][num] = React.createElement(Promote, null)
	}
	else{	
	var Link = React.createClass({
	render:function(){
	return(
	<div> 
  	<div className = "subrender" dangerouslySetInnerHTML = {{__html:item}} ></div>
	</div>	
	)
	}
	})
        finalarray[key][num] = React.createElement(Link, null)
	}
	})
	finalarray[key]["index"] = count
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
	addentrydata = false
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

viewby: [],historyid: 0, history: false, edit: false, stagecolor : 'black',enable:true, enablesave: false, modaloptions: [{value:"Please Save Entry First", label:"Please Save Entry First"}],addentry: false, reload: false, data: dataSource, back: false, columns: [],oneview: false,options:[ {value: 'Flair Off', label: 'Flair Off'}, {value: 'View Guide', label: 'View Guide'}, {value: 'View Source', label: 'View Source'}, {value:'View History', label: 'View History'}, {value: 'Add Entry', label: 'Add Entry'}, {value: 'Open Selected', label: 'Open Selected'}, {value:'Closed Selected', label: 'Closed Selected'}, {value:'Promote Selected', label:'Promote Selected'}, {value: 'Add Selected to existing event', label: 'Add Selected to existing event'}, {value: 'Export to CSV', label: 'Export to CSV'}, {value: 'Delete Selected', label: 'Delete Selected'}]}
    },
   componentWillMount: function(){
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
	setTimeout(function() { this.setState({columns: newarray})}.bind(this), 100)
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
    viewHistory: function(){
	this.setState({history: false})
    },

    onColumnResize: function(firstCol, firstSize, secondCol, secondSize){
         firstCol.width = firstSize
         this.setState({})
   },
	render: function(){	
	$('.z-table').each(function(key, value){
	   $(value).find('.z-content').each(function(x,y){
		if($(y).text() == 'closed'){
		    $(y).css({'color':'green', 'font-weight' : 'bold'})
		}
		else if($(y).text() == 'open'){
		    $(y).css({'color' : 'red', 'font-weight':'bold'})
		}
		else {
		    $(y).css('color', 'black')
		}
	})
	})	    
	return (
	this.state.history ? React.createElement(HistoryView, {type:'alertgroup', id: this.state.historyid, historyToggle: this.viewHistory}) 
        : 
	this.state.addentry  ?  	
	
	React.createElement(Modal, {style: customStyles, isOpen: this.state.addentry}, 
	React.createElement("div", {className: "modal-content"}, 
	React.createElement("div", {className: "modal-header"}, 
	React.createElement("h4", {className: "modal-title"}, " Add Entry")
	), 
	React.createElement("div", {className: "modal-body", style: {background: this.state.stagecolor, height: '90%'}}, 
	React.createElement(TinyMCE, {content: "", className: "inputtext",config: {plugins: 'autolink link image lists print preview',toolbar: 'undo redo | bold italic | alignleft aligncenter alignright'},onChange: this.handleEditorChange}
	)), 
	React.createElement("div", {className: "modal-footer"}, React.createElement(Dropzone, {onDrop: this.onDrop, style: {'border-width': '2px','border-color':'#000','border-radius':'4px',margin:'30px', padding:'30px',width: '200px', 'border-style': 'dashed'}}, React.createElement("div",null,"Drop some files here or click to  select files to upload")),
	this.state.files ? React.createElement("div", null, this.state.files.map((file) => React.createElement("a", {style: {border: '2px solid black'}, href:file.preview, target:"_blank"}, file.name ))): null, 
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
	this.state.back ? React.createElement(Maintable, null) : React.createElement("div" , {className: "subtable"}, React.createElement('button', {className: 'btn btn-warning', onClick: this.goBack}, 'Back to Alerts'),React.createElement('div', {className: 'entry-header-info-null', style:{top: '1px', width: '100%',background: '#000'}}, React.createElement('h2',{ style: {color: 'white', 'font-size': '24px', 'text-align':'left'}}, 'Id(s) : ' +  ids ), React.createElement('h2', {style: {color: 'white', 'font-size':'24px', 'text-align' : 'left'}}, 'Viewed By : ' + this.state.viewby.join(','))), this.state.oneview ? React.createElement(Dropdown, {placeholder: 'Select an option', options: this.state.options, onChange: this.onSelect}) : null ,  React.createElement(Subgrid, {className: "Subgrid",
            ref: "dataGrid", 
            idProperty: "index",
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
	    rowStyle: configureTable}
	)
        )
	);
   },
    onDrop: function(files){
        this.setState({files: files})

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
	selected.push(newSelection[id].index)
	})
	var ids = selected.length? selected.join(',') : 'none'
	storealertids = ids.split(',')	
	this.setState({oneview:true,setcss: false})
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
	    if(storealertids.length > 1){
		alert("Select only one id to view guide")
		this.setState({reload: true})
	    }
	    else {
	    $('.z-selected').each(function(key, value){
	    $(value).find('.z-cell').each(function(x,y){
		if($(y).attr('name') == 'id'){
	    	window.open('/guide.html#' + $(y).text());
		}
		})
		})
		this.setState({reload:true})
	    }
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
	historyview = ''
        var id = 0;
	if(storealertids.length > 1){
	    alert("Select only one id to view history")
	    this.setState({reload:true})
	}
	else {  	
	$('.z-selected').each(function(key,value){
	    $(value).find('.z-cell').each(function(x,y){
		if($(y).attr('name') == 'id'){
		    id = $(y).text()
		}
	/*
	$.ajax({
	    type: 'GET',
	    url: '/scot/api/v2/alertgroup/'+$(y).text()+'/history',
    	   }).done(function(response){
		history += $(y).text() + "\n" + response.view_history +"\n"
	})

	*/
	})
	})
	this.setState({historyid: id, history: true})
	}
	}	
	else if(option.label == "Add Entry"){
	this.setState({addentry: true})
	}
	else if (option.label == "Open Selected"){
	var data = new Object();
	$('.z-selected').each(function(key,value){
	$(value).find('.z-cell').each(function(x,y){
	    if($(y).attr('name') == "id"){
		data = JSON.stringify({status:'open'})
		$.ajax({
			type: 'PUT',
			url: '/scot/api/v2/alert/'+$(y).text(),
			data: data
		}).success(function(response){
		    $('.z-selected').each(function(t,u){
		    $(u).find('.z-cell').each(function(r,s){
			if($(s).attr('name') == "alertgroup"){
		         data = JSON.stringify({status: 'open'})
		        $.ajax({
			    type: 'PUT',
			    url: '/scot/api/v2/alertgroup/' + $(s).text(),
			    data: data
		        }).success(function(response){
			   });		
			   }
			   });
			   });
	});
	}
	});
	});
	setTimeout(
	function() {
	this.setState({reload:true})
	}.bind(this), 500)
        }
	else if (option.label == "Promote Selected"){
	$('.z-selected').each(function(key,value){
	$(value).find('.z-cell').each(function(x,y){
	    if($(y).attr('name') == "id"){
		data = JSON.stringify({status: 'promoted',promote: 'new'})			
			$.ajax({
			type: 'PUT',
			url: '/scot/api/v2/alert/' + $(y).text(),
			data: data
		}).success(function(response){
		    $('.z-selected').each(function(t,u){
		    $(u).find('.z-cell').each(function(r,s){
			if($(s).attr('name') == "alertgroup"){
		         data = JSON.stringify({status: 'promoted'})
		        $.ajax({
			    type: 'PUT',
			    url: '/scot/api/v2/alertgroup/' + $(s).text(),
			    data: data
		        }).success(function(response){
			   });		
			   }
			   });
			   }); 
	});
	}
	})
	});
	setTimeout(
	function() {
	this.setState({reload:true})
	}.bind(this),500)
	}
	else if(option.label == "Closed Selected"){
	var data = new Object();
	var curr = Math.round(new Date().getTime() / 1000);
	$('.z-selected').each(function(key,value){
	$(value).find('.z-cell').each(function(x,y){
	    if($(y).attr('name') == "id"){
		data = JSON.stringify({status:'closed', closed: curr})
		$.ajax({
			type: 'PUT',
			url: '/scot/api/v2/alert/'+$(y).text(),
			data: data
		}).success(function(response){
		    $('.z-selected').each(function(t,u){
		    $(u).find('.z-cell').each(function(r,s){
			if($(s).attr('name') == "alertgroup"){
		         data = JSON.stringify({status: 'closed'})
		        $.ajax({
			    type: 'PUT',
			    url: '/scot/api/v2/alertgroup/' + $(s).text(),
			    data: data
		        }).success(function(response){
			   });		
			   }
			   });
			   });
	});
	}
	});
	});
	setTimeout( 
	function(){
	this.setState({reload: true})
	}.bind(this),500)
	}
	else if(option.label == "Add Selected to existing event"){
	var text = prompt("Please Enter Event ID to promote into")
	$('.z-selected').each(function(key, value){
	$(value).find('.z-cell').each(function(x,y){
	if($(y).attr('name') == "id") {
	var data = { 
	promote: text
	};
	$.ajax({
	type: 'PUT',
	url: '/scot/api/v2/alert/' + $(y).text(),
	data: JSON.stringify(data)
	}).success(function(response){
	if($.isNumeric(text)){
	window.location = '#/event/' + text
	}
	})
	}
	});
	})
	setTimeout(function() {this.setState({reload:true})}.bind(this), 500)
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
	if(confirm("Are you sure you want to Delete? This action can not be undone.")){
	var data = new Object();
	var curr = Math.round(new Date().getTime() / 1000);
	$('.z-selected').each(function(key,value){
	$(value).find('.z-cell').each(function(x,y){
	    if($(y).attr('name') == "id"){
		$.ajax({
			type: 'DELETE',
			url: '/scot/api/v2/alert/'+$(y).text(),
			data: data
		}).success(function(response){
	});
	}
	});
	});
	setTimeout(function() {this.setState({reload: true})}.bind(this), 300)	
	}
	else {
	    this.setState({reload: true})
 	}
	}	
	},
	submit: function(){
	if(marksave)
	{
	    var store = {}
	    for(var i = 0; i<storealertids.length; i++){
		store[storealertids[i]] = {}
		store[storealertids[i]] = $('#react-tinymce-'+tinycount+'_ifr').contents().find("#tinymce").text()  	
	     }
	     entrydict.push(store)          
	     addentrydata = true
	     tinycount++;
	     setTimeout(
	     function() {
	     }.bind(this),this.setState({edit:false, addentry: false, reload:true}),100)
	}

        },
	Edit: function(){
        $('#react-tinymce-'+tinycount+'_ifr').contents().find("#tinymce").attr("contenteditable", true)
	this.setState({edit: false,enablesave:false,enable:true})
	},
	onCancel: function(){
	 if(confirm('Are you sure you want to cancel this entry?')){
	     tinycount++;
	     this.setState({reload: true, addentry: false})
	    }
	else{
	
	}
	},
	onSave: function(){
	if($('#react-tinymce-'+tinycount+'_ifr').contents().find("#tinymce").text() == "")	{
	alert("Please fill in Text")
	}
	else {
	$('#react-tinymce-'+tinycount+'_ifr').contents().find("#tinymce").attr("contenteditable", false)
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
	color = 'red'
	this.state.stagecolor = color 
	}
	else if(option.label == "Reopen Task"){
	newoptions = [{value: "Move", label: "Move"}, {value: "Delete", label: "Delete"}, {value: "Mark as Summary", label: "Mark as Summary"}, {value: "Close Task", label: "Close Task"}, {value:"Permissions", label: "Permissions"}, {value: "Assign taks to me", label: "Assign task to me"}]
	this.state.modaloptions = newoptions
	color = 'red'
	this.state.stagecolor = color
	}
	else if (option.label == "Close Task"){
	newoptions = [{value: "Move", label: "Move"}, {value: "Delete", label: "Delete"}, {value: "Mark as Summary", label: "Mark as Summary"}, {value: "Reopen Task", label: "Reopen Task"}, {value:"Permissions", label: "Permissions"}]
	this.state.modaloptions = newoptions
	color = 'green'
	this.state.stagecolor = color
	}
	else if (option.label == "Assign task to me"){
	color = 'yellow'
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
           return {fsearch: '',viewfilter: false, data: dataSource, showAlertbutton: false, viewAlert:false,csv:true};
         },
    onColumnResize: function(firstCol, firstSize, secondCol, secondSize){
        firstCol.width = firstSize
        this.setState({})
    },
    componentWillMount: function(){
	if(this.props.supertable !== undefined){
	    if(this.props.supertable.length > 0){
		window.history.pushState({}, 'Scot', '#/alert/'+ this.props.supertable.join('+'))
		passids = this.props.supertable
		ids = this.props.supertable.join(',')
		stage = true
		changestate = true
		url = '/scot/api/v2/supertable'	
		this.setState({})
		}
		else {
		window.history.pushState({}, 'Scot', '#/alert/')
		url = '/scot/api/v2/alertgroup'
		stage = false
		SELECTED_ID_GRID = {}
		changestate = false
		passids = {}	
		this.setState({})
		}
	}
	else {
	window.history.pushState({}, 'Scot', '#/alert/')
	this.setState({})
	}
    },
    componentWillReceiveProps: function(){
	this.setState({})
    },
    render: function() {
	const rowFact = (rowProps) => {
	rowProps.onDoubleClick = this.viewAlerts
	}
	
	if(savedsearch){
	this.state.fsearch = savedfsearch
	this.state.viewfilter = true
	}
	return (
	
	    stage ?  React.createElement(Subtable, null) :  
	    React.createElement("div", {className: "allComponents"}, this.state.csv ? React.createElement('button', {className: 'btn btn-warning', onClick: this.exportCSV, style: {'margin-left' : 'auto'}}, 'Export to CSV') : null , this.state.showAlertbutton ? React.createElement('button',{className: 'btn btn-info',onClick: this.viewAlerts, style: {'margin-left':'auto'}},"View Alert(s)") : null, this.state.viewAlert ? React.createElement("div" , {className: "subtable"}, React.createElement(Subtable,null)) : this.state.viewfilter ? React.createElement(Crouton, {message:"You Filtered: ( " + this.state.fsearch + ")", buttons: "close", onDismiss: "onDismiss", type: "info"}) : null,   
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
	    rowHeight: 100,
	    rowFactory:rowFact,
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
	window.history.pushState({}, 'Scot', '#/alert/' + passids.join('+'))
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
	var multiple = false
	var selected = []
	Object.keys(newSelection).forEach(function(id){
	selected.push(newSelection[id].id)
	})
	ids = selected.length? selected.join(' , ') : 'none'
        passids = ids.split(" , ")
	numberofids = selected.length
	if(passids.length > 1){
	multiple = true
	}	
	this.setState({showAlertbutton: multiple, viewAlert: false})
	},
    handleFilter: function(column, value, allFilterValues){
	filter = {}
	var filtersearch = ''
	var search = false
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
	if(Object.keys(filter).length > 0){
	savedsearch = false
	this.setState({viewfilter: false})
	$.each(allFilterValues, function(key,value){
	    if(value != ""){
	    filtersearch = filtersearch + key + ": " + JSON.stringify(value) + " "
	    }
	})
 	setTimeout(function() {savedsearch = true; this.setState({viewfilter:true, fsearch: filtersearch})}.bind(this), 1000)	
	savedfsearch = filtersearch
	}
	else{
	savedsearch = false
	savedfsearch = ''
	this.setState({viewfilter: false})
	}
	
	}

});

module.exports = Maintable

/*

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

*/
