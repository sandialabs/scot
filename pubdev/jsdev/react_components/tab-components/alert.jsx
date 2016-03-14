'use strict';

var React = require('react')
var HistoryView = require('../modal/history.jsx')
var Search = require('../components/esearch.jsx')
var DataGrid = require('../../../node_modules/alert-react-datagrid/react-datagrid');
var SORT_INFO;
var colsort = "id"
var valuesort = -1
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
var Frame = require('../../../node_modules/react-frame')
var finalfiles = []
var checkfiles = false
var Alertentry = require('../entry/selected_entry.jsx').SelectedEntry
var Header = require('../entry/selected_header.jsx')
var Addentry = require('../modal/add_entry.jsx')
var Appactions = require('../flux/actions.jsx')
var Store = require('../flux/store.jsx')
var supervalue = [];
var ventry = false
var supername;
var columns = 
[
    { name: 'id' , width: 111.183, style: {color: 'black'}},
    { name: 'status', width: 119.533},
    { name: 'created', style: {color: 'black'}, width:261.45},
    { name: 'sources', style: {color: 'black'}, width:198.467},
    { name: 'subject', style: {color: 'black'}},
    { name: 'tags', style: {color: 'black'}, width:189.95},
    { name: 'views', style: {color: 'black'}, width: 104.4}
]

