'use strict';

var React                   = require('react')
var SelectedContainer       = require('../entry/selected_container.jsx')
var Notificationactivemq    = require('../../../node_modules/react-notification-system')
var Search                  = require('../components/esearch.jsx')
var Store                   = require('../activemq/store.jsx')
var Page                    = require('../components/paging.jsx')
var Popover                 = require('react-bootstrap/lib/Popover')
var OverlayTrigger          = require('react-bootstrap/lib/OverlayTrigger')
var ButtonToolbar           = require('react-bootstrap/lib/ButtonToolbar')
var DateRangePicker         = require('../../../node_modules/react-daterange-picker')
var Source                  = require('react-tag-input-tags/react-tag-input').WithContext
var Tags                    = require('react-tag-input').WithContext
var SORT_INFO;
var colsort = "id"
var defaultpage = 1
var start;
var end;
var valuesort = -1
var SELECTED_ID = {}
var filter = {}
var sortarray = {}
var names = 'none'
var getColumn;
var tab;
var datasource
var ids = []
var stage = false
var savedsearch = false
var savedfsearch;
var setfilter = false
var savedid;
var height;
var width;
var pageSize = 50;
var readonly = []
var colorrow = [];
sortarray[colsort] = -1
var columns = ['Type', 'ID', 'Status', 'Owner', 'Entry', 'Updated']






