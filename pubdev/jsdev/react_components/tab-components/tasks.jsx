'use strict';

var React                   = require('react')
var SelectedContainer       = require('../entry/selected_container.jsx')
var Notificationactivemq    = require('../../../node_modules/react-notification-system')
var Search                  = require('../components/esearch.jsx')
var Store                   = require('../activemq/store.jsx')
var Page                    = require('../components/paging.jsx')
var Popover                 = require('react-bootstrap/lib/Popover')
var SplitButton             = require('react-bootstrap/lib/SplitButton.js');
var OverlayTrigger          = require('react-bootstrap/lib/OverlayTrigger')
var ButtonToolbar           = require('react-bootstrap/lib/ButtonToolbar')
var DateRangePicker         = require('../../../node_modules/react-daterange-picker')
var Source                  = require('react-tag-input-tags/react-tag-input').WithContext
var Tags                    = require('react-tag-input').WithContext
var Button                  = require('react-bootstrap/lib/Button.js');
var DropdownButton          = require('react-bootstrap/lib/DropdownButton.js');
var MenuItem                = require('react-bootstrap/lib/MenuItem.js');
var fluidheight
var size = 645
var toggle
var scrolled = 43
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
var columns = ['Type', 'id', 'Status', 'Owner', 'Entry', 'Updated']
var listStartX;
var listStartY;
var listStartWidth;
var listStartHeight;

