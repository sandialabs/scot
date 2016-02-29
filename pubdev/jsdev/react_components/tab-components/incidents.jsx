'use strict';

var React = require('react')
var DataGrid = require('../../../node_modules/incident-react-datagrid/react-datagrid');
var Crouton = require('../../../node_modules/react-crouton')
var SelectedContainer = require('../entry/selected_container.jsx')
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
var columns = 
[
    { name: 'id',style: {color: 'black'}},
    { name: 'doe',  style: {color: 'black'}},
    { name: 'status'},
    { name: 'owner', style: {color: 'black'}},
    { name: 'subject',  style: {color: 'black'}},    
    { name: 'occurred', style: {color: 'black'}},
    { name: 'discovered',  style: {color: 'black'}},
    { name: 'reported',  style: {color: 'black'}},
    { name: 'type',  style: {color: 'black'}},
    { name: 'cat',  style: {color: 'black'}},
    { name: 'sen',  style: {color: 'black'}},
    { name: 'sec',  style: {color: 'black'}},
    { name: 'deadline',  style: {color: 'black'}}
]

function dataSource(query)
{

      	var finalarray = [];
	var sortarray = {}
	sortarray[colsort] = valuesort
	return $.ajax({
	type: 'GET',
	url: '/scot/api/v2/incident',
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
             return {viewfilter: false, viewevent: false, showevent: false, data: dataSource, csv:true,fsearch: ''};
         },
    onColumnResize: function(firstCol, firstSize, secondCol, secondSize){
        firstCol.width = firstSize
        this.setState({})
    },
    componentWillMount: function(){
	//window.history.pushState({}, 'Scot', '#/incident/')
	window.location = '#/incident'
    },

    render: function() {
	const rowFact = (rowProps) => {	
	rowProps.onDoubleClick = this.viewEvent
	}
	if(savedsearch){
	this.state.fsearch = savedfsearch
	this.state.viewfilter = true
	}

	return (
	    stage ? React.createElement(SelectedContainer, {ids: ids, type: 'incident', viewEvent:this.viewEvent}) : 
	    this.state.viewevent ? React.createElement(SelectedContainer, {ids: ids, type: 'incident', viewEvent:this.viewEvent}) : 
	    React.createElement("div", {className: "allComponents"}, this.state.csv ? React.createElement('button', {className: 'btn btn-warning', onClick: this.exportCSV}, 'Export to CSV') : null,this.state.showevent ? React.createElement('button', {className: 'btn btn-info', onClick: this.viewEvent}, "View Incidents") : null, this.state.viewfilter ? React.createElement(Crouton, {message: "You Filtered: (" + this.state.fsearch + ")", buttons: "close", onDismiss: "onDismiss", type: "info"}) :null,
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
	//window.history.pushState({}, 'Scot', '#/incident/' + ids.join('+'))
	window.location = '#/incident/'+ids.join('+')
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
	this.setState({})
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
	
	this.setState({showevent: multiple})
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
	