const  customStyles = {
        content : {
        top     : '3%',
        right   : '60%',
        bottom  : 'auto',
        left: '10%',
	width: '80%',
	'z-index' : '99'
//	height: '80%'
    }
}
function getColumns()
{
    return $.ajax({
	type: 'GET',
	url: url,
	data: {
	alertgroup: JSON.stringify(supervalue)
	}
	}).success(function(data){
		datacolumns = data
	});
}
	var Viewentry = React.createClass({
	getInitialState: function() {
	return{open: ventry}
	},
	componentWillMount: function(){
	this.clickable1()
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
	alertgroup: JSON.stringify(supervalue)
	}
	}).then(function(response){
  	datasource = response
	$.each(datasource.records, function(key, value){
	finalarray[key] = {}
	
	$.each(value, function(num, item){	
	if(num == 'id'){
	addentrydata = true
	$.ajax({
	   type: 'GET',
	   url: '/scot/api/v2/alert/' + item + '/entry'
	   }).success(function(response){
	   if(response.totalRecordCount != 0){
	var View = React.createClass({
		getInitialState: function(){
		return {view:false, refe: 0}
		  },
		 render: function(){
		 return( 
	this.state.view ? React.createElement('div', {className: 'ViewEntry'} , React.createElement(Viewentry, {id: this.state.refe}), React.createElement('button', {className: 'btn btn-default', onClick:this.view}, 'Re-Open Entry')) :
			React.createElement('button', {className: 'btn btn-default', onClick: this.view}, 'View Entry')
			)
		},
		view: function(){
		ventry = false;		
		this.setState({view:true, refe: item})
		}
		});	
		finalarray[key]["Entry"] = React.createElement(View, {change: true})
		}
		})
		finalarray[key][num] = item
	}
	else if(num == 'when')
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
	return {
	data:  finalarray,	
	count: response.totalRecordCount,
	columns: response.columns
	}
	})
    }
    else {
	$('.z-vertical-scrollbar').css('top', 0)
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
	$.each(response.records, function(key, value){
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
	if(this.props.id !== undefined)
	{
	    supervalue = []
	    supervalue.push(this.props.id)
	    supername = this.props.id
	}
	else {
	supername = supervalue[0]
	}
        return {

flair: false, key: supername, viewby: [],historyid: 0, history: false, edit: false, stagecolor : 'black',enable:true, enablesave: false, modaloptions: [{value:"Please Save Entry First", label:"Please Save Entry First"}],addentry: false, reload: false, data: dataSource, back: false, columns: [],oneview: false,options:[ {value: 'Flair Off', label: 'Flair Off'}, {value: 'View Guide', label: 'View Guide'}, {value: 'View Source', label: 'View Source'}, {value:'View History', label: 'View History'}, {value: 'Add Entry', label: 'Add Entry'}, {value: 'Open Selected', label: 'Open Selected'}, {value:'Closed Selected', label: 'Closed Selected'}, {value:'Promote Selected', label:'Promote Selected'}, {value: 'Add Selected to existing event', label: 'Add Selected to existing event'}, {value: 'Export to CSV', label: 'Export to CSV'}, {value: 'Delete Selected', label: 'Delete Selected'}]}
    },
   componentWillMount: function(){
	SELECTED_ID_GRID = {}
	var project = getColumns()
	project.success(function(realData){
	var last = realData.columns
	if(this.isMounted()){
	var newarray = []
	if(true){
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
	setTimeout(function() { this.setState({columns: newarray})}.bind(this), 800)
	}
	}.bind(this));
	Store.storeKey(this.state.key)
	Store.addChangeListener(this.reloadentry)
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
	Close: function(i) {
	for(var x = 0; x< finalfiles.length; x++){
	 if(i.target.id == finalfiles[x].name){
	     finalfiles.splice(x,1)
	  }
	  }
	  this.setState({files:finalfiles})
	},
	render: function(){
	$('.mac-fix').css('position', 'relative')	
	$('.z-table').each(function(key,value){
	$(value).find('.z-cell').each(function(x,y){
	$(y).css({'height' : '120px', 'overflow':'auto'})
	})
	})
	setTimeout(function() {
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
	}, 100)
	return (
	this.state.history ? React.createElement(HistoryView, {type:'alertgroup', id: this.state.historyid, historyToggle: this.viewHistory}) 
        :
	React.createElement("div", {className: 'All Modal'}, /*style: {'padding-left': '25px'}},*/ this.state.addentry ? React.createElement(Addentry, {title: 'Add Entry', updated: this.reloadentry, addedentry: this.addEntry, type: 'alert'}) : null,
	this.state.reload ? React.createElement(Subtable, {className: "MainSubtable"},null) :  
	this.state.back ? React.createElement(Maintable, null) : React.createElement("div" , {className: "subtable" + this.state.key}, React.createElement('div', null, React.createElement(Header, {type: 'alertgroup', id: this.state.key})), this.state.oneview ? React.createElement('btn-group', null, this.state.flair ? React.createElement('button',{className: 'btn btn-default', onClick: this.flairOn}, 'Flair On') : React.createElement('button', {className: 'btn btn-default', onClick: this.flairOff}, 'Flair Off'), React.createElement('button', {className: 'btn btn-default', onClick: this.viewGuide}, 'View Guide'), React.createElement('button', {className:'btn btn-default', onClick:this.viewSource}, 'View Source'), React.createElement('button', {className:'btn btn-default', onClick: this.viewHistory}, 'View History'), React.createElement('button', {className: 'btn btn-default', onClick:this.addEntry}, 'Add Entry'), React.createElement('button', {className: 'btn btn-default', onClick: this.openSelected}, 'Open Selected'), React.createElement('button', {className: 'btn btn-default', onClick: this.closeSelected}, 'Close Selected'), React.createElement('button', {className: 'btn btn-default', onClick: this.promoteSelected}, 'Promote Selected'), React.createElement('button', {className:'btn btn-default', onClick:this.selectExisting}, 'Add Selected to Existing Event'), React.createElement('button', {className:'btn btn-default', onClick:this.exportCSV}, 'Export to CSV'), React.createElement('button', {className:'btn btn-default', onClick:this.deleteSelected}, 'Delete Selected')) : null ,  React.createElement(Subgrid, {style: {height: '100%', 'z-index' : '0'},className: "Subgrid",
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
	    rowHeight: 120,
	    rowStyle: configureTable}
	)
        )
	));
   },
   flairOn: function(){
	$('.subtable'+this.state.key).find('.z-selected').each(function(key, value){
	    $(value).find('.z-cell').each(function(num,content){
		var con = $(content).find('.entity-off')
		con.each(function(x,y){
		    $(y).addClass('entity');
		    $(y).removeClass('entity-off')
	});
	});
	});
	this.setState({flair:false})
    },
   flairOff: function(){
	$('.subtable'+this.state.key).find('.z-selected').each(function(key, value){
	    $(value).find('.z-cell').each(function(num,content){
		var con = $(content).find('.entity')
		con.each(function(x,y){
		    $(y).addClass('entity-off');
		    $(y).removeClass('entity')
	});
	});
	});
	this.setState({flair: true})
    },
    viewGuide: function(){
	    if(storealertids.length > 1){
		alert("Select only one id to view guide")
	    }
	    else {
	$('.subtable'+this.state.key).find('.z-selected').each(function(key, value){
	    $(value).find('.z-cell').each(function(x,y){
		if($(y).attr('name') == 'id'){
	    	window.open('/guide.html#' + $(y).text());
		}
		})
		})
	    }
    },
    viewSource: function(){
	var win = window.open('viewSource.html', '_blank')
	var html = $('.subtable'+this.state.key).find('.z-selected').html()	
	var plain = $('.subtable'+this.state.key).find('.z-selected').text()
	win.onload = function() {   if(html != undefined){
	$(win.document).find('#html').text(html)
	} else {$(win.document).find('.html').remove() }
	if(plain != undefined) {
	$(win.document).find('#plain').text(plain)
	} else { $(win.document).find('.plain').remove() }
	}

    },
    viewHistory: function(){
	historyview = ''
        var id = 0;
	if(storealertids.length > 1){
	    alert("Select only one id to view history")
	}
	else {  
	$('.subtable'+this.state.key).find('.z-selected').each(function(key, value){
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
   },
   addEntry: function(){
	if(!this.state.addentry) {
	this.setState({addentry: true})
	}
	else {
	this.setState({addentry: false})
	}

    },
    reloadentry: function(){
	SELECTED_ID_GRID = {}
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
	alertgroup: JSON.stringify(supervalue)
	}
	}).then(function(response){
  	datasource = response
	$.each(datasource.records, function(key, value){
	finalarray[key] = {}	
	$.each(value, function(num, item){	
	if(num == 'id'){
	addentrydata = true
	$.ajax({
	   type: 'GET',
	   url: '/scot/api/v2/alert/' + item + '/entry'
	   }).success(function(response){
	   if(response.totalRecordCount != 0){
	var View = React.createClass({
		getInitialState: function(){
		return {view:false, refe: 0}
		  },
		 render: function(){
		 return( 
	this.state.view ? React.createElement('div', {className: 'ViewEntry'} , React.createElement(Viewentry, {id: this.state.refe}), React.createElement('button', {className: 'btn btn-default', onClick:this.view}, 'Re-Open Entry')) :
			React.createElement('button', {className: 'btn btn-default', onClick: this.view}, 'View Entry')
			)
		},
		view: function(){
		ventry = false;		
		this.setState({view:true, refe: item})
		}
		});	
		finalarray[key]["Entry"] = React.createElement(View, {change: true})
		}
		})
		finalarray[key][num] = item
	}
	else if(num == 'when')
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
	this.setState({oneview: false, data:finalarray})
	}.bind(this))
  	}

    },
    openSelected: function(){
	var data = new Object();
	var state = this.state.key
	Appactions.updateItem(state, 'alertstatusmessage', 'open')
    },

    closeSelected: function(){
	var state = this.state.key
	Appactions.updateItem(state, 'alertstatusmessage', 'closed')
   },
   promoteSelected: function(){
	var state = this.state.key
	Appactions.updateItem(state, 'alertstatusmessage', 'promoted')
   },

   selectExisting: function(){
	var text = prompt("Please Enter Event ID to promote into")
	$('.subtable'+this.state.key).find('.z-selected').each(function(key, value){
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
   },
   exportCSV: function(){
	    var keys = []
	    $.each(this.state.columns, function(key, value){
		keys.push(value['name']);
	    });
	    var csv = ''
	    	$('.subtable'+this.state.key).find('.z-selected').each(function(key, value){
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
	setTimeout(
	function() {
	this.reloadentry()
	}.bind(this), 1000)
	this.setState({})
	    window.open(data_uri)
    },
    deleteSelected: function(){
	if(confirm("Are you sure you want to Delete? This action can not be undone.")){
	var state = this.state.key
	Appactions.updateItem(state, 'alertstatusmessage', 'delete')
	}

   },
    onDrop: function(files){
	   for(var i = 0; i<files.length; i++){
		finalfiles.push(files[i])
	   }	
        this.setState({files: finalfiles})
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
	supervalue = []	
	supervalue.push(this.state.key)
	SELECTED_ID_GRID = newSelection
	var selected = []
	Object.keys(newSelection).forEach(function(id){
	selected.push(newSelection[id].index)
	})
	var ids = selected.length? selected.join(',') : 'none'
	storealertids = ids.split(',')		
	this.setState({oneview:true,setcss: false, key:supervalue[0] })
	},
    closeHistory: function(){
	this.setState({history: false})	
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
		window.location.hash = '#/alertgroup/' + this.props.supertable.join('+')
		window.location.href = window.location.hash 
		passids = this.props.supertable
		ids = this.props.supertable.join(',')
		stage = true
		changestate = true
		url = '/scot/api/v2/supertable'	
		this.setState({})
		}
		else {
		window.location.hash = '#/alertgroup/'
		window.location.location = window.location.hash
		url = '/scot/api/v2/alertgroup'
		stage = false
		SELECTED_ID_GRID = {}
		changestate = false
		passids = {}	
		this.setState({})
		}
	}
	else {
	window.location.hash = '#/alertgroup/'
	window.location.href = window.location.hash
	this.setState({})
	}
    },
    componentWillReceiveProps: function(){
	this.setState({})
    },
    render: function() {
	$('.active').on('click', function(){
	window.location.hash = '#/alertgroup/'
	window.location.href = window.location.hash
	})
	const rowFact = (rowProps) => {
	rowProps.onDoubleClick = this.viewAlerts
	}
	
	if(savedsearch){
	this.state.fsearch = savedfsearch
	this.state.viewfilter = true
	}
	$('#close').css('text-shadow', '#0B0B0B 0px 1px 0px')
	$('#searchid').keyup(function(){
         var page = $('.allComponents');
         var pageText = page.text().replace("<span>","").replace("</span>");
         var searchedText = $('#searchid').val();
         var theRegEx = new RegExp("("+searchedText+")", "igm");    
         var newHtml = pageText.replace(theRegEx ,"<span>$1</span>");
 	
    	});
	var styles;
	if(this.state.viewfilter){
	styles = {
	'border-radius': '0px'
	}
	}
	else{
	styles = {'border-radius': '0px'}
	}
 	$('.z-table').find('.z-row').each(function(key, value){
	$(value).find('.z-cell').each(function(x,y){
	$(y).css('overflow', 'auto')
	})
	})	
	return (
	
	    stage ?  React.createElement('div', null, passids.map((num) => React.createElement(Subtable, {id: num}))) :  

	    React.createElement("div", {className: "allComponents", style: {'margin-left': '17px'}}, React.createElement("div", {className: 'entry-header-info-null', style: {'padding-bottom': '55px',width:'100%'}}, React.createElement("div", {style: {top: '1px', 'margin-left': '10px', float:'left', 'text-align':'center', position: 'absolute'}}, React.createElement('h2', {style: {'font-size': '30px'}}, 'Alerts')), React.createElement("div", {style: {float: 'right', right: '100px', left: '50px','text-align': 'center', position: 'absolute', top: '9px'}}, React.createElement('h2', {style: {'font-size': '19px'}}, 'OUO')), React.createElement(Search, null)),this.state.viewfilter ? React.createElement(Crouton, {color: '#119FE1',style: {top: '75px', padding: '5px'}, message:"Filtered: ( " + this.state.fsearch + ")", onDismiss: 'onDismiss', type: "info"}) : null, this.state.csv ? React.createElement('btn-group', null, React.createElement('button', {className: 'btn btn-default', onClick: this.exportCSV, style: styles}, 'Export to CSV') , this.state.showAlertbutton ? React.createElement('button',{className: 'btn btn-default',onClick: this.viewAlerts, style:styles},"View Alerts") : null) : null, this.state.viewAlert ? React.createElement("div" , {className: "subtable"}, React.createElement(Subtable,null)) : React.createElement(DataGrid, {
            ref: "dataGrid", 
            idProperty: "id",
            dataSource: this.state.data, 
            columns: columns, 
            onColumnResize: this.onColumnResize, 
	    onFilter: this.handleFilter, 
	    selected: SELECTED_ID, 
	    onSelectionChange: this.onSelectionChange, 
	    defaultPageSize: 50,  
	    pagination: true, 
	    paginationToolbarProps: {pageSizes: [5,10,20,50]}, 
	    onColumnOrderChange: this.handleColumnOrderChange, 
	    sortInfo: SORT_INFO, 
	    onSortChange: this.handleSortChange,
	    showCellBorders: true,
	    rowHeight: 55,
	    style: {height: '100%'},
	    rowFactory:rowFact,
	    rowStyle: configureTable}
	)
        ));
    },
    onDismiss: function(){
    this.setState({viewfilter: false})
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
	window.location.hash = '#/alertgroup/'+passids.join('+')
	window.location.href = window.location.hash
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

