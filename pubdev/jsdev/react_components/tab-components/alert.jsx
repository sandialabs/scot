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
var Button                  = require('react-bootstrap/lib/Button')
var SplitButton             = require('react-bootstrap/lib/SplitButton.js');
var DropdownButton          = require('react-bootstrap/lib/DropdownButton.js');
var MenuItem                = require('react-bootstrap/lib/MenuItem.js');
var SORT_INFO;
var colsort = "id"
var start;
var end;
var valuesort = -1
var SELECTED_ID = {}
var filter = {}
var sortarray = {}
var names = 'none'
var getColumn;
var tab;
var highlight = false
var datasource
var ids = []
var stage = false
var savedsearch = false
var savedfsearch;
var fluidheight;
var setfilter = false
var savedid;
var height;
var width;
var size = 645
var defaultpage = 1;
var pageSize = 50;
var readonly = []
var colorrow = [];
sortarray[colsort] = -1
var columns = ['id', 'Status', 'Subject', 'Created', 'Source', 'Tags', 'Views']
var toggle
var scrolled = 48
module.exports = React.createClass({

    getInitialState: function(){
        var scrollHeight = $(window).height() - 170
        var scrollWidth  = '650px'  
        width = 650
        fluidheight = $(window).height() - 108
    return {
            splitter: true, 
            pagedisplay: 'inline-flex', mute: false,unbold: '', bold: 'bold', white: 'white', blue: '#AEDAFF',
            sourcetags: [], tags: [], startepoch:'', endepoch: '', idtext: '', totalcount: 0, activepage: 0,
            sizearray: ['dates-orgclass', 'status-owner-orgclass', 'module-reporter-orgclass'],
            statustext: '', subjecttext:'', idsarray: [], classname: [' ', ' ',' ', ' '],
            alldetail : true, viewsarrow: [0,0], idarrow: [-1,-1], subjectarrow: [0, 0], statusarrow: [0, 0],
            resize: 'horizontal',createdarrow: [0, 0], sourcearrow:[0, 0],tagsarrow: [0, 0],
            alertPreSelectedId: 0, viewstext: '', entriestext: '', scrollheight: scrollHeight, display: 'flex',
            differentviews: '',maxwidth: '915px', maxheight: scrollHeight,  minwidth: '650px',
            suggestiontags: [], suggestionssource: [], sourcetext: '', tagstext: '', scrollwidth: scrollWidth, reload: false, 
            viewfilter: false, viewevent: false, showevent: true, objectarray:[], csv:true,fsearch: ''};
    },
    onColumnResize: function(firstCol, firstSize, secondCol, secondSize){
        firstCol.width = firstSize
        this.setState({})
    },
    componentDidMount: function(){
        toggle  = $('#list-view').find('.tableview')
        var t2 = document.getElementById('fluid2')
        $(t2).resize(function(){
            this.reloadItem()
        }.bind(this))
        $(document.body).keydown(function(e){
            if ($('input').is(':focus')) {return};
            var obj = $(toggle[0]).find('#'+this.state.idsarray[0]).prevAll('.allevents')
            var obj2 = $(toggle[0]).find('#'+this.state.idsarray[0]).nextAll('.allevents')
            if((e.keyCode == 74 && obj2.length != 0) || (e.keyCode == 40 && obj2.length != 0)){
                var set;
                set  = $(toggle[0]).find('#'+this.state.idsarray[0]).nextAll('.allevents').click()
                var array = []
                array.push($(set).attr('id'))
                window.history.pushState('Page', 'SCOT', '/#/alertgroup/'+$(set).attr('id'))
                $('.container-fluid2').scrollTop(scrolled)
                scrolled = scrolled + $(toggle[0]).find('#'+this.state.idsarray[0]).height()
                this.setState({idsarray: array})
            }
            else if((e.keyCode == 75 && obj.length != 0) || (e.keyCode == 38 && obj.length != 0)){
                var set;
                set  = $(toggle[0]).find('#'+this.state.idsarray[0]).prevAll('.allevents').click()
                var array = []
                array.push($(set).attr('id'))
                window.history.pushState('Page', 'SCOT', '/#/alertgroup/'+$(set).attr('id'))
                $('.container-fluid2').scrollTop(scrolled)
                scrolled = scrolled -  $(toggle[0]).find('#'+this.state.idsarray[0]).height()
                this.setState({idsarray: array})
            } else if (e.keyCode == 70) {
                this.toggleView();
            }
        }.bind(this)) 
        var height = this.state.scrollheight
        var array = []
        if(this.props.supertable !== undefined){
            if(this.props.supertable.length > 0){
                array = this.props.supertable
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
        Store.storeKey('activealertgroup')
        Store.addChangeListener(this.reloadactive)
        //List View code
        $.ajax({
	        type: 'GET',
	        url: '/scot/api/v2/alertgroup',
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
                    else if (num == 'sources' || num == 'source'){
                        finalarray[key]["sources"] = item
                    }
                    else if (num == 'tags' || num == 'tag'){
                        finalarray[key]["tags"] = item
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
        //Elastic Search Code
        if(this.props.isalert != null){
            if(this.props.isalert != ''){
                highlight = true
                $.ajax({
                    type: 'get',
                    url: '/scot/api/v2/alert/'+array[0]
                }).success(function(response1){
                    var newresponse = response1
                    array = []
                    array.push(newresponse.alertgroup)
                    this.setState({scrollheight: height, idsarray: array, objectarray: finalarray,totalcount: datasource.totalRecordCount})
        }.bind(this))
        }
        else {
                    highlight = false
                    this.setState({scrollheight: height, idsarray: array, objectarray: finalarray,totalcount: datasource.totalRecordCount})
        }
        }
        }.bind(this)) 
    },
    
    //Callback for AMQ updates
    reloadactive: function(){    
        var notification = this.refs.notificationSystem
        if(activemqwho != 'scot-alerts' && activemqwho != 'scot-admin' && whoami != activemqwho && notification != undefined && activemqwho != "" &&  activemqwho != 'api'){
            notification.addNotification({
                message: activemqwho + activemqmessage + activemqid,
                level: 'info',
                autoDismiss: 15,
                action: activemqstate != 'delete' ? {
                    label: 'View',
                    callback: function(){
                        if(activemqtype == 'entry' || activemqtype == 'alert'){
                            activemqid = activemqsetentry
                            activemqtype = activemqsetentrytype
                        } 
                        window.open('#/' + activemqtype + '/' + activemqid)
                    }
                } : null
            })
            savedid = activemqid
        }  
        this.getNewData({page: defaultpage, limit: pageSize}) 
    },

    //This is used for the dragging portrait and landscape views
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
        //portrait
        if(this.state.display == 'flex'){
        fluidheight = $(window).height() - 108
            $('.container-fluid2').css('height', height)
            $('.container-fluid2').css('max-height', height)
            //$('.container-fluid2').css('max-width', '915px')
            if(e != null){
                width = e.clientX
                $('.container-fluid2').css('width', e.clientX)
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
        //landscape
        else {
        //    $('.container-fluid2').css('height', this.state.idsarray.length != 0 ? '300px' : height)
              $('.container-fluid2').css('width', '100%')
              if(e != null){
                $('.container-fluid2').css('height', e.clientY)
            }
        }
    },
    launchEvent: function(array){
        stage = true
        if(this.state.display == 'block'){
            this.state.scrollheight = '300px'
        }
        this.setState({alertPreSelectedId: 0, scrollheight: this.state.scrollheight, idsarray:array})

    },
    render: function() {
        var styles;
	    if(this.state.viewfilter){
	        styles = {'border-radius': '0px'}
	    }
	    else {
	        styles = {'border-radius': '0px'}
	    }
	    $('.z-table').each(function(key, value){
	        $(value).find('.z-cell').each(function(x,y){
	            $(y).css('overflow', 'auto')
	        })
	    })

        setTimeout(function(){
            $('.allevents').find('.table-row').each(function(key, value){
                $(value).find('.colorstatus').each(function(x,y){
                    if($(y).text() == 'open'){
                        $(y).css('color', 'red')
                    }
                    else if($(y).text() == 'closed'){
                        $(y).css('color', 'green')
                    }
        else if($(y).text()  == 'promoted'){
            $(y).css('color', 'orange')
        }
        })
        })

        }.bind(this),100)
        window.addEventListener('resize',this.reloadItem);
        return (
            React.createElement("div", {className: "allComponents", style: {'margin-left': '17px'}}, 
                React.createElement('div', null, 
                    !this.state.mute ? React.createElement(Notificationactivemq, {ref: 'notificationSystem'}) :null ), 
                        React.createElement("div", {className: 'entry-header-info-null', style: {'padding-bottom': '55px',width:'100%'}}, 
                        React.createElement("div", {style: {top: '1px', 'margin-left': '10px', float:'left', 'text-align':'center', position: 'absolute'}}, 
                        React.createElement('h2', {style: {'font-size': '30px'}}, 'Alertgroup')), 
                        React.createElement("div", {style: {float: 'right', right: '100px', left: '50px','text-align': 'center', position: 'absolute', top: '9px'}}, 
                        React.createElement('h2', {style: {'font-size': '19px'}}, 'OUO')), 
                        React.createElement(Search, null)),

                        React.createElement('div', {className: 'mainview', style: {display: this.state.display == 'block' ? 'block' : 'flex'}},
                        React.createElement('div', {style:{display: 'block'}},
                        React.createElement('div', {style: {display: 'inline-flex'}},
                        width < 645 ?
                        React.createElement('div', {className:'buttonmenu'},
                        React.createElement(SplitButton, {bsSize: 'small' , title: 'Select'},
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
            React.createElement('div', {className: 'eventwidth', style: {display:this.state.display}},
            React.createElement('div', {style: {width: this.state.differentviews},id:this.state.display == 'block' ? 'old-list-view' : 'list-view'},  
            React.createElement('div', {className: 'tableview',style:{display: 'flex'}},
                React.createElement("div", {id: 'fluid2', className: "container-fluid2", style: {/*'max-width': '915px',*//*'min-width': '650px',*/ width:this.state.scrollwidth, 'max-height': this.state.maxheight, 'margin-left': '0px',height: this.state.scrollheight, 'overflow': 'hidden','padding-left':'5px', display:'flex', flexFlow: 'column'}}, 
                    React.createElement("div", {className: "table-row header " + this.state.classname[0]},
                        React.createElement("div", {className: "wrapper attributes " + this.state.classname[1]}, 
                        React.createElement('div', {className: 'wrapper status-owner-severity'},
                        React.createElement('div', {className: 'wrapper status-owner ' + this.state.sizearray[1]}, 
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
                        React.createElement('div',{style: {width: '87px'},className: 'column index'}, 'ID'), this.state.idarrow[0] != 0 ? React.createElement('div', {className:'arrow-up', style:{ width: 0, height: 0, 'border-left': this.state.idarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-right': this.state.idarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-bottom': this.state.idarrow[1] == -1 ? '5px solid black' : null, 'border-top': this.state.idarrow[1] == -1 ? null : '5px solid black', top: '9px', right: '30px', position: 'relative'}}) : null))), 
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
                        this.state.statusarrow[0] != 0 ? React.createElement('div', {className:'arrow-up', style:{ width: 0, height: 0, 'border-left': this.state.statusarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-right': this.state.statusarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-bottom': this.state.statusarrow[1] == -1 ? '5px solid black' : null, 'border-top': this.state.statusarrow[1] == -1 ? null : '5px solid black', top: '9px', right: '40px', position: 'relative'}}) : null)
                         ))
                         )),

                        React.createElement("div", {className: "wrapper title-comment-module-reporter"}, 
                        React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, 
                        React.createElement(OverlayTrigger, {trigger:['click','focus'], placement:'bottom', ref: 'myPopOversubject', rootClose: true, overlay: React.createElement(Popover, null, 
                        React.createElement('div', {className: 'Filter and Sort', id: 'subjectheader'}, React.createElement('div',
                        {style: {display: 'inline-flex'}}, React.createElement('div', null, 'Subject'), React.createElement('div', 
                        {style:{'padding-left': '80px'}}, 'Sort'), 
                        React.createElement('btn-group', null, 
                        React.createElement('button', {style: {height:'5px'},value: 'subject', id: -1, onClick: this.handlesort, className: 'sort glyphicon glyphicon-triangle-top'}),
                        React.createElement('button', {className: 'glyphicon glyphicon-triangle-bottom sort', value: 'subject', id: 1, onClick: this.handlesort, style:{height:'5px'}}))),
                        React.createElement('input', {autoFocus: true, id: 'subject',onKeyUp: this.filterUp, defaultValue:this.state.subjecttext, placeholder: 'Search', style: {background: 'white', width: '200px'}, type:'text', className:'subjectinput'}), 
                        React.createElement('btn-group', null, 
                        React.createElement('button', {className:'btn btn-default clear', value: 'subject', onClick: this.filterclear}, 'Clear'),
                        React.createElement('button', {className:'btn btn-default filter', value: 'subject', onClick: this.handlefilter}, 'Filter')))
                        )},
                            React.createElement("div", {className: "wrapper title-comment"},

                            React.createElement('div', {style: {display: 'flex'}},
                            React.createElement("div", {className: "column title"}, "Subject"),
                            this.state.subjectarrow[0] != 0 ? React.createElement('div', {className:'arrow-up', style:{ width: 0, height: 0, 'border-left': this.state.subjectarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-right': this.state.subjectarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-bottom': this.state.subjectarrow[1] == -1 ? '5px solid black' : null, 'border-top': this.state.subjectarrow[1] == -1 ? null : '5px solid black', top: '9px', right: '120px', position: 'relative'}}) : null)))

                            )),

                        React.createElement("div", {className: "wrapper dates " + this.state.sizearray[0]}, 
                        React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, React.createElement(OverlayTrigger, {trigger:['click','focus'], placement:'bottom', ref: 'myPopOvercreated',rootClose: true, overlay: React.createElement(Popover, null, 
                        React.createElement('div', {className: 'Filter and Sort', id: 'createdheader'}, React.createElement('div',
                        {style: {display: 'inline-flex'}}, React.createElement('div', null, 'Created'), React.createElement('div', 
                        {style:{'padding-left': '80px'}}, 'Sort'), 
                        React.createElement('btn-group', null, 
                        React.createElement('button', {style: {height:'5px'}, onClick: this.handlesort, className: 'sort glyphicon glyphicon-triangle-top', value: 'created', id: -1}),
                        React.createElement('button', {value: 'created', id: 1, onClick: this.handlesort, className: 'sort glyphicon glyphicon-triangle-bottom', style:{height:'5px'}}))),                        
                        React.createElement('div', {onKeyUp: this.filterUp, id: 'created', className: 'Dates'},  
                        React.createElement(DateRangePicker, {numberOfCalendars: 2, selectionType:"range", showLegend: true, onSelect:this.handleSelect ,singleDateRange: true}),
                        React.createElement("div",{className: 'dates'}, React.createElement('input', {className: "StartDate",placeholder: 'Start Date', value: this.state.startepoch, readOnly:true}), 
                          React.createElement('input', {className: "EndDate",placeholder:'End Date', value: this.state.endepoch, readOnly:true}))),
                        React.createElement('btn-group', null, 
                        React.createElement('button', {className:'btn btn-default clear',  value: 'created',onClick: this.filterclear}, 'Clear'),
                        React.createElement('button', {className:'btn btn-default filter', value: 'created', onClick: this.handlefilter}, 'Filter')))
                        )},
                        React.createElement('div', {style: {display: 'flex'}},
                        React.createElement("div", {className: "column date"}, "Created"),
                        this.state.createdarrow[0] != 0 ? React.createElement('div', {className:'arrow-up', style:{ width: 0, height: 0, 'border-left': this.state.createdarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-right': this.state.createdarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-bottom': this.state.createdarrow[1] == -1 ? '5px solid black' : null, 'border-top': this.state.createdarrow[1] == -1 ? null : '5px solid black', top: '9px', right: '45px', position: 'relative'}}) : null)
                        ))),
                         React.createElement('div', {className:'wrapper module-reporter '+this.state.sizearray[2] + ' ' + this.state.classname[2]},
                         React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, React.createElement(OverlayTrigger, {trigger:['click','focus'], placement:'bottom', ref: 'myPopOversource', rootClose: true, overlay: React.createElement(Popover, null, 
                        React.createElement('div', {className: 'Filter and Sort', id: 'sourceheader'}, React.createElement('div',
                        {style: {display: 'inline-flex'}}, React.createElement('div', null, 'Source'), React.createElement('div', 
                        {style:{'padding-left': '100px'}}, 'Sort'), 
                        React.createElement('btn-group', null, 
                        React.createElement('button', {style: {height:'5px'}, onClick: this.handlesort, value: 'source', id: -1, className: 'sort glyphicon glyphicon-triangle-top'}),
                        React.createElement('button', {onClick: this.handlesort, value: 'source', id: 1, className: 'sort glyphicon glyphicon-triangle-bottom', style:{height:'5px'}}))),

                        React.createElement("div", {style:{overflow: 'auto', width: '100%', height: '100%'},className: "sources"},
                        React.createElement(Source, {handleInputChange: this.handleInputChange, minQueryLength:1,tags: this.state.sourcetags, suggestions: this.state.suggestionssource, handleDelete: this.handleDelete, handleAddition: this.handleAddition})), 
                        React.createElement('btn-group', null, 
                        React.createElement('button', {className:'btn btn-default clear',  value: 'source', onClick: this.filterclear}, 'Clear'),
                        React.createElement('button', {className:'btn btn-default filter', value: 'source', onClick: this.handlefilter}, 'Filter')))
                        )},
                          React.createElement('div', {style: {display: 'flex'}},
                          React.createElement("div", {className: "column module"}, "Source"),

                            this.state.sourcearrow[0] != 0 ? React.createElement('div', {className:'arrow-up', style:{ width: 0, height: 0, 'border-left': this.state.sourcearrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-right': this.state.sourcearrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-bottom': this.state.sourcearrow[1] == -1 ? '5px solid black' : null, 'border-top': this.state.sourcearrow[1] == -1 ? null : '5px solid black', top: '9px', right: '55px', position: 'relative'}}) : null)
                        )),
                        React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, React.createElement(OverlayTrigger, {trigger:['click','focus'], placement:'bottom', ref: 'myPopOvertags', rootClose: true, overlay: React.createElement(Popover, null, 
                        React.createElement('div', {className: 'Filter and Sort', id: 'tagsheader'}, React.createElement('div',
                        {style: {display: 'inline-flex'}}, React.createElement('div', null, 'Tags'), React.createElement('div', 
                        {style:{'padding-left': '100px'}}, 'Sort'), 
                        React.createElement('btn-group', null, 
                        React.createElement('button', {style: {height:'5px'}, onClick: this.handlesort, value: 'tags', id: -1, className: 'sort glyphicon glyphicon-triangle-top'}),
                        React.createElement('button', {onClick: this.handlesort, value: 'tags', id: 1, className: 'sort glyphicon glyphicon-triangle-bottom', style:{height:'5px'}}))),
  


                        React.createElement("div", {style:{overflow: 'auto', width: '100%', height: '100%'},className: "tags"},
                        React.createElement(Tags, {handleInputChange: this.handleInputChangefortag, minQueryLength:1,tags: this.state.tags, suggestions: this.state.suggestiontags, handleDelete: this.handleDeletefortag, handleAddition: this.handleAdditionfortag})),  
                        React.createElement('btn-group', null, 
                        React.createElement('button', {className:'btn btn-default clear',  value: 'tags', onClick: this.filterclear}, 'Clear'),
                        React.createElement('button', {className:'btn btn-default filter', value: 'tags', onClick: this.handlefilter}, 'Filter')))
                        )},

                            React.createElement('div', {style: {display: 'flex'}},
                            React.createElement("div", {className: "column reporter"}, "Tags"),

                            this.state.tagsarrow[0] != 0 ? React.createElement('div', {className:'arrow-up', style:{ width: 0, height: 0, 'border-left': this.state.tagsarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-right': this.state.tagsarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-bottom': this.state.tagsarrow[1] == -1 ? '5px solid black' : null, 'border-top': this.state.tagsarrow[1] == -1 ? null : '5px solid black', top: '9px', right: '50px', position: 'relative'}}) : null)
                        ))),

                        React.createElement('div', {className: 'wrapper status-owner-severity'},
                        React.createElement('div', {className: 'wrapper status-owner ' + this.state.sizearray[1] + ' ' + this.state.classname[3]},          
                        React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, React.createElement(OverlayTrigger, {trigger:['click','focus'], placement:'bottom', ref: 'myPopOverviews', rootClose: true, overlay: React.createElement(Popover, null, 
                        React.createElement('div', {className: 'Filter and Sort', id: 'viewsheader'}, React.createElement('div',
                        {style: {display: 'inline-flex'}}, React.createElement('div', null, 'Views'), React.createElement('div', 
                        {style:{'padding-left': '100px'}}, 'Sort'), 
                        React.createElement('btn-group', null, 
                        React.createElement('button', {style: {height:'5px'}, onClick: this.handlesort, value: 'views', id: -1, className: 'sort glyphicon glyphicon-triangle-top'}),
                        React.createElement('button', {onClick: this.handlesort, value: 'views', id: 1, className: 'sort glyphicon glyphicon-triangle-bottom', style:{height:'5px'}}))),
                        React.createElement('input', {autoFocus: true, id: 'views', onKeyUp: this.filterUp, defaultValue: this.state.viewstext, placeholder: 'Search', style: {background: 'white', width: '200px'}, type:'text', className:'viewsinput'}), 
                        React.createElement('btn-group', null, 
                        React.createElement('button', {className:'btn btn-default clear',  value: 'views', onClick: this.filterclear}, 'Clear'),
                        React.createElement('button', {className:'btn btn-default filter', value: 'views', onClick: this.handlefilter}, 'Filter')))
                        )},
                    
                            React.createElement('div', {style: {display: 'flex'}},
                            React.createElement("div", {className: "column owner"}, "Views"),

                            this.state.viewsarrow[0] != 0 ? React.createElement('div', {className:'arrow-up', style:{ width: 0, height: 0, 'border-left': this.state.viewsarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-right': this.state.viewsarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-bottom': this.state.viewsarrow[1] == -1 ? '5px solid black' : null, 'border-top': this.state.viewsarrow[1] == -1 ? null : '5px solid black', top: '9px', right: '50px', position: 'relative'}}) : null)))
                    ))
                    )
                    ), 
                    React.createElement('div', {id: 'listpane', style:{overflowY:'auto'}},
                    this.state.objectarray.map((value) => React.createElement('div', {className:'allevents', id: value.id}, 
                       /* React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, React.createElement(OverlayTrigger, {trigger:['hover', 'focus'], placement:'top', positionTop: 50, title: value.id, style: {overflow: 'auto'}, overlay: React.createElement(Popover, null, 
                        React.createElement('div', null,
                        React.createElement('div', {style: {display:'flex'}}, React.createElement('div', {style: {'font-weight': 'bold'}}, 'ID:'),
                        React.createElement('div', null, value.id)),
                    
                        React.createElement('div', {style: {display:'flex'}}, React.createElement('div', {style:{'font-weight': 'bold'}}, 'Created:  '),
                        React.createElement('div', null, value.created)), React.createElement('div', {style: {display:'flex'}},
                        React.createElement('div', {style: {'font-weight': 'bold'}}, 'Subject:  '), React.createElement('div', null, value.subject)),
                        React.createElement('div', {style: {display: 'flex'}},
                        React.createElement('div', {style: {'font-weight': 'bold'}}, 'Status:  '), React.createElement('div', null, value.status)),
                        React.createElement('div', {style: {display:'inline-flex'}},
                        React.createElement('div', {style: {'font-weight': 'bold'}}, 'Sources:  '), React.createElement('div', null, value.sources)),
                        React.createElement('div', {style: {display:'flex'}},
                        React.createElement('div', {style: {'font-weight':'bold'}}, 'Tags:  '), React.createElement('div', null, value.tags)),
                        React.createElement('div', {style: {display:'flex'}},
                        React.createElement('div', {style: {'font-weight': 'bold'}}, 'Views:  '), React.createElement('div', null, value.views))
                        ))},*/ 
                        React.createElement("div", {style: {background: this.state.idsarray[0] == value.id ? this.state.blue : null},onClick: this.clickable, className: value.classname + ' ' + this.state.classname[0], id: value.id}, 
                        React.createElement("div", {className: "wrapper attributes " + this.state.classname[1]},
                        React.createElement('div', {className: 'wrapper status-owner-severity'},
                        React.createElement('div', {className: 'wrapper status-owner '+ this.state.sizearray[1] + ' ' + this.state.classname[3]}, 
                            React.createElement("div", {style: {width: '100px'}, className: 'column index'}, value.id),
                            React.createElement("div", {className: "column owner colorstatus"}, 
                            React.createElement(Button, {className: value.status == 'open' ? 'alertgroup_open' : value.status == 'closed' ? 'alertgroup_closed' : 'alertgroup_promoted', bsSize: "xsmall", bsStyle: value.status == 'open' ? 'danger' : value.status == 'closed' ? 'success' : 'default'}, 
                            React.createElement("span", null, 
                            React.createElement("span", null, value.open_count), " / ", 
                            React.createElement("span", null, value.closed_count), " / ",   
                           React.createElement("span", null, value.promoted_count)))  
                            ))),
                        React.createElement("div", {className: "wrapper title-comment-module-reporter"}, 
                            React.createElement("div", {className: "wrapper title-comment"},  
                            React.createElement("div", {className: "column title"}, value.subject) 
                            )
                        ),     
                        React.createElement("div", {className: "wrapper dates "+ this.state.sizearray[0]}, 
                            React.createElement("div", {className: "column date"}, value.created)), 
                        React.createElement('div', {className:'wrapper module-reporter '+ this.state.sizearray[2] + ' ' + this.state.classname[2]},
                        React.createElement("div", {className: "column module"}, value.sources.join(',')), 
                        React.createElement("div", {className: "column reporter"}, value.tags.join(','))), 
                        React.createElement('div', {className: 'wrapper status-owner-severity'},
                            React.createElement('div', {className: 'wrapper status-owner '+ this.state.sizearray[1] + ' ' + this.state.classname[3]},    
                            React.createElement("div", {className: "column owner"}, value.views == null ? 0 : value.views)
                            ) 
                        )
                        )
                    )
                    //)
                    //)
                    ))))), 

                        !this.state.splitter ? React.createElement('div', {onMouseDown: this.dragdiv, className: 'splitter', style: {display: 'block', height: '5px', 'background-color': 'black', 'border-top': '1px solid #AAA', 'border-bottom': '1px solid #AAA', cursor: 'nwse-resize', overflow: 'hidden'}}):null, 
                        React.createElement(Page, {paginationToolbarProps: { pageSizes: [5, 20, 50, 100]}, pagefunction: this.getNewData, defaultPageSize: 50, count: this.state.totalcount, pagination: true})))) , 
                        this.state.splitter ?
                        React.createElement('div' , null,
                        React.createElement('div', {onMouseDown: this.dragdiv, className: 'splitter', style: {display: 'block', width: '5px', height: fluidheight, 'background-color': 'black', 'border-top': '1px solid #AAA', 'border-bottom': '1px solid #AAA', cursor: 'nwse-resize', overflow: 'hidden'}})) : null,


                        stage ? 
                        React.createElement(SelectedContainer, {alertPreSelectedId: highlight ? this.props.supertable[0] : 0, height: height - 220,ids: this.state.idsarray, type: 'alertgroup'}) : null),
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
                        React.createElement(SelectedContainer, {alertPreSelectedId: highlight ? this.props.supertable[0] : 0, height: height - 220,ids: this.state.idsarray, type: 'alertgroup'})
        )) : React.createElement('div', null) 

        ));
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
        document.onmousemove = this.reloadItem
        document.onmouseup  = this.stopdrag
    },
    toggleView: function(){
        if(this.state.idsarray.length != 0 && stage == true){
            stage = false
            $('.mainview').hide()
            this.setState({alldetail:false, containerdisplay: 'inherit'})
        } else {
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
    Portrait: function(){
        document.onmousemove = null
        document.onmousedown = null
        document.onmouseup = null
        stage = true
        $('.container-fluid2').css('width', '650px')
        width = 650
        $('.paging').css('width', width)
        $('.splitter').css('width', '5px')
        $('.mainview').show()
        var array = []
        array = ['dates-small', 'status-owner-small', 'module-reporter-small']
                        this.setState({splitter: true, display: 'flex', alldetail: true, scrollheight: $(window).height() - 170, maxheight: $(window).height() - 170, resize: 'horizontal',differentviews: '',
                        maxwidth: '', minwidth: '',scrollwidth: '650px', sizearray: array})
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
        this.setState({classname: [' ', ' ', ' ', ' '],splitter: false, display: 'block', maxheight: '', alldetail: true, differentviews: '100%',
        scrollheight: this.state.idsarray.length != 0 ? '300px' : $(window).height()  - 170, maxwidth: '', minwidth: '',scrollwidth: '100%', sizearray: array, resize: 'vertical'})

    },
    clearAll: function(){
        sortarray['id'] = -1
        filter = {}
        this.setState({tags: [], sourcetags: [], startepoch: '', endepoch: '', idtext: '',
            upstartepoch: '', upendepoch: '', statustext: '', subjecttext: '', entriestext: '', ownertext: '',
            viewstext: ''})
            this.getNewData({page: 0, limit: pageSize})
    },
    getTags:  function(getColumn){
        var array = []
        var values;
        if(getColumn == "Sources"){
            for(var i = 0; i<this.state.sourcetags.length; i++){
                array.push(this.state.sourcetags[i].text)
            }
        }
        else
        {
            for(var i = 0; i<this.state.tags.length; i++){
                array.push(this.state.tags[i].text)
            }
        }
        values = array.join(',');
        values = values.replace("+", "");
        return values.split(',')

    }, 
    handleInputChangefortag: function(input){
         var array = []
         $.ajax({
               type: 'GET',
               url: '/scot/api/v2/ac/tag/'+input
           }).success(function(response){
               $.each(response.records, function(key,value){
                    array.push(value.value)
            })
             this.setState({suggestiontags: array})
         }.bind(this))
    },
    handleAdditionfortag: function(tag){
        var tags = []
        tags = this.state.tags;
        tags.push({
            id: tags.length +1,
            text: tag
         });
        this.setState({tags:tags})
    },
    handleDeletefortag: function(i) {
        var tags;
        tags = this.state.tags
        tags.splice(i,1)
        this.setState({tags: tags})
    },  

    handleInputChange: function(input){
         var array = []
         $.ajax({
               type: 'GET',
               url: '/scot/api/v2/ac/source/'+input
           }).success(function(response){
               $.each(response.records, function(key,value){
                    array.push(value.value)
            })
             this.setState({suggestionssource: array})
         }.bind(this))
    },
    handleAddition: function(tag){
        var tags = []
        tags = this.state.sourcetags;
        tags.push({
            id: tags.length +1,
            text: tag
         });
        this.setState({sourcetags:tags})
    },
    handleDelete: function(i) {
        var tags;
        tags = this.state.sourcetags
        tags.splice(i,1)
        this.setState({sourcetags: tags})
    }, 
    handleSelect: function(range, pick){
        start = range['start']
        var month = start['_i'].getMonth()+1
        var day   = start['_i'].getDate()
        var StartDate = month+"/"+day+"/"+start['_i'].getFullYear()
        end = range['end']
        var month = end['_i'].getMonth()+1
        var day   = end['_i'].getDate()
        var EndDate = month+"/"+day+"/"+end['_i'].getFullYear()

        start = StartDate.split('/')
        start = new Date(start[2], start[0] - 1, start[1])
        end   = EndDate.split('/')
        end   = new Date(end[2],end[0]-1, end[1], 23,59,59,99);

        start = Math.round(start.getTime()/1000)
        end   = Math.round(end.getTime()/1000)
        this.setState({startepoch: StartDate, endepoch: EndDate})
    
    },
    filterUp: function(v){
        if(v.keyCode == 13){
            if($($(v.currentTarget).find('.idinput').context).attr('id') == 'id'){
                filter['id'] = [$('.idinput').val()]
                this.refs.myPopOverid.hide()
                this.setState({idtext: $('.idinput').val()})
            }
            else if($($(v.currentTarget).find('.statusinput').context).attr('id') == 'status'){
                filter['status'] = $('.statusinput').val()
                this.refs.myPopOverstatus.hide()
                this.setState({statustext: $('.statusinput').val()})
            }
            else if($($(v.currentTarget).find('.subjectinput').context).attr('id') == 'subject'){
                filter['subject'] = $('.subjectinput').val()
                this.refs.myPopOversubject.hide()
                this.setState({subjecttext: $('.subjectinput').val()})
            }
            else if($($(v.currentTarget).find('.createdinput').context).attr('id') == 'created'){
                filter['created'] = {begin:start, end:end}
            }
            else if($($(v.currentTarget).find('.tagsinput').context).attr('id') == 'tags'){
   
                //             filter['tags'] = $('.tagsinput').val()
                //             this.setState({tagstext: $('.tagsinput').val()})
            }
            else if($($(v.currentTarget).find('.sourceinput').context).attr('id') == 'source'){
                //              filter['source'] = $('.sourceinput').val()
                //              this.setState({sourcetext: $('.sourceinput').val()})
            }
            else if($($(v.currentTarget).find('.viewsinput').context).attr('id') == 'views'){
                filter['views'] = [$('.viewsinput').val()]
                this.refs.myPopOverviews.hide()
                this.setState({viewstext: $('.viewsinput').val()})
            }

            this.getNewData({page: 0, limit: pageSize})
        }
    },
    clearNote: function(){
        if(this.state.mute){
            this.setState({mute: false})
        }
        else {
            this.setState({mute: true})
        }
    },
    clickable: function(v){
        $('#list-view').find('.container-fluid2').focus() 
        $('#'+$(v.currentTarget).find('.index').text()).find('.table-row').each(function(x,y){
            var array = []
            array.push($(y).attr('id'))
            colorrow.push($(y).attr('id'))
            window.history.pushState('Page', 'SCOT', '/#/alertgroup/'+$(y).attr('id'))  
            this.launchEvent(array)
        }.bind(this))
        scrolled = $('.container-fluid2').scrollTop() 
    },

    handlePageChange: function(pageNumber){
        this.getNewData(pageNumber)
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
	        url: '/scot/api/v2/alertgroup',
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
                    else if (num == 'sources' || num == 'source'){
                        newarray[key]["sources"] = item
                    }
                    else if (num == 'tags' || num == 'tag'){
                        newarray[key]["tags"] = item
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
            sortarray['status'] = Number($($(v.currentTarget).find('.sort').context).attr('id')) 
            this.refs.myPopOverstatus.hide()
            this.setState({statusarrow: [Number($($(v.currentTarget).find('.sort').context).attr('id'))
, Number($($(v.currentTarget).find('.sort').context).attr('id'))]})
        }
        else if($($(v.currentTarget).find('.sort').context).attr('value') == 'subject'){
            sortarray['subject'] = Number($($(v.currentTarget).find('.sort').context).attr('id')) 
            this.refs.myPopOversubject.hide()
            this.setState({subjectarrow: [Number($($(v.currentTarget).find('.sort').context).attr('id'))
, Number($($(v.currentTarget).find('.sort').context).attr('id'))]})
        }
        else if($($(v.currentTarget).find('.sort').context).attr('value') == 'created'){
            sortarray['created'] = Number($($(v.currentTarget).find('.sort').context).attr('id')) 
            this.refs.myPopOvercreated.hide()
            this.setState({createdarrow: [Number($($(v.currentTarget).find('.sort').context).attr('id'))
, Number($($(v.currentTarget).find('.sort').context).attr('id'))]})
        }
        else if($($(v.currentTarget).find('.sort').context).attr('value') == 'views'){
            sortarray['views'] = Number($($(v.currentTarget).find('.sort').context).attr('id')) 
            this.refs.myPopOverviews.hide()
            this.setState({viewsarrow: [Number($($(v.currentTarget).find('.sort').context).attr('id'))
, Number($($(v.currentTarget).find('.sort').context).attr('id'))]})
        }
        else if($($(v.currentTarget).find('.sort').context).attr('value') == 'source'){
            sortarray['source'] = Number($($(v.currentTarget).find('.sort').context).attr('id')) 
            this.refs.myPopOversource.hide()
            this.setState({sourcearrow: [Number($($(v.currentTarget).find('.sort').context).attr('id'))
, Number($($(v.currentTarget).find('.sort').context).attr('id'))]})
        }
        else if($($(v.currentTarget).find('.sort').context).attr('value') == 'tags'){
            sortarray['tags'] = Number($($(v.currentTarget).find('.sort').context).attr('id')) 
            this.refs.myPopOvertags.hide()
            this.setState({tagsarrow: [Number($($(v.currentTarget).find('.sort').context).attr('id'))
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
        else if($($(v.currentTarget).find('.clear').context).attr('value') == 'subject'){
            delete filter.subject
            this.refs.myPopOversubject.hide()
            this.setState({subjecttext: ''})
        }
        else if($($(v.currentTarget).find('.clear').context).attr('value') == 'created'){
            delete filter.created
            this.refs.myPopOvercreated.hide()
            this.setState({startepoch: '', endepoch: ''})
        }
       else if($($(v.currentTarget).find('.clear').context).attr('value') == 'tags'){
            delete filter.tags
            this.refs.myPopOvertags.hide()
            this.setState({tags: []})
        }
       else if($($(v.currentTarget).find('.clear').context).attr('value') == 'source'){
            delete filter.source
            this.refs.myPopOversource.hide()
            this.setState({sourcetags: []})
        }
       else if($($(v.currentTarget).find('.clear').context).attr('value') == 'updated'){
            delete filter.updated
            this.refs.myPopOvercreated.hide()
            this.setState({upstartepoch: '', upendepoch: ''})
        }
       else if($($(v.currentTarget).find('.clear').context).attr('value') == 'views'){
            delete filter.views
            this.refs.myPopOverviews.hide()
            this.setState({viewstext: ''})
        }
 
        this.getNewData({page:0, limit: pageSize})
    },

    handlefilter: function(v){
        if($($(v.currentTarget).find('.filter').context).attr('value') == 'id'){
            filter['id'] = [$('.idinput').val()]
            this.refs.myPopOverid.hide()
            this.setState({idtext: $('.idinput').val()})
        }
        else if($($(v.currentTarget).find('.filter').context).attr('value') == 'status'){
            filter['status'] = $('.statusinput').val()
            this.refs.myPopOverstatus.hide()
            this.setState({statustext: $('.statusinput').val()})
        }
        else if($($(v.currentTarget).find('.filter').context).attr('value') == 'subject'){
            filter['subject'] = $('.subjectinput').val()
            this.refs.myPopOversubject.hide()
            this.setState({subjecttext: $('.subjectinput').val()})
        }
        else if($($(v.currentTarget).find('.filter').context).attr('value') == 'created'){
            filter['created'] = {begin:start, end:end}
            this.refs.myPopOvercreated.hide()
        }
        else if($($(v.currentTarget).find('.filter').context).attr('value') == 'tags'){
            var array = this.getTags('tags')
            filter['tags'] = array
            this.refs.myPopOvertags.hide()
        }
        else if($($(v.currentTarget).find('.filter').context).attr('value') == 'source'){
            var array = this.getTags('Sources')
            filter['source'] = array
            this.refs.myPopOversource.hide()
        }
        else if($($(v.currentTarget).find('.filter').context).attr('value') == 'views'){
            filter['views'] = [$('.viewsinput').val()]
            this.refs.myPopOverviews.hide()
            this.setState({viewstext: $('.viewsinput').val()})
        }

        this.getNewData({page: 0, limit: pageSize})
    }
    
});