module.exports = React.createClass({

    getInitialState: function(){
        var scrollHeight = $(window).height() - 170
        var scrollWidth  = '650px'
        width = 650

    return {
            upstartepoch: '', upendepoch: '',white: 'white', blue: '#AEDAFF',
            idtext: '', totalcount: 0, activepage: 0,
            entry: 0, type: '', statustext: '', idsarray: [],
            ownertext: '', typetext: '', entriestext: '', scrollheight: scrollHeight,
            scrollwidth: scrollWidth, reload: false,
            objectarray:[], csv:true};
    },
    componentWillMount: function(){
        var array = []
        if(this.props.ids !== undefined){
            if(this.props.ids.length > 0){
                array = this.props.ids
                stage = true
                }
          }
        var finalarray = [];
        var sortarray = {}
        sortarray[colsort] = -1
        Store.storeKey('taskgroup')
        Store.addChangeListener(this.reloadactive)
        $.ajax({
            type: 'GET',
            url: '/scot/api/v2/task',
            data: {
                limit: 50,
                offset: 0,
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
        this.setState({idsarray: array, objectarray: finalarray,totalcount: response.totalRecordCount})
        }.bind(this))
    },

    reloadactive: function(){
        var notification = this.refs.notificationSystem
        if(activemqwho != whoami && notification != undefined && activemqwho != "" &&  activemqwho != 'api'){
            notification.addNotification({
                message: activemqwho + activemqmessage + activemqid,
                level: 'info',
                autoDismiss: 15,
                action:  activemqstate != 'delete' ? {
                    label: 'View',
                    callback: function(){
                        if(activemqtype == 'entry'|| activemqtype == 'alert'){
                            activemqid = activemqsetentry
                            activemqtype = activemqsetentrytype
                        }
                        window.open('#/' + activemqtype + '/' + activemqid)
                    }
                }  : null
            })
            savedid = activemqid
        }
        this.getNewData({page:defaultpage , limit: pageSize})
    },
    reloadItem: function(){
        height = $(window).height() - 170
        width = width + 40
        $('.container-fluid').css('height', height)
        $('.container-fluid').css('max-height', height)
        $('.container-fluid').css('max-width', '915px')
        $('.container-fluid').css('width', width)
    },

    launchEvent: function(array,entryid,tasktype){
        stage = true
        this.setState({idsarray:array, type: tasktype, entry: entryid})

    },
    render: function(){
        var styles;
        setTimeout(function(){
            $('.allevents').find('.table-row').each(function(key, value){
                $(value).find('.colorstatus').each(function(x,y){
                    if($(y).text() == 'open'){
                        $(y).css('color', 'red')
                    }
                    else if($(y).text() == 'completed' || $(y).text() == 'closed'){
                        $(y).css('color', 'green')
                    }
        else if($(y).text()  == 'promoted' || $(y).text() == 'assigned'){
            $(y).css('color', 'orange')
        }
        })
        })

        }.bind(this),100)
        window.addEventListener('resize',this.reloadItem);
        return (
            React.createElement("div", {className: "allComponents", style: {'margin-left': '17px'}},
                React.createElement('div', null,
                    React.createElement(Notificationactivemq, {ref: 'notificationSystem'})),
                        React.createElement("div", {className: 'entry-header-info-null', style: {'padding-bottom': '55px',width:'100%'}},
                        React.createElement("div", {style: {top: '1px', 'margin-left': '10px', float:'left', 'text-align':'center', position: 'absolute'}},
                        React.createElement('h2', {style: {'font-size': '30px'}}, 'Task')),
                        React.createElement("div", {style: {float: 'right', right: '100px', left: '50px','text-align': 'center', position: 'absolute', top: '9px'}},
                        React.createElement('h2', {style: {'font-size': '19px'}}, 'OUO')),
                        React.createElement(Search, null)), React.createElement('btn-group', {style: {'padding-left': '0px'}},
                        React.createElement('button', {className: 'btn btn-default', onClick: this.clearAll, style: styles}, 'Clear All Filters'),
                        React.createElement('button', {className: 'btn btn-default', onClick: this.exportCSV, style: styles}, 'Export to CSV')),
            React.createElement('div', {className: 'incidentwidth', style: {display:'flex'}},
            React.createElement('div', {id:'list-view'},
            React.createElement('div', {style:{display: 'flex'}},
                React.createElement("div", {className: "container-fluid", style: {'max-width': '915px',resize:'horizontal','min-width': '650px', width:this.state.scrollwidth, 'max-height': this.state.scrollheight, 'margin-left': '0px',height: this.state.scrollheight, overflow: 'auto', 'padding-left':'5px'}},
                    React.createElement("div", {className: "table-row header"},
                        React.createElement("div", {className: "wrapper attributes"},
                        React.createElement('div', {className: 'wrapper status-owner-severity'},
                        React.createElement('div', {className: 'wrapper status-owner'},
                        React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, React.createElement(OverlayTrigger, {trigger:['click','focus'], placement:'bottom', ref: 'myPopOvertype', rootClose: true, overlay: React.createElement(Popover, null,
                        React.createElement('div', {className: 'Filter and Sort', id: 'typeheader'}, React.createElement('div',
                        {style: {display: 'inline-flex'}}, React.createElement('div', null, 'Type'), React.createElement('div',
                        {style:{'padding-left': '100px'}}, 'Sort'),
                        React.createElement('btn-group', null,
                        React.createElement('button', {style: {height:'5px'}, onClick: this.handlesort, value: 'type', id: 1, className: 'sort glyphicon glyphicon-triangle-top'}),
                        React.createElement('button', {onClick: this.handlesort, value: 'type', id: -1, className: 'sort glyphicon glyphicon-triangle-bottom', style:{height:'5px'}}))),
                        React.createElement('input', {autoFocus: true,id: 'type', onKeyUp: this.filterUp, defaultValue: this.state.typetext, placeholder: 'Search', style: {background: 'white', width: '200px'}, type:'text', className:'typeinput'}),
                        React.createElement('btn-group', null,
                        React.createElement('button', {className:'btn btn-default clear',  value: 'type', onClick: this.filterclear}, 'Clear'),
                        React.createElement('button', {className:'btn btn-default filter', value: 'type', onClick: this.handlefilter}, 'Filter')))
                        )},
                        React.createElement("div", {className: "column owner"}, "Type"))),
                        React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, React.createElement(OverlayTrigger, {ref: 'myPopOverid', trigger:['click','focus'], placement:'bottom', rootClose: true, overlay: React.createElement(Popover, null,
                        React.createElement('div', {className: 'Filter and Sort', id: 'idheader'}, React.createElement('div',
                        {style: {display: 'inline-flex'}}, React.createElement('div', null, 'ID'), React.createElement('div',
                        {style:{'padding-left': '100px'}}, 'Sort'),
                        React.createElement('btn-group', null,
                        React.createElement('button', {style: {height:'5px'},value: 'id', id: 1, onClick: this.handlesort, className: 'sort glyphicon glyphicon-triangle-top'}),
                        React.createElement('button', {className: 'sort glyphicon glyphicon-triangle-bottom', value: 'id', onClick: this.handlesort, id: -1, style:{height:'5px'}}))),
                        React.createElement('input',  {autoFocus: true, id:'id',onKeyUp: this.filterUp, defaultValue: this.state.idtext, placeholder: 'Search', style: {background: 'white', width: '200px'}, type:'text', className:'idinput'}),
                        React.createElement('btn-group', null,
                        React.createElement('button', {className:'btn btn-default clear', value: 'id', onClick: this.filterclear}, 'Clear'),
                        React.createElement('button', {value: 'id',className:'filter btn btn-default', onClick: this.handlefilter}, 'Filter')))
                        )},
                        React.createElement('div',{className: 'column index'}, 'ID')))
                        )),

                        React.createElement('div', {className: 'wrapper status-owner-severity'},
                        React.createElement('div', {className: 'wrapper status-owner'},
                        React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, React.createElement(OverlayTrigger, {trigger:['click','focus'], placement:'bottom', ref: 'myPopOverstatus', rootClose: true, overlay: React.createElement(Popover, null,
                        React.createElement('div', {className: 'Filter and Sort', id: 'statusheader'}, React.createElement('div',
                        {style: {display: 'inline-flex'}}, React.createElement('div', null, 'Status'), React.createElement('div',
                        {style:{'padding-left': '100px'}}, 'Sort'),
                        React.createElement('btn-group', null,
                        React.createElement('button', {style: {height:'5px'}, onClick: this.handlesort, value: 'status', id: 1, className: 'sort glyphicon glyphicon-triangle-top'}),
                        React.createElement('button', {onClick: this.handlesort, value: 'status', id: -1, className: 'sort glyphicon glyphicon-triangle-bottom', style:{height:'5px'}}))),
                        React.createElement('input', {autoFocus: true,id: 'status', onKeyUp: this.filterUp, defaultValue: this.state.statustext, placeholder: 'Search', style: {background: 'white', width: '200px'}, type:'text', className:'statusinput'}),
                        React.createElement('btn-group', null,
                        React.createElement('button', {className:'btn btn-default clear',  value: 'status', onClick: this.filterclear}, 'Clear'),
                        React.createElement('button', {className:'btn btn-default filter', value: 'status', onClick: this.handlefilter}, 'Filter')))
                        )},
                         React.createElement("div", {className: "column owner"}, "Status")))
                         )),
                         React.createElement('div', {className: 'wrapper status-owner-severity'},
                         React.createElement('div', {className: 'wrapper status-owner'},
                         React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, React.createElement(OverlayTrigger, {trigger:['click','focus'], placement:'bottom', ref: 'myPopOverowner', rootClose: true, overlay: React.createElement(Popover, null,
                        React.createElement('div', {className: 'Filter and Sort', id: 'ownerheader'}, React.createElement('div',
                        {style: {display: 'inline-flex'}}, React.createElement('div', null, 'Owner'), React.createElement('div',
                        {style:{'padding-left': '100px'}}, 'Sort'),
                        React.createElement('btn-group', null,
                        React.createElement('button', {style: {height:'5px'}, onClick: this.handlesort, value: 'owner', id: 1, className: 'sort glyphicon glyphicon-triangle-top'}),
                        React.createElement('button', {onClick: this.handlesort, value: 'owner', id: -1, className: 'sort glyphicon glyphicon-triangle-bottom', style:{height:'5px'}}))),
                        React.createElement('input', {autoFocus: true, id: 'owner', onKeyUp: this.filterUp, defaultValue: this.state.ownertext, placeholder: 'Search', style: {background: 'white', width: '200px'}, type:'text', className:'ownerinput'}),
                        React.createElement('btn-group', null,
                        React.createElement('button', {className:'btn btn-default clear',  value: 'owner', onClick: this.filterclear}, 'Clear'),
                        React.createElement('button', {className:'btn btn-default filter', value: 'owner', onClick: this.handlefilter}, 'Filter')))
                        )},
                        React.createElement("div", {className: "column severity"}, "Owner")))
                        )), 
                        React.createElement('div', {className: 'wrapper status-owner-severity'},
                        React.createElement('div', {className: 'wrapper status-owner'},
                        React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, React.createElement(OverlayTrigger, {trigger:['click','focus'], placement:'bottom', ref: 'myPopOverentries', rootClose: true, overlay: React.createElement(Popover, null,
                        React.createElement('div', {className: 'Filter and Sort', id: 'entriesheader'}, React.createElement('div',
                        {style: {display: 'inline-flex'}}, React.createElement('div', null, 'Entries'), React.createElement('div',
                        {style:{'padding-left': '100px'}}, 'Sort'),
                        React.createElement('btn-group', null,
                        React.createElement('button', {style: {height:'5px'}, onClick: this.handlesort, value: 'entries', id: 1, className: 'sort glyphicon glyphicon-triangle-top'}),
                        React.createElement('button', {onClick: this.handlesort, value: 'entries', id: -1, className: 'sort glyphicon glyphicon-triangle-bottom', style:{height:'5px'}}))),
                        React.createElement('input', {autoFocus: true,id: 'entries', onKeyUp: this.filterUp, defaultValue: this.state.entriestext, placeholder: 'Search', style: {background: 'white', width: '200px'}, type:'text', className:'entriesinput'}),
                        React.createElement('btn-group', null,
                        React.createElement('button', {className:'btn btn-default clear',  value: 'entries', onClick: this.filterclear}, 'Clear'),
                        React.createElement('button', {className:'btn btn-default filter', value: 'entries', onClick: this.handlefilter}, 'Filter')))
                        )},
                        React.createElement("div", {className: "column owner"}, "Entry")))
                        )),

                        React.createElement("div", {className: "wrapper dates"},
                        React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, React.createElement(OverlayTrigger, {trigger:['click','focus'], placement:'bottom', ref: 'myPopOverupdated',rootClose: true, overlay: React.createElement(Popover, null,
                        React.createElement('div', {className: 'Filter and Sort', id: 'updatedheader'}, React.createElement('div',
                        {style: {display: 'inline-flex'}}, React.createElement('div', null, 'Updated'), React.createElement('div',
                        {style:{'padding-left': '80px'}}, 'Sort'),
                        React.createElement('btn-group', null,
                        React.createElement('button', {style: {height:'5px'}, onClick: this.handlesort, className: 'sort glyphicon glyphicon-triangle-top', value: 'updated', id: 1}),
                        React.createElement('button', {value: 'updated', id: -1, onClick: this.handlesort, className: 'sort glyphicon glyphicon-triangle-bottom', style:{height:'5px'}}))),
                        React.createElement('div', {onKeyUp: this.filterUp, id: 'updated', className: 'Dates'},
                        React.createElement(DateRangePicker, {numberOfCalendars: 2, selectionType:"range", showLegend: true, onSelect:this.handleSelectforupdate ,singleDateRange: true}),
                        React.createElement("div",{className: 'dates'}, React.createElement('input', {className: "StartDate",placeholder: 'Start Date', value: this.state.upstartepoch, readOnly:true}),
                          React.createElement('input', {className: "EndDate",placeholder:'End Date', value: this.state.upendepoch, readOnly:true}))),
                        React.createElement('btn-group', null,
                        React.createElement('button', {className:'btn btn-default clear',  value: 'updated',onClick: this.filterclear}, 'Clear'),
                        React.createElement('button', {className:'btn btn-default filter', value: 'updated', onClick: this.handlefilter}, 'Filter')))
                        )},
                        React.createElement("div", {className: "column date"}, "Updated")))
                        ))), 

                    this.state.objectarray.map((value) => React.createElement('div', {className:'allevents', id: value.id},
                        React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, React.createElement(OverlayTrigger, {trigger:['hover', 'focus'], placement:'top', positionTop: 50, title: value.id, style: {overflow: 'auto'}, overlay: React.createElement(Popover, null,
                        React.createElement('div', null,
                        React.createElement('div', {style: {display:'flex'}}, React.createElement('div', {style: {'font-weight': 'bold'}}, 'ID:'),
                        React.createElement('div', null, value.target.id)),
                        React.createElement('div', {style: {display: 'flex'}},
                        React.createElement('div', {style: {'font-weight': 'bold'}}, 'Status:  '), React.createElement('div', null, value.task.status)),
                        React.createElement('div', {style: {display:'flex'}}, React.createElement('div', {style: {'font-weight': 'bold'}}, 'Updated:  '),
                        React.createElement('div', null, value.updated)),                         
                        React.createElement('div', {style: {display:'flex'}}, React.createElement('div', {style: {'font-weight': 'bold'}}, 'Owner:  '),
                        React.createElement('div', null, value.owner)),
                        React.createElement('div', {style: {display:'flex'}}, React.createElement('div', {style: {'font-weight': 'bold'}}, 'Entry:  '),
                        React.createElement('div', null, value.id)), React.createElement('div', {style: {display:'flex'}},
                        React.createElement('div', {style: {'font-weight': 'bold'}}, 'Type:  '), React.createElement('div', null, value.target.type))
                        ))},
                        React.createElement("div", {style: {background: colorrow[0] == value.id ? this.state.blue : this.state.white},onClick: this.clickable, className: "table-row", id: value.targetid},
                        React.createElement("div", {className: "wrapper attributes"},
                        React.createElement('div', {className: 'wrapper status-owner-severity'},
                        React.createElement('div', {className: 'wrapper status-owner'},
                            React.createElement("div", {className: 'column status type'}, value.target.type),
                            React.createElement("div", {className: "column index"}, value.target.id))),
                        React.createElement('div', {className: 'wrapper status-owner-severity'},
                        React.createElement('div', {className: 'wrapper status-owner'}, 
                            React.createElement("div", {className: 'column owner colorstatus'}, value.task.status))),
                            React.createElement('div', {className: 'wrapper status-owner-severity'},
                            React.createElement('div', {className: 'wrapper status-owner'},
                            React.createElement("div", {className: "column status"}, value.owner))),
                            React.createElement('div', {className: 'wrapper status-owner-severity'},
                            React.createElement('div', {className: 'wrapper status-owner'}, 
                            React.createElement("div", {className: "column severity"}, value.id))),
                        React.createElement("div", {className: "wrapper dates"},
                            React.createElement("div", {className: "column date"}, value.updated)))))))))),
                        React.createElement(Page, {paginationToolbarProps: { pageSizes: [5, 20, 100]}, pagefunction: this.getNewData, defaultPageSize: 50, count: this.state.totalcount, pagination: true})) , stage ?
                        React.createElement(SelectedContainer, {height: height - 117,ids: this.state.idsarray, type: this.state.type, taskid: this.state.entry}) : null)
        ));
},

    clearAll: function(){
        sortarray['id'] = -1
        filter = {}
        this.setState({tags: [], sourcetags: [], idtext: '',
            upstartepoch: '', upendepoch: '', statustext: '', typetext: '', entriestext: '', ownertext: '',
            viewstext: ''})
            this.getNewData({page: 0, limit: pageSize})
    },
    filterUp: function(v){
        if(v.keyCode == 13){
            if($($(v.currentTarget).find('.idinput').context).attr('id') == 'id'){
                filter['id'] = [$('.idinput').val()]
                this.refs.myPopOverid.hide()
                this.setState({idtext: $('.idinput').val()})
            }
            else if($($(v.currentTarget).find('.statusinput').context).attr('id') == 'status'){
                filter['task.status'] = $('.statusinput').val()
                this.refs.myPopOverstatus.hide()
                this.setState({statustext: $('.statusinput').val()})
            }
            else if($($(v.currentTarget).find('.typeinput').context).attr('id') == 'type'){
                filter['target.type'] = $('.typeinput').val()
                this.refs.myPopOvertype.hide()
                this.setState({typetext: $('.typeinput').val()})
            }
            else if($($(v.currentTarget).find('.entriesinput').context).attr('id') == 'entries'){
                filter['entries'] = $('.entriesinput').val()
                this.refs.myPopOverentries.hide()
                this.setState({entriestext: $('.entriesinput').val()})
            }
            else if($($(v.currentTarget).find('.ownerinput').context).attr('id') == 'owner'){
                filter['owner'] = $('.ownerinput').val()
                this.refs.myPopOverowner.hide()
                this.setState({ownertext: $('.ownerinput').val()})
            }
            else if($($(v.currentTarget).find('.updatedinput').context).attr('id') == 'updated'){
                filter['updated'] = {begin:start, end:end}
            }

            this.getNewData({page: 0, limit: pageSize})
         }
    },
    clickable: function(v){
        $('#'+$(v.currentTarget).find('.severity').text()).find('.table-row').each(function(x,y){
            var array = []
            colorrow = []
            array.push($(y).find('.index').text())
            colorrow.push($(y).find('.severity').text())
            window.history.pushState('Page', 'SCOT', '/#/'+$(y).find('.type').text() + '/' + array[0]) 
            this.launchEvent(array, $(y).find('.severity').text(), $(y).find('.type').text())
        }.bind(this))
    },

    getNewData: function(page){
        pageSize = page.limit
        defaultpage = page.page
        var newPage;
        if(page.page != 0){
            newPage = (page.page - 1) * page.limit
        }
        else {
               page.limit = pageSize
               newPage = 0
        }
        var newarray = []
        $.ajax({
            type: 'GET',
            url: '/scot/api/v2/task',
            data: {
                limit:  page.limit,
                offset: newPage,
                sort:  JSON.stringify(sortarray),
                match: JSON.stringify(filter)
            }
        }).then(function(response){
            datasource = response
            $.each(datasource.records, function(key, value){
                newarray[key] = {}
                $.each(value, function(num, item){
                    if(num == 'created' || num == 'updated' || num == 'discovered' || num == 'occurred' || num == 'reported')
                    {
                        var date = new Date(1000 * item)
                        newarray[key][num] = date.toLocaleString()
                    }
                    else{
                        newarray[key][num] = item
                    }
                })
            })
                this.setState({totalcount: response.totalRecordCount, activepage: page, objectarray: newarray})
        }.bind(this))
    },
    reloadCSS: function(){
        this.setState({})
    },
    exportCSV: function(){
        var keys = []
        $.each(columns, function(key, value){
            keys.push(value);
        });
        var csv = ''
        $('.allevents').find('.table-row').each(function(key, value){
            var storearray = []
            $(value).find('.column').each(function(x,y) {
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
    handlesort : function(v){
         if($($(v.currentTarget).find('.sort').context).attr('value') == 'id'){
            sortarray['id'] = Number($($(v.currentTarget).find('.sort').context).attr('id'))
            this.refs.myPopOverid.hide()
        }
        else if($($(v.currentTarget).find('.sort').context).attr('value') == 'status'){
            sortarray['task.status'] = Number($($(v.currentTarget).find('.sort').context).attr('id'))
            this.refs.myPopOverstatus.hide()
        }
        else if($($(v.currentTarget).find('.sort').context).attr('value') == 'type'){
            sortarray['target.type'] = Number($($(v.currentTarget).find('.sort').context).attr('id'))
            this.refs.myPopOvertype.hide()
        }
        else if($($(v.currentTarget).find('.sort').context).attr('value') == 'owner'){
            sortarray['owner'] = Number($($(v.currentTarget).find('.sort').context).attr('id'))
            this.refs.myPopOverowner.hide()
        }
        else if($($(v.currentTarget).find('.sort').context).attr('value') == 'updated'){
            sortarray['updated'] = Number($($(v.currentTarget).find('.sort').context).attr('id'))
            this.refs.myPopOverupdated.hide()
        }
        else if($($(v.currentTarget).find('.sort').context).attr('value') == 'entries'){
            sortarray['entries'] = Number($($(v.currentTarget).find('.sort').context).attr('id'))
            this.refs.myPopOverentries.hide()
        }
        this.getNewData({page:0, limit:pageSize})
    },
    filterclear: function(v){
        if($($(v.currentTarget).find('.clear').context).attr('value') == 'id'){
            delete filter.id
            this.refs.myPopOverid.hide()
            this.setState({idtext: ''})
        }
        else if($($(v.currentTarget).find('.clear').context).attr('value') == 'status'){
            delete filter.status
            this.refs.myPopOverstatus.hide()
            this.setState({statustext: ''})
        }
        else if($($(v.currentTarget).find('.clear').context).attr('value') == 'type'){
            delete filter.type
            this.refs.myPopOvertype.hide()
            this.setState({typetext: ''})
        }
       else if($($(v.currentTarget).find('.clear').context).attr('value') == 'updated'){
            delete filter.updated
            this.refs.myPopOvercreated.hide()
            this.setState({upstartepoch: '', upendepoch: ''})
        }
       else if($($(v.currentTarget).find('.clear').context).attr('value') == 'entries'){
            delete filter.entries
            this.refs.myPopOverentries.hide()
            this.setState({entriestext: ''})
        }
       else if($($(v.currentTarget).find('.clear').context).attr('value') == 'owner'){
            delete filter.owner
            this.refs.myPopOverowner.hide()
            this.setState({ownertext: ''})
        }
        this.getNewData({page:0, limit: pageSize})
    },
    handlefilter: function(v){
        if($($(v.currentTarget).find('.filter').context).attr('value') == 'id'){
            filter['task.id'] = [$('.idinput').val()]
            this.refs.myPopOverid.hide()
            this.setState({idtext: $('.idinput').val()})
        }
        else if($($(v.currentTarget).find('.filter').context).attr('value') == 'status'){
            filter['task.status'] = $('.statusinput').val()
            this.refs.myPopOverstatus.hide()
            this.setState({statustext: $('.statusinput').val()})
        }
        else if($($(v.currentTarget).find('.filter').context).attr('value') == 'type'){
            filter['target.type'] = $('.typeinput').val()
            this.refs.myPopOvertype.hide()
            this.setState({typetext: $('.typeinput').val()})
        }
        else if($($(v.currentTarget).find('.filter').context).attr('value') == 'entries'){
            filter['entries'] = $('.entriesinput').val()
            this.refs.myPopOverentries.hide()
            this.setState({entriestext: $('.entriesinput').val()})
        }
        else if($($(v.currentTarget).find('.filter').context).attr('value') == 'owner'){
            filter['owner'] = $('.ownerinput').val()
            this.refs.myPopOverowner.hide()
            this.setState({ownertext: $('.ownerinput').val()})
        }
        else if($($(v.currentTarget).find('.filter').context).attr('value') == 'updated'){
            filter['updated'] = {begin:start, end:end}
            this.refs.myPopOverupdated.hide()
        }
        this.getNewData({page: 0, limit: pageSize})
    }
});
