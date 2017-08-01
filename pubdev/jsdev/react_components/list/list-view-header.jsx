var React               = require('react');
var DateRangePicker     = require('react-daterange-picker');
var Popover             = require('react-bootstrap/lib/Popover')
var OverlayTrigger      = require('react-bootstrap/lib/OverlayTrigger')
var ButtonGroup         = require('react-bootstrap/lib/ButtonGroup');
var Button              = require('react-bootstrap/lib/Button');
var TagSourceFilter     = require('../components/list-view-filter-tag-source.jsx');
'use strict';

var ListViewHeader = React.createClass({
    getInitialState: function() {
        return {

        }
    },
    render: function() {
        var columns = this.props.columns;
        var columnsDisplay = this.props.columnsDisplay;
        var columnsClassName = this.props.columnsClassName;
        var data = this.props.data;
        var sort = this.props.sort;
        var filter = this.props.filter;
        var handleSort = this.props.handleSort;
        var handleFilter = this.props.handleFilter;
        var arr = [];
        var className = 'wrapper table-row header';
        for (var i=0; i < columns.length; i++) {
            arr.push(<ListViewHeaderEach key={i} columnsOne={columns[i]} columnsDisplayOne={columnsDisplay[i]} columnsClassName={columnsClassName[i]} sort={sort} filter={filter} handleSort={handleSort} handleFilter={handleFilter} type={this.props.type}/>)
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
        var className = this.props.columnsClassName + '-list-header-column';
        return {
            startepoch:'', endepoch:'', className:className,
        }
    },
    handleSort: function() {
        this.props.handleSort(this.props.columnsOne);  
    },
    handleFilter: function(v) {
        if (v.target != undefined) {
            this.props.handleFilter(this.props.columnsOne,v.target.value);
        } else {
            this.props.handleFilter(this.props.columnsOne,v)
        }
    },
    handleEnterKey: function(e) {
        if (e.key == 'Enter') {
            this.handleFilter(e);
        }
    },
    handleFilterDate: function(range, pick){
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
    },
    clearFilter: function(v) {
        var ref = 'popOverRef'+this.props.columnsOne;
        this.props.handleFilter(this.props.columnsOne, '');
        this.setState({startepoch: '', endepoch: ''})
        this.refs[ref].hide(); 
    },
    handleStatusFilter: function(e) {
        if (e.target != undefined) {
            if (e.target.textContent != undefined) {
                this.handleFilter(e.target.textContent.toLowerCase());
            }
        }
    },
    handleStatusFilterClear: function() {
        this.handleFilter('');
    },
    componentDidUpdate: function(prevProps, prevState) {
        var widthValue;
        if ($('#list-view-data-div').find('.'+this.state.className)[0]) {
            widthValue = $('#list-view-data-div').find('.'+this.state.className).width();
            $('.list-view-table-header').find('.'+this.state.className).css('width',widthValue);
        }
    },
    render: function() {
        var columnsOne = this.props.columnsOne;
        var popOverRef = 'popOverRef'+columnsOne
        var columnsDisplayOne = this.props.columnsDisplayOne;
        var dataOne = this.props.dataOne;
        var sortDirection;
        var filterValue;
        var sort = this.props.sort;
        var filter = this.props.filter;
        var handleSort = this.props.handleSort;
        var handleFilter = this.props.handleFilter;
        var showSort = false;
        var epochInputValue = '';
        var statusInputValue = '';
        if (sort != undefined) {
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
        }
        if (filter != undefined) {
            $.each(filter, function(key, value) {
                if (key == columnsOne) {
                    filterValue = value.toString();
                }
            })
        }

        if (columnsOne =='created' || columnsOne == 'updated' || columnsOne == 'occurred') {
            
            if (this.state.startepoch != '' || this.state.endepoch != '') {
                epochInputValue = this.state.startepoch + ',' + this.state.endepoch;
            }
            if (filterValue != undefined) {
                epochInputValue = filterValue;
            }
            return (
                <th className={this.state.className}>
                    <div onClick={this.handleSort}>
                        {columnsDisplayOne}
                        {showSort ? 
                        <span>{sortDirection == 'up' ? <span className='glyphicon glyphicon-triangle-top'/> : null} {sortDirection == 'down' ? <span className='glyphicon glyphicon-triangle-bottom'/> : null}</span> 
                        : 
                        null}
                    </div>
                    <OverlayTrigger trigger='click' placement='bottom' ref={popOverRef} overlay={<Popover id='dateRangePicker'><DateRangePicker numberOfCalendars={2} selectionType={'range'} showLegend={true} onSelect={this.handleFilterDate} singleDateRange={true} /><Button eventKey={'1'} onClick={this.handleFilterDateSubmit} bsSize={'xsmall'} value={columnsOne}>Filter</Button><Button eventKey={'2'} onClick={this.clearFilter} bsSize={'xsmall'} value={columnsOne}>Clear</Button></Popover>}>
                        <input style={{width:'inherit'}} onKeyPress={this.handleEnterKey} value={epochInputValue} />
                    </OverlayTrigger>
                </th>
            )
        } else if(columnsOne == 'tag' || columnsOne == 'source'){
            return( 
                <th className={this.state.className}>
                    <div onClick={this.handleSort}>
                        {columnsDisplayOne}
                        {showSort ?
                        <span>{sortDirection == 'up' ? <span className='glyphicon glyphicon-triangle-top'/> : null} {sortDirection == 'down' ? <span className='glyphicon glyphicon-triangle-bottom'/> : null}</span>
                        :
                        null}
                    </div> 
                    <TagSourceFilter columnsOne={columnsOne} handleFilter={this.handleFilter} defaultValue={filterValue}/>
                </th>
            )
        } else if (columnsOne == 'status'){
            if (filterValue != undefined) {
                statusInputValue = filterValue;
            } else {
                statusInputValue = '';
            }
            return (
                <th className={this.state.className}>
                    <div onClick={this.handleSort}>
                        {columnsDisplayOne}
                        {showSort ?
                        <span>{sortDirection == 'up' ? <span className='glyphicon glyphicon-triangle-top'/> : null} {sortDirection == 'down' ? <span className='glyphicon glyphicon-triangle-bottom'/> : null}</span>
                        :
                        null}
                    </div>
                    {this.props.type == 'signature' ?
                    <span style={{width:'inherit'}}>
                        <OverlayTrigger trigger='focus' placement='bottom' overlay={<Popover id='statuspicker'><ButtonGroup vertical><Button onClick={this.handleStatusFilter}>Enabled</Button><Button onClick={this.handleStatusFilter}>Disabled</Button><Button onClick={this.handleStatusFilterClear}>Clear</Button></ButtonGroup></Popover>}>
                            <input style={{width:'inherit'}} onKeyPress={this.handleEnterKey} value={statusInputValue}/>
                        </OverlayTrigger>
                    </span>
                    :
                    <span style={{width:'inherit'}}>
                        <OverlayTrigger trigger='focus' placement='bottom' overlay={<Popover id='statuspicker'><ButtonGroup vertical><Button onClick={this.handleStatusFilter}>Open</Button><Button onClick={this.handleStatusFilter}>Closed</Button><Button onClick={this.handleStatusFilter}>Promoted</Button><Button onClick={this.handleStatusFilterClear}>Clear</Button></ButtonGroup></Popover>}>
                            <input style={{width:'inherit'}} onKeyPress={this.handleEnterKey} value={statusInputValue}/>
                        </OverlayTrigger>
                    </span>
                    }
                </th>
            )
        } else {
            return (
                <th className={this.state.className}>
                    <div onClick={this.handleSort}>
                        {columnsDisplayOne}
                        {showSort ? 
                        <span>{sortDirection == 'up' ? <span className='glyphicon glyphicon-triangle-top'/> : null} {sortDirection == 'down' ? <span className='glyphicon glyphicon-triangle-bottom'/> : null}</span> 
                        : 
                        null}
                    </div>
                    <input style={{width:'inherit'}} onKeyPress={this.handleEnterKey} defaultValue={filterValue}/>
                </th>
            )
        }
    }
});



module.exports = ListViewHeader;