module.exports = React.createClass({

    getInitialState: function(){
        var scrollHeight = $(window).height() - 170
        var scrollWidth  = '650px'
        width = 650
        fluidheight = $(window).height() - 108
    return {
            resize: 'horizontal', mute: false, splitter: true, pagedisplay: 'inline-flex', 
            display: 'flex', upstartepoch: '', upendepoch: '',white: 'white', blue: '#AEDAFF',
            idtext: '', totalcount: 0, activepage: 0,
            sizearray: ['dates-orgclass', 'status-owner-orgclass', 'module-reporter-orgclass'],
            idarrow: [-1,-1], typearrow: [0, 0], statusarrow: [0, 0],
            updatedarrow:[0, 0],ownerarrow: [0, 0], entriesarrow: [0, 0],
            alldetail: true, entry: 0, type: '', statustext: '', idsarray: [],
            ownertext: '', typetext: '', entriestext: '', scrollheight: scrollHeight,
            scrollwidth: scrollWidth, reload: false,
            classname: [' ', ' ',' ', ' '],
            objectarray:[], csv:true};
    },
    componentWillMount: function() {
        if (this.props.viewMode == undefined || this.props.viewMode == 'default') {
            this.Landscap();
        } else if (this.props.viewMode == 'landscape') {
            this.Landscap();
        } else if (this.props.viewMode == 'portrait') {
            this.Portrait();
        } 
    },
    componentDidMount: function(){
        if ($('#list-view')[0] != undefined) {
            toggle  = $('#list-view').find('.tableview')
        } else {
            toggle = $('#old-list-view').find('.tableview')
        }  
        var t2 = document.getElementById('fluid2')
        $(t2).resize(function(){
            this.reloadItem()
        }.bind(this))
        $(document.body).keydown(function(e){
            if ($('input').is(':focus')) {return};
            var obj = $(toggle[0]).find('#'+colorrow[0]).prev('.allevents')
            var obj2 = $(toggle[0]).find('#'+colorrow[0]).next('.allevents')
            if((e.keyCode == 74 && obj2.length != 0) || (e.keyCode == 40 && obj2.length != 0)){
                var set;
                set  = $(toggle[0]).find('#'+colorrow[0]).next('.allevents').click()
                var array = []
                colorrow = []
                colorrow.push($(set).attr('id'))
                array.push($(set).find('.index').text())
                $('.container-fluid2').scrollTop(scrolled)
                window.history.pushState('Page', 'SCOT', '/#/'+$(set).find('.type').text() + '/' + array[0]) 
                scrolled = scrolled + $(toggle[0]).find('#'+colorrow[0]).height()
                this.setState({idsarray: array, type: $(set).find('.type').text(), entry: colorrow[0]})
            }
            else if((e.keyCode == 75 && obj.length != 0) || (e.keyCode == 38 && obj.length != 0)){
                var set;
                set  = $(toggle[0]).find('#'+colorrow[0]).prev('.allevents').click()
                var array = []
                colorrow = []
                colorrow.push($(set).attr('id'))
                array.push($(set).find('.index').text())
                $('.container-fluid2').scrollTop(scrolled)
                scrolled = scrolled - $(toggle[0]).find('#'+colorrow[0]).height()
                window.history.pushState('Page', 'SCOT', '/#/'+$(set).find('.type').text() + '/' + array[0]) 
                this.setState({idsarray: array, type: $(set).find('.type').text(), entry: colorrow[0]})
            } else if (e.keyCode == 70) {
                this.toggleView();
            }
        }.bind(this)) 
        
        var height = this.state.scrollheight 
        var array = []
        if(this.props.ids !== undefined){
            if(this.props.ids.length > 0){
                array = this.props.ids
                stage = true
                scrolled = $('.container-fluid2').scrollTop()
                if(this.state.display == 'block'){
                    height = '300px'
                }
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
            if(key %2 == 0){
                finalarray[key]["classname"] = 'table-row roweven'
            }
            else {
                finalarray[key]["classname"] = 'table-row rowodd'
            }
        })
        this.setState({scrollheight: height, idsarray: array, objectarray: finalarray,totalcount: response.totalRecordCount})
        }.bind(this))
    },

    reloadactive: function(){
        var notification = this.refs.notificationSystem
        if(activemqwho != 'scot-admin' && activemqwho != 'scot-alerts' && activemqwho != whoami && notification != undefined && activemqwho != "" &&  activemqwho != 'api'){
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
    reloadItem: function(e){
        /*
       console.log($('.container-fluid2').width())
        if($('.container-fluid2').width() == 100){
            $('.paging').css('display', 'none')
        }
        */
        $('iframe').each(function(index,ifr){
            $(ifr).addClass('pointerEventsOff')
        })
        var t2 = document.getElementById('fluid2')
        height = $(window).height() - 170
        width = $(t2).width()
        if(this.state.display == 'flex'){
        fluidheight = $(window).height() - 108            
$('.container-fluid2').css('height', height)
            $('.container-fluid2').css('max-height', height)
            //$('.container-fluid2').css('max-width', '915px')
            if(e != null){
                //width = e.clientX
                $('.container-fluid2').css('width', listStartWidth + e.clientX - listStartX)
            }
            if(width < size){
                var array = []
                array =  ['table-row-smallclass', 'attributes-smallclass','module-reporter-smallclass', 'status-owner-smallclass']

                $('.paging').css('width', width)
                $('.paging').css('overflow-x','auto')
                $('.splitter').css('width', '5px')
                this.setState({classname: array})
           }
            else {
                size = 645
                var array = []
                var classname = [' ', ' ', ' ', ' ']
                array = ['dates-orgclass', 'status-owner-orgclass', 'module-reporter-orgclass']
                $('.paging').css('width', width)
                this.setState({scrollwidth: '650px', sizearray: array, classname:classname})
               }
        }
        else {
        //    $('.container-fluid2').css('height', this.state.idsarray.length != 0 ? '300px' : height)
              $('.container-fluid2').css('width', '100%')
              if(e != null){
                $('.container-fluid2').css('height', listStartHeight + e.clientY - listStartY)
                this.forceUpdate();
            }
        }
    },
    launchEvent: function(array,entryid,tasktype){
        stage = true
        if(this.state.display == 'block'){
            this.state.scrollheight = '300px'
        }
        this.setState({scrollheight: this.state.scrollheight, idsarray:array, type: tasktype, entry: entryid})

    },
    clearNote: function(){
        if(this.state.mute){
            this.setState({mute: false})
        }
        else {
            this.setState({mute: true})
        }
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
                    !this.state.mute ? React.createElement(Notificationactivemq, {ref: 'notificationSystem'}):null),
                        React.createElement("div", {className: 'entry-header-info-null', style: {'padding-bottom': '55px',width:'100%'}},
                        React.createElement("div", {style: {top: '1px', 'margin-left': '10px', float:'left', 'text-align':'center', position: 'absolute'}},
                        React.createElement('h2', {style: {'font-size': '30px'}}, 'Task')),
                        React.createElement("div", {style: {float: 'right', right: '100px', left: '50px','text-align': 'center', position: 'absolute', top: '9px'}},
                        React.createElement('h2', {style: {'font-size': '19px'}}, 'OUO')),
                        React.createElement(Search, null)), 

                        React.createElement('div', {className: 'mainview', style: {display: this.state.display == 'block' ? 'block' : 'flex'}},
                        React.createElement('div', {style:{display: 'block'}},
                        React.createElement('div', {style: {display: 'inline-flex'}},
                        width < 645 ?
                        React.createElement('div', {className: 'buttonmenu'},
                        React.createElement(SplitButton, {bsSize: 'xsmall' , title: 'Select'},
                        !this.state.mute ?
                        React.createElement(Button, {eventKey: '1', onClick: this.clearNote, bsSize: 'xsmall'}, 'Mute ', React.createElement('b', null, 'Notifications')): React.createElement(Button , {eventKey: '2', onClick: this.clearNote, bsSize: 'xsmall'}, 'Turn On ', React.createElement('b', null, 'Notifications')),
                        React.createElement(Button, {onClick: this.clearAll, eventKey: '3', bsSize: 'xsmall'}, 'Clear All ', React.createElement('b', null, 'Filters')),
                        React.createElement(Button, {eventKey: '5', bsSize: 'xsmall',onClick: this.exportCSV}, 'Export to ', React.createElement('b', null, 'CSV')))) : /* , !this.state.mute ? React.createElement('button', {className: 'btn btn-default', onClick:this.dismissNote, style: styles}, 'Clear All Notifications') : null */
                        React.createElement('div', {className: 'buttonmenu'},
                        !this.state.mute ?
                        React.createElement(Button, {eventKey: '1', onClick: this.clearNote, bsSize: 'xsmall'}, 'Mute ', React.createElement('b', null, 'Notifications')): React.createElement(Button , {eventKey: '2', onClick: this.clearNote, bsSize: 'xsmall'}, 'Turn On ', React.createElement('b', null, 'Notifications')),
                        React.createElement(Button, {onClick: this.clearAll, eventKey: '3', bsSize: 'xsmall'}, 'Clear All ', React.createElement('b', null, 'Filters')),
                        React.createElement(Button, {eventKey: '5', bsSize: 'xsmall',onClick: this.exportCSV}, 'Export to ', React.createElement('b', null, 'CSV')))
                        ,

                         React.createElement(DropdownButton, {bsSize: 'xsmall', title: 'View'},
                         React.createElement(MenuItem, {eventKey: '10', onClick:this.Portrait}, 'Portrait ', React.createElement('b', null, 'View')), React.createElement(MenuItem, {eventKey: '11', onClick:this.Landscap}, 'Landscape ', React.createElement('b', null, 'View')), React.createElement(MenuItem, {eventKey: '3', onClick: this.toggleView}, 'Toggle ', React.createElement('b', null, 'Detail View')))
            ),
            Object.getOwnPropertyNames(filter).length !== 0 ? React.createElement("div", {style: {width: width, color: 'blue', 'text-overflow': 'ellipsis', 'overflow-x': 'auto', 'font-weight': 'bold', 'font-style': 'italic', 'white-space': 'nowrap','padding-left': '5px'}}, 'Filtered: ' + JSON.stringify(filter)) : null,
            React.createElement('div', {className: 'incidentwidth', style: {display:this.state.display}},
            React.createElement('div', {style: {width: this.state.differentviews},id:this.state.display == 'block' ? 'old-list-view' : 'list-view'},
            React.createElement('div', {className: 'tableview', style:{display: 'flex'}},
                React.createElement("div", {className: "container-fluid2", id: 'fluid2', style: {/*'max-width': '915px',*//*'min-width': '650px',*/ width:this.state.scrollwidth, 'max-height': this.state.maxheight, 'margin-left': '0px',height: this.state.scrollheight, 'overflow' : 'hidden','padding-left':'5px', display:'flex', flexFlow:'column'}},
                    React.createElement("div", {className: "table-row header "+ this.state.classname[0]},
                        React.createElement("div", {className: "wrapper attributes "+ this.state.classname[1]},
                        React.createElement('div', {className: 'wrapper '},
                        React.createElement('div', {className: 'wrapper status-owner '+ this.state.sizearray[1] + ' ' + this.state.classname[3]},
                        React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, React.createElement(OverlayTrigger, {trigger:['click','focus'], placement:'bottom', ref: 'myPopOvertype', rootClose: true, overlay: React.createElement(Popover, null,
                        React.createElement('div', {className: 'Filter and Sort', id: 'typeheader'}, React.createElement('div',
                        {style: {display: 'inline-flex'}}, React.createElement('div', null, 'Type'), React.createElement('div',
                        {style:{'padding-left': '100px'}}, 'Sort'),
                        React.createElement('btn-group', null,
                        React.createElement('button', {style: {height:'5px'}, onClick: this.handlesort, value: 'type', id: -1, className: 'sort glyphicon glyphicon-triangle-top'}),
                        React.createElement('button', {onClick: this.handlesort, value: 'type', id: 1, className: 'sort glyphicon glyphicon-triangle-bottom', style:{height:'5px'}}))),
                        React.createElement('input', {autoFocus: true,id: 'type', onKeyUp: this.filterUp, defaultValue: this.state.typetext, placeholder: 'Search', style: {background: 'white', width: '200px'}, type:'text', className:'typeinput'}),
                        React.createElement('btn-group', null,
                        React.createElement('button', {className:'btn btn-default clear',  value: 'type', onClick: this.filterclear}, 'Clear'),
                        React.createElement('button', {className:'btn btn-default filter', value: 'type', onClick: this.handlefilter}, 'Filter')))
                        )},
                         React.createElement('div', {style: {display: 'flex'}},
                         React.createElement("div", {className: "column owner"}, "Type"),
                        this.state.typearrow[0] != 0 ? React.createElement('div', {className:'arrow-up', style:{ width: 0, height: 0, 'border-left': this.state.typearrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-right': this.state.typearrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-bottom': this.state.typearrow[1] == -1 ? '5px solid black' : null, 'border-top': this.state.typearrow[1] == -1 ? null : '5px solid black', top: '9px', right: '40px', position: 'relative'}}) : null))),

                        React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, React.createElement(OverlayTrigger, {ref: 'myPopOverid', trigger:['click','focus'], placement:'bottom', rootClose: true, overlay: React.createElement(Popover, null,
                        React.createElement('div', {className: 'Filter and Sort', id: 'idheader'}, React.createElement('div',
                        {style: {display: 'inline-flex'}}, React.createElement('div', null, 'ID'), React.createElement('div',
                        {style:{'padding-left': '100px'}}, 'Sort'),
                        React.createElement('btn-group', null,
                        React.createElement('button', {style: {height:'5px'},value: 'id', id: -1, onClick: this.handlesort, className: 'sort glyphicon glyphicon-triangle-top'}),
                        React.createElement('button', {className: 'sort glyphicon glyphicon-triangle-bottom', value: 'id', onClick: this.handlesort, id: 1, style:{height:'5px'}}))),
                        React.createElement('input',  {autoFocus: true, id:'id',onKeyUp: this.filterUp, defaultValue: this.state.idtext, placeholder: 'Search', style: {background: 'white', width: '200px'}, type:'text', className:'idinput'}),
                        React.createElement('btn-group', null,
                        React.createElement('button', {className:'btn btn-default clear', value: 'id', onClick: this.filterclear}, 'Clear'),
                        React.createElement('button', {value: 'id',className:'filter btn btn-default', onClick: this.handlefilter}, 'Filter')))
                        )},
                        React.createElement('div', {style: {display: 'flex'}},
                        React.createElement('div',{style: {width: '87px'}, className: 'column index'}, 'ID'), this.state.idarrow[0] != 0 ? React.createElement('div', {className:'arrow-up', style:{ width: 0, height: 0, 'border-left': this.state.idarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-right': this.state.idarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-bottom': this.state.idarrow[1] == -1 ? '5px solid black' : null, 'border-top': this.state.idarrow[1] == -1 ? null : '5px solid black', top: '9px', right: '30px', position: 'relative'}}) : null)))
                        )),

                        React.createElement('div', {className: 'wrapper '},
                        React.createElement('div', {className: 'wrapper status-owner '+ this.state.sizearray[1] + ' ' + this.state.classname[3]},
                        React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, React.createElement(OverlayTrigger, {trigger:['click','focus'], placement:'bottom', ref: 'myPopOverstatus', rootClose: true, overlay: React.createElement(Popover, null,
                        React.createElement('div', {className: 'Filter and Sort', id: 'statusheader'}, React.createElement('div',
                        {style: {display: 'inline-flex'}}, React.createElement('div', null, 'Status'), React.createElement('div',
                        {style:{'padding-left': '100px'}}, 'Sort'),
                        React.createElement('btn-group', null,
                        React.createElement('button', {style: {height:'5px'}, onClick: this.handlesort, value: 'status', id: -1, className: 'sort glyphicon glyphicon-triangle-top'}),
                        React.createElement('button', {onClick: this.handlesort, value: 'status', id: 1, className: 'sort glyphicon glyphicon-triangle-bottom', style:{height:'5px'}}))),
                        React.createElement('input', {autoFocus: true,id: 'status', onKeyUp: this.filterUp, defaultValue: this.state.statustext, placeholder: 'Search', style: {background: 'white', width: '200px'}, type:'text', className:'statusinput'}),
                        React.createElement('btn-group', null,
                        React.createElement('button', {className:'btn btn-default clear',  value: 'status', onClick: this.filterclear}, 'Clear'),
                        React.createElement('button', {className:'btn btn-default filter', value: 'status', onClick: this.handlefilter}, 'Filter')))
                        )},
                         React.createElement('div', {style: {display: 'flex'}},
                         React.createElement("div", {className: "column owner"}, "Status"),
                        this.state.statusarrow[0] != 0 ? React.createElement('div', {className:'arrow-up', style:{ width: 0, height: 0, 'border-left': this.state.statusarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-right': this.state.statusarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-bottom': this.state.statusarrow[1] == -1 ? '5px solid black' : null, 'border-top': this.state.statusarrow[1] == -1 ? null : '5px solid black', top: '9px', right: '40px', position: 'relative'}}) : null)))
                         )),
                         React.createElement('div', {className: 'wrapper '},
                         React.createElement('div', {className: 'wrapper status-owner '+ this.state.sizearray[1] + ' ' + this.state.classname[3]},
                         React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, React.createElement(OverlayTrigger, {trigger:['click','focus'], placement:'bottom', ref: 'myPopOverowner', rootClose: true, overlay: React.createElement(Popover, null,
                        React.createElement('div', {className: 'Filter and Sort', id: 'ownerheader'}, React.createElement('div',
                        {style: {display: 'inline-flex'}}, React.createElement('div', null, 'Owner'), React.createElement('div',
                        {style:{'padding-left': '100px'}}, 'Sort'),
                        React.createElement('btn-group', null,
                        React.createElement('button', {style: {height:'5px'}, onClick: this.handlesort, value: 'owner', id: -1, className: 'sort glyphicon glyphicon-triangle-top'}),
                        React.createElement('button', {onClick: this.handlesort, value: 'owner', id: 1, className: 'sort glyphicon glyphicon-triangle-bottom', style:{height:'5px'}}))),
                        React.createElement('input', {autoFocus: true, id: 'owner', onKeyUp: this.filterUp, defaultValue: this.state.ownertext, placeholder: 'Search', style: {background: 'white', width: '200px'}, type:'text', className:'ownerinput'}),
                        React.createElement('btn-group', null,
                        React.createElement('button', {className:'btn btn-default clear',  value: 'owner', onClick: this.filterclear}, 'Clear'),
                        React.createElement('button', {className:'btn btn-default filter', value: 'owner', onClick: this.handlefilter}, 'Filter')))
                        )},
                            React.createElement('div', {style: {display: 'flex'}},
                            React.createElement("div", {style: {width: '92px'}, className: "column severity"}, "Owner"),
                           this.state.ownerarrow[0] != 0 ? React.createElement('div', {className:'arrow-up', style:{ width: 0, height: 0, 'border-left': this.state.ownerarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-right': this.state.ownerarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-bottom': this.state.ownerarrow[1] == -1 ? '5px solid black' : null, 'border-top': this.state.ownerarrow[1] == -1 ? null : '5px solid black', top: '9px', right: '30px', position: 'relative'}}) : null)))
                        )), 
                        React.createElement('div', {className: 'wrapper '},
                        React.createElement('div', {className: 'wrapper status-owner '+ this.state.sizearray[1] + ' ' + this.state.classname[3]},
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
                        React.createElement('div', {style: {display: 'flex'}},
                        React.createElement("div", {className: "column owner"}, "Entries"),
                        this.state.entriesarrow[0] != 0 ? React.createElement('div', {className:'arrow-up', style:{ width: 0, height: 0, 'border-left': this.state.entriesarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-right': this.state.entriesarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-bottom': this.state.entriesarrow[1] == -1 ? '5px solid black' : null, 'border-top': this.state.entriesarrow[1] == -1 ? null : '5px solid black', top: '9px', right: '45px', position: 'relative'}}) : null)))
                        )),

                        React.createElement("div", {className: "wrapper dates "+ this.state.sizearray[0]},
                        React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, React.createElement(OverlayTrigger, {trigger:['click','focus'], placement:'bottom', ref: 'myPopOverupdated',rootClose: true, overlay: React.createElement(Popover, null,
                        React.createElement('div', {className: 'Filter and Sort', id: 'updatedheader'}, React.createElement('div',
                        {style: {display: 'inline-flex'}}, React.createElement('div', null, 'Updated'), React.createElement('div',
                        {style:{'padding-left': '80px'}}, 'Sort'),
                        React.createElement('btn-group', null,
                        React.createElement('button', {style: {height:'5px'}, onClick: this.handlesort, className: 'sort glyphicon glyphicon-triangle-top', value: 'updated', id: -1}),
                        React.createElement('button', {value: 'updated', id: 1, onClick: this.handlesort, className: 'sort glyphicon glyphicon-triangle-bottom', style:{height:'5px'}}))),
                        React.createElement('div', {onKeyUp: this.filterUp, id: 'updated', className: 'Dates'},
                        React.createElement(DateRangePicker, {numberOfCalendars: 2, selectionType:"range", showLegend: true, onSelect:this.handleSelectforupdate ,singleDateRange: true}),
                        React.createElement("div",{className: 'dates'}, React.createElement('input', {className: "StartDate",placeholder: 'Start Date', value: this.state.upstartepoch, readOnly:true}),
                          React.createElement('input', {className: "EndDate",placeholder:'End Date', value: this.state.upendepoch, readOnly:true}))),
                        React.createElement('btn-group', null,
                        React.createElement('button', {className:'btn btn-default clear',  value: 'updated',onClick: this.filterclear}, 'Clear'),
                        React.createElement('button', {className:'btn btn-default filter', value: 'updated', onClick: this.handlefilter}, 'Filter')))
                        )},
                        React.createElement('div', {style: {display: 'flex'}},
                        React.createElement("div", {style: {position: this.state.display == 'block' ? 'relative' : null, right: this.state.display == 'block' ? '12px' : null},className: "column date"}, "Updated"),
                        this.state.updatedarrow[0] != 0 ? React.createElement('div', {className:'arrow-up', style:{ width: 0, height: 0, 'border-left': this.state.updatedarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-right': this.state.updatedarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-bottom': this.state.updatedarrow[1] == -1 ? '5px solid black' : null, 'border-top': this.state.updatedarrow[1] == -1 ? null : '5px solid black', top: '9px', right: '45px', position: 'relative'}}) : null))
                        )))), 
                   React.createElement('div', {id: 'listpane', style:{overflowY:'auto'}},
                    this.state.objectarray.map((value) => React.createElement('div', {className:'allevents', id: value.id},
                        
                        React.createElement("div", {style: {background: colorrow[0] == value.id ? this.state.blue : null},classname: value.classname + ' ' + this.state.classname[0],onClick: this.clickable, className: value.classname + ' ' + this.state.classname[0], id: value.targetid},
                        React.createElement("div", {className: "wrapper attributes "+ this.state.classname[1]},
                        React.createElement('div', {className: 'wrapper '},
                        React.createElement('div', {className: 'wrapper status-owner '+ this.state.sizearray[1] + ' ' + this.state.classname[3]},
                            React.createElement("div", {className: 'column status type'}, value.target.type),
                            React.createElement("div", {style: {width: '100px'}, className: "column index"}, value.target.id))),
                        React.createElement('div', {className: 'wrapper '},
                        React.createElement('div', {className: 'wrapper status-owner '+ this.state.sizearray[1] + ' ' + this.state.classname[3]}, 
                            React.createElement("div", {className: 'column owner colorstatus'}, value.task.status))),
                            React.createElement('div', {className: 'wrapper '},
                            React.createElement('div', {className: 'wrapper status-owner '+ this.state.sizearray[1] + '  ' + this.state.classname[3]},
                            React.createElement("div", {className: "column status"}, value.owner))),
                            React.createElement('div', {className: 'wrapper '},
                            React.createElement('div', {className: 'wrapper status-owner '+ this.state.sizearray[1] + ' ' + this.state.classname[3]}, 
                            React.createElement("div", {className: "column severity"}, value.id))),
                        React.createElement("div", {className: "wrapper dates "+this.state.sizearray[0]},
                            React.createElement("div", {className: "column date"}, value.updated))))))))),
                                                               !this.state.splitter ?
