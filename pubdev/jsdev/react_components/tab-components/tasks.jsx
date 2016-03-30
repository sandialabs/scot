'use strict';

var React = require('react')
var DataGrid = require('../../../node_modules/tasks-react-datagrid/react-datagrid');
var Crouton = require('../../../node_modules/react-crouton')
var SelectedContainer = require('../entry/selected_container.jsx')
var Search = require('../components/esearch.jsx')
var SORT_INFO;
var colsort = "id"
var valuesort = 1
var SELECTED_ID = {}
var filter = {}
var names = 'none'
var getColumn;
var check = false; 
var tab;
var datasource
var ids = []
var stage = false
var savedsearch = false
var savedfsearch;
var setfilter = false
var Listener = require('../activemq/listener.jsx')
var columns = 
[
    { name: 'type',width: 159.4,  style: {color: 'black'}},
    { name: 'id',  width: 111.183, style: {color: 'black'}},
    { name: 'status', width:119.533},
    { name: 'owner',  width: 119.533,style: {color: 'black'}},
    { name: 'entry',  style: {color: 'black'}},
    { name: 'updated',  width: 261.45,style: {color: 'black'}}
]

function dataSource(query)
{
    if(setfilter){
    query.skip = 0
    setfilter = false
    }

    var finalarray = [];
	var sortarray = {}
	sortarray[colsort] = valuesort
	return $.ajax({
	type: 'GET',
	url: '/scot/api/v2/task',
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

module.exports = React.createClass({

    getInitialState: function(){
             return {reload: false, viewfilter: false, viewevent: false, showevent: false, data: dataSource, csv:true,fsearch: ''};
         },
    onColumnResize: function(firstCol, firstSize, secondCol, secondSize){
        firstCol.width = firstSize
        this.setState({})
    },
    componentWillMount: function(){
	window.location.hash = '#/task/'
	window.location.href = window.location.hash
    Listener.activeMq('taskgroup', this.reloadactive)
    },
    reloadactive: function(){

    this.setState({reload:true})

    },
    render: function() {
	const rowFact = (rowProps) => {	
	rowProps.onDoubleClick = this.viewEvent
	}
	if(savedsearch){
	this.state.fsearch = savedfsearch
	this.state.viewfilter = true
	}
	var styles;
	if(this.state.viewfilter){
	styles = {'border-radius': '0px'
	}
	}
	else {
	styles = {'border-radius': '0px'}
	}
	$('.z-table').each(function(key,value){
	$(value).find('.z-content').each(function(x,y){
	$(y).css('overflow', 'auto')
	})
	})
	return (
	    stage ? React.createElement(SelectedContainer, {ids: ids, type: 'task', viewEvent:this.viewEvent}) : 
	    this.state.viewevent ? React.createElement(SelectedContainer, {ids: ids, type: 'task', viewEvent:this.viewEvent}) : 
	    React.createElement("div", {className: "allComponents", style: {'margin-left': '17px'}}, React.createElement("div", {className: 'entry-header-info-null', style: {'padding-bottom': '55px',width:'100%'}}, React.createElement("div", {style: {top: '1px', 'margin-left': '10px', float:'left', 'text-align':'center', position: 'absolute'}}, React.createElement('h2', {style: {'font-size': '30px'}}, 'Task')), React.createElement("div", {style: {float: 'right', right: '100px', left: '50px','text-align': 'center', position: 'absolute', top: '9px'}}, React.createElement('h2', {style: {'font-size': '19px'}}, 'OUO')), React.createElement(Search, null)),this.state.viewfilter ? React.createElement(Crouton, {style: {top: '75px', padding: '5px'}, message:"Filtered: ( " + this.state.fsearch + ")", buttons: "close", onDismiss: "Dismiss", type: "info"}) : null, this.state.csv ? React.createElement('btn-group', null, React.createElement('button', {className: 'btn btn-default', onClick: this.exportCSV, style: styles}, 'Export to CSV') , this.state.showevent ? React.createElement('button',{className: 'btn btn-default',onClick: this.viewEvent, style:styles},"View Tasks") : null) : null, React.createElement(DataGrid, {
            ref: "dataGrid", 
            idProperty: "id", 
            dataSource: this.state.data, 
            columns: columns, 
            onColumnResize: this.onColumnResize, 
	    onFilter: this.handleFilter, 
	    selected: SELECTED_ID, 
	    onSelectionChange: this.onSelectionChange, 
	    defaultPageSize:50 ,  
	    pagination: true, 
	    paginationToolbarProps: {pageSizes: [5,10,20,50]}, 
	    onColumnOrderChange: this.handleColumnOrderChange, 
	    sortInfo: SORT_INFO, 
	    onSortChange: this.handleSortChange, 
	    emptyText: 'No records',
        showCellBorders: true,
	    rowHeight: 55,
        reload: this.state.reload,
	    style: {height: '100%'},
	    rowFactory: rowFact,
	    rowStyle: configureTable}
	)
        ));
    },
    viewEvent: function(){

        if (stage == false || this.state.viewevent == false) {
            stage = true;
            this.setState({viewevent: true});
        } else {
            stage = false;
            this.setState({viewevent: false});
        }
	window.location.hash = '#/task/'+ids.join('+')
	window.location.href = window.location.hash
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
	this.setState({reload: false})
	},
    onSelectionChange: function(newSelection){
	SELECTED_ID = newSelection
	var selected = []
	var multiple = false
	Object.keys(newSelection).forEach(function(id){
	selected.push(newSelection[id].id)
	})
	names = selected.length? selected.join(',') : 'none'
	ids = names.split(',')
	if(ids.length > 1){
	multiple = true
	}
	
	this.setState({showevent: multiple, reload:false})
	check = true

	},
    handleFilter: function(column, value, allFilterValues){
	var filtersearch = ''
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
	if(Object.keys(filter).length > 0){
	savedsearch = false
	setfilter = true
    this.setState({viewfilter: false})
	$.each(allFilterValues, function(key,value){
	    if(value != ""){
	    filtersearch = filtersearch + key + ": " + JSON.stringify(value) + " "
	    }
	})
 	setTimeout(function() {savedsearch = true; reload: false, this.setState({viewfilter:true, fsearch: filtersearch})}.bind(this), 1000)	
	savedfsearch = filtersearch
	}
	else{
	savedsearch = false
	savedfsearch = ''
	this.setState({viewfilter: false})
	}
    }

});
	


