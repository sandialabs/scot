'use strict';

var React = require('react')
var DataGrid = require('../../../node_modules/incident-react-datagrid/react-datagrid');
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
             return {data: dataSource};
         },
    onColumnResize: function(firstCol, firstSize, secondCol, secondSize){
        firstCol.width = firstSize
        this.setState({})
    },

    render: function() {

	return (
	    React.createElement("div", {className: "allComponents"}, 
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
	selected.push(newSelection[id].firstName)
	})
	names = selected.length? selected.join(', ') : 'none'
	this.setState({})
	check = true

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
	




