React.createElement('div', {onMouseDown: this.dragdiv, className: 'splitter', style: {display: 'block', height: '5px', 'background-color': 'black', 'border-top': '1px solid #AAA', 'border-bottom': '1px solid #AAA', cursor: 'nwse-resize', overflow: 'hidden'}}): null,        
                React.createElement(Page, {paginationToolbarProps: { pageSizes: [5, 20, 50, 100]}, pagefunction: this.getNewData, defaultPageSize: 50, count: this.state.totalcount, pagination: true})))) , 

                        this.state.splitter ?
                        React.createElement('div' , null,
                        React.createElement('div', {onMouseDown: this.dragdiv, className: 'splitter', style: {display: 'block', width: '5px', height: fluidheight, 'background-color': 'black', 'border-top': '1px solid #AAA', 'border-bottom': '1px solid #AAA', cursor: 'nwse-resize', overflow: 'hidden'}})) : null,
stage ?
                        React.createElement(SelectedContainer, {height: height - 117,ids: this.state.idsarray, type: this.state.type, taskid: this.state.entry}) : null),
                        !this.state.alldetail ?
                        React.createElement('div', null,
                        React.createElement('div', {className: 'toggleview'},
                        React.createElement('div', {style: {display:'block'}},
                         React.createElement('div', {className: 'buttonmenu', style: {display: 'inline-flex'}},
                        !this.state.mute ?
                        React.createElement(Button, {eventKey: '1', onClick: this.clearNote, bsSize: 'xsmall'}, 'Mute ', React.createElement('b', null, 'Notifications')): React.createElement(Button , {eventKey: '2', onClick: this.clearNote, bsSize: 'xsmall'}, 'Turn On ', React.createElement('b', null, 'Notifications')),
                        React.createElement(Button, {onClick: this.clearAll, eventKey: '3', bsSize: 'xsmall'}, 'Clear All ', React.createElement('b', null, 'Filters')),
                        React.createElement(Button, {eventKey: '5', bsSize: 'xsmall',onClick: this.exportCSV}, 'Export to ', React.createElement('b', null, 'CSV'))/* , !this.state.mute ? React.createElement('button', {className: 'btn btn-default', onClick:this.dismissNote, style: styles}, 'Clear All Notifications') : null */,

                         React.createElement(DropdownButton, {bsSize: 'xsmall', title: 'View'},
                         React.createElement(MenuItem, {eventKey: '10', onClick:this.Portrait}, 'Portrait ', React.createElement('b', null, 'View')), React.createElement(MenuItem, {eventKey: '11', onClick:this.Landscap}, 'Landscape ', React.createElement('b', null, 'View')), React.createElement(MenuItem, {eventKey: '3', onClick: this.toggleView}, 'Toggle ', React.createElement('b', null, 'Detail View'))))
            ),
                        React.createElement(SelectedContainer, {height: height - 117,ids: this.state.idsarray, type: this.state.type, taskid: this.state.entry })
        )) : React.createElement('div', null)
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
        $('#list-view').find('.container-fluid2').focus()   
        $('#'+$(v.currentTarget).find('.severity').text()).find('.table-row').each(function(x,y){
            var array = []
            colorrow = []
            array.push($(y).find('.index').text())
            colorrow.push($(y).find('.severity').text())
            window.history.pushState('Page', 'SCOT', '/#/'+$(y).find('.type').text() + '/' + array[0]) 
            this.launchEvent(array, $(y).find('.severity').text(), $(y).find('.type').text())
        }.bind(this))
        scrolled = $('.container-fluid2').scrollTop()
    },
    toggleView: function(){
        if(this.state.idsarray.length != 0 && stage == true){
            stage = false
            $('.mainview').hide()
            this.setState({alldetail: false, containerdisplay: 'inherit'})
        }  else {
            stage = true;
            $('.mainview').show();
            this.setState({alldetail:true});
        }
        /*var t2 = document.getElementById('fluid2')
        $(t2).resize(function(){
            this.reloadItem()
        }.bind(this))
         if(!this.state.alldetail) {
            this.setState({alldetail: true})
        }
        else {
            this.setState({alldetail: false})
        } */
    },
    stopdrag: function(e){
        $('iframe').each(function(index,ifr){
        $(ifr).removeClass('pointerEventsOff')
        })
        document.onmousemove = null
        $('.container-fluid2').css('width', width)
        $('.paging').css('width', width)
        $('.splitter').css('width', '5px')
        if(this.state.resize == 'vertical'){
            width = 650
            $('.container-fluid2').css('width', '100%')
            $('.paging').css('width', '100%')
            $('.splitter').css('width', '100%')
        }
    },
    dragdiv: function(e){
        var elem = document.getElementById('fluid2');
        listStartX = e.clientX;
        listStartY = e.clientY;
        listStartWidth = parseInt(document.defaultView.getComputedStyle(elem).width,10)
        listStartHeight = parseInt(document.defaultView.getComputedStyle(elem).height,10)
        document.onmousemove = this.reloadItem
        document.onmouseup  = this.stopdrag
    },
    Portrait: function(){
        document.onmousemove = null
        document.onmousedown = null
        document.onmouseup = null 
        stage = true
        width =650
        $('.paging').css('width', width)
        $('.splitter').css('width', '5px')
        $('.container-fluid2').css('width', '650px')
        $('.mainview').show()
        var array = []
        array = ['dates-small', 'status-owner-small', 'module-reporter-small']
                        this.setState({splitter: true,display: 'flex', alldetail: true, scrollheight: $(window).height() - 170, maxheight: $(window).height() - 170, resize: 'horizontal',differentviews: '',
                        maxwidth: '', minwidth: '',scrollwidth: '650px', sizearray: array})
        setCookie('viewMode',"portrait",1000);
    },

    Landscap: function(){
        document.onmousemove = null
        document.onmousedown = null
        document.onmouseup = null
        stage = true
        width = 650
        $('.paging').css('width', '100%')
        $('.splitter').css('width', '100%')
        $('.mainview').show()
        var array = []
        array = ['dates-wide', 'status-owner-wide', 'module-reporter-wide']
        this.setState({classname: [' ', ' ', ' ', ' '],display: 'block', maxheight: '', alldetail: true, differentviews: '100%',
        splitter: false, scrollheight: this.state.idsarray.length != 0 ? '300px' : $(window).height()  - 170, maxwidth: '', minwidth: '',scrollwidth: '100%', sizearray: array, resize: 'vertical'})
        setCookie('viewMode',"landscape",1000);
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
                if(key %2 == 0){
                    newarray[key]['classname'] = 'table-row roweven'
                }
                else {
                    newarray[key]['classname'] = 'table-row rowodd'
                }
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
            this.setState({idarrow: [Number($($(v.currentTarget).find('.sort').context).attr('id'))
, Number($($(v.currentTarget).find('.sort').context).attr('id'))]})
        }
        else if($($(v.currentTarget).find('.sort').context).attr('value') == 'status'){
            sortarray['task.status'] = Number($($(v.currentTarget).find('.sort').context).attr('id'))
            this.refs.myPopOverstatus.hide()
            this.setState({statusarrow: [Number($($(v.currentTarget).find('.sort').context).attr('id'))
, Number($($(v.currentTarget).find('.sort').context).attr('id'))]})
        }
        else if($($(v.currentTarget).find('.sort').context).attr('value') == 'type'){
            sortarray['target.type'] = Number($($(v.currentTarget).find('.sort').context).attr('id'))
            this.refs.myPopOvertype.hide()
            this.setState({typearrow: [Number($($(v.currentTarget).find('.sort').context).attr('id'))
, Number($($(v.currentTarget).find('.sort').context).attr('id'))]})
        }
        else if($($(v.currentTarget).find('.sort').context).attr('value') == 'owner'){
            sortarray['owner'] = Number($($(v.currentTarget).find('.sort').context).attr('id'))
            this.refs.myPopOverowner.hide()
            this.setState({ownerarrow: [Number($($(v.currentTarget).find('.sort').context).attr('id'))
, Number($($(v.currentTarget).find('.sort').context).attr('id'))]})
        }
        else if($($(v.currentTarget).find('.sort').context).attr('value') == 'updated'){
            sortarray['updated'] = Number($($(v.currentTarget).find('.sort').context).attr('id'))
            this.refs.myPopOverupdated.hide()
            this.setState({updatedarrow: [Number($($(v.currentTarget).find('.sort').context).attr('id'))
, Number($($(v.currentTarget).find('.sort').context).attr('id'))]})
        }
        else if($($(v.currentTarget).find('.sort').context).attr('value') == 'entries'){
            sortarray['entries'] = Number($($(v.currentTarget).find('.sort').context).attr('id'))
            this.refs.myPopOverentries.hide()
            this.setState({entriesarrow: [Number($($(v.currentTarget).find('.sort').context).attr('id'))
, Number($($(v.currentTarget).find('.sort').context).attr('id'))]})
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
