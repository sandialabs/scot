var React               = require('react');
var DateRangePicker     = require('react-daterange-picker');
var Popover             = require('react-bootstrap/lib/Popover')
var OverlayTrigger      = require('react-bootstrap/lib/OverlayTrigger')
var Button              = require('react-bootstrap/lib/Button');
'use strict';

var ListViewHeader = React.createClass({
    getInitialState: function() {
        return {

        }
    },
    render: function() {
        var columns = this.props.columns;
        var columnsDisplay = this.props.columnsDisplay;
        var data = this.props.data;
        var sort = this.props.sort;
        var handleSort = this.props.handleSort;
        var handleFilter = this.props.handleFilter;
        var arr = [];
        var className = 'wrapper table-row header';
        for (i=0; i < columns.length; i++) {
            arr.push(<ListViewHeaderEach columnsOne={columns[i]} columnsDisplayOne={columnsDisplay[i]} sort={sort} handleSort={handleSort} handleFilter={handleFilter} />)
        }
        return (
            <tbody className='list-view-table-header'>
                <tr>
                    {arr}     
                </tr>
            </tbody>
        )
    }
});

var ListViewHeaderEach = React.createClass({
    getInitialState: function() {
        return {
            startepoch:'',endepoch:'',
        }
    },
    handleSort: function() {
        this.props.handleSort(this.props.columnsOne);  
    },
    handleFilter: function(v) {
        this.props.handleFilter(this.props.columnsOne,v.target.value);
    },
    handleEnterKey: function(e) {
        if (e.key == 'Enter') {
            this.handleFilter(e);
        }
    },
    handleFilterDate: function(range, pick){
        /*var start = range['start']
        var month = start['_i'].getMonth()+1
        var day   = start['_i'].getDate()
        var StartDate = month+"/"+day+"/"+start['_i'].getFullYear()
        var end = range['end']
        var month = end['_i'].getMonth()+1
        var day   = end['_i'].getDate()
        var EndDate = month+"/"+day+"/"+end['_i'].getFullYear()

        start = StartDate.split('/')
        start = new Date(start[2], start[0] - 1, start[1])
        end   = EndDate.split('/')
        end   = new Date(end[2],end[0]-1, end[1], 23,59,59,99);

        start = Math.round(start.getTime()/1000)
        end   = Math.round(end.getTime()/1000)
        this.setState({startepoch: StartDate, endepoch: EndDate})*/
        this.setState({startepoch: Math.round(range['start'])/1000, endepoch: Math.round(range['end'])/1000})
    },
    handleFilterDateSubmit: function(v) {
        var ref = 'popOverRef'+this.props.columnsOne;
        if (this.state.startepoch != '' && this.state.endepoch != '') { //check if blank, and if so send the request but as a blank string so it is stripped out
            this.props.handleFilter(this.props.columnsOne, this.state.startepoch + ',' + this.state.endepoch);
        } else {
            this.props.handleFilter(this.props.columnsOne, '');
        }
        this.refs[ref].hide();
        //if($($(v.currentTarget).find('.filter').context).attr('value') == this.props.columnsOne {
            
        //}
    },
    clearFilter: function(v) {
        var ref = 'popOverRef'+this.props.columnsOne;
        this.props.handleFilter(this.props.columnsOne, '');
        this.setState({startepoch: '', endepoch: ''})
        this.refs[ref].hide(); 
    },
    render: function() {
        var columnsOne = this.props.columnsOne;
        var popOverRef = 'popOverRef'+columnsOne
        var columnsDisplayOne = this.props.columnsDisplayOne;
        var dataOne = this.props.dataOne;
        var sortDirection;
        var sort = this.props.sort;
        var handleSort = this.props.handleSort;
        var handleFilter = this.props.handleFilter;
        var className = columnsOne + '-list-header-column'
        var showSort = false;
        var epochInputValue = '';
        $.each(sort, function(key, value) {
            if (key == columnsOne) {
                showSort = true;
                if (value == -1) {
                    sortDirection = 'down'
                } else {
                    sortDirection = 'up'
                }
            }
        })
        if (columnsOne =='created' || columnsOne == 'updated' || columnsOne == 'occurred') {
            
            if (this.state.startepoch != '' || this.state.endepoch != '') {
                epochInputValue = this.state.startepoch + ',' + this.state.endepoch;
            }
            return (
                <th className={className}>
                    <div onClick={this.handleSort}>
                        {columnsDisplayOne}
                        {showSort ? 
                        <span>{sortDirection == 'up' ? <span className='glyphicon glyphicon-triangle-top'/> : null} {sortDirection == 'down' ? <span className='glyphicon glyphicon-triangle-bottom'/> : null}</span> 
                        : 
                        null}
                    </div>
                    <OverlayTrigger trigger='click' placement='bottom' ref={popOverRef} overlay={<Popover id='dateRangePicker'><DateRangePicker numberOfCalendars={2} selectionType={'range'} showLegend={true} onSelect={this.handleFilterDate} singleDateRange={true} /><Button eventKey={'1'} onClick={this.handleFilterDateSubmit} bsSize={'xsmall'} value={columnsOne}>Filter</Button><Button eventKey={'2'} onClick={this.clearFilter} bsSize={'xsmall'} value={columnsOne}>Clear</Button></Popover>}>
                        <input style={{width:'inherit'}} onKeyPress={this.handleEnterKey} value={epochInputValue}/>
                    </OverlayTrigger>
                </th>
            )
        } else {
            return (
                <th className={className}>
                    <div onClick={this.handleSort}>
                        {columnsDisplayOne}
                        {showSort ? 
                        <span>{sortDirection == 'up' ? <span className='glyphicon glyphicon-triangle-top'/> : null} {sortDirection == 'down' ? <span className='glyphicon glyphicon-triangle-bottom'/> : null}</span> 
                        : 
                        null}
                    </div>
                    <input style={{width:'inherit'}} onKeyPress={this.handleEnterKey}/>
                </th>
            )
        }
    }
});



module.exports = ListViewHeader;
