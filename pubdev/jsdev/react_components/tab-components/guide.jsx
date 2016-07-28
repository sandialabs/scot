'use strict';

var React                   = require('react')
var SelectedContainer       = require('../entry/selected_container.jsx')
var Notificationactivemq    = require('../../../node_modules/react-notification-system')
var Search                  = require('../components/esearch.jsx')
var Store                   = require('../activemq/store.jsx')
var Button                  = require('react-bootstrap/lib/Button.js');
var MenuItem                = require('react-bootstrap/lib/MenuItem.js');
var SplitButton             = require('react-bootstrap/lib/SplitButton.js');
var Page                    = require('../components/paging.jsx')
var Popover                 = require('react-bootstrap/lib/Popover')
var OverlayTrigger          = require('react-bootstrap/lib/OverlayTrigger')
var ButtonToolbar           = require('react-bootstrap/lib/ButtonToolbar')
var DateRangePicker         = require('../../../node_modules/react-daterange-picker')
var Source                  = require('react-tag-input-tags/react-tag-input').WithContext
var Tags                    = require('react-tag-input').WithContext
var SORT_INFO;
var colsort = "id"
var start;
var toggle
var size = 645 
var scrolled = 23
var end;
var valuesort = -1
var SELECTED_ID = {}
var filter = {}
var sortarray = {}
var defaultpage = 1
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
var columns = ['id', 'Applies_to']

module.exports = React.createClass({

    getInitialState: function(){
        var scrollHeight = $(window).height() - 170
        var scrollWidth  = '650px'  
        width = 650

    return {
            mute: false, resize: 'horizontal', unbold: '', bold: 'bold', white: 'white', blue: '#AEDAFF',
            idtext: '', totalcount: 0, activepage: 0,sizearray: ['dates-orgclass', 'status-owner-orgclass', 'module-reporter-orgclass'],
            pagedisplay: 'inline-flex', idarrow: [-1,-1],subjectarrow: [0, 0],
            subjecttext:'', idsarray: [], scrollheight: scrollHeight, 
            display: 'flex',scrollwidth: scrollWidth, reload: false, 
            differentviews: '',maxwidth: '915px', maxheight: scrollHeight, containerdisplay: 'none',alldetail: true, minwidth: '650px',classname: [' ', ' ',' ', ' '],
            viewfilter: false, viewevent: false, showevent: true, objectarray:[], csv:true,fsearch: ''};
    },

    componentDidMount: function(){
        toggle  = $('#list-view').find('.tableview')
        var t2 = document.getElementById('fluid2')
        $(t2).resize(function(){
            this.reloadItem()
        }.bind(this))
        $('.container-fluid2').keydown(function(e){
            var obj = $(toggle[0]).find('#'+this.state.idsarray[0]).prevAll('.allevents')
            var obj2 = $(toggle[0]).find('#'+this.state.idsarray[0]).nextAll('.allevents')
            if((e.keyCode == 74 && obj2.length != 0) || (e.keyCode == 40 && obj2.length != 0)){
                var set;
                set  = $(toggle[0]).find('#'+this.state.idsarray[0]).nextAll('.allevents').click()
                var array = []
                array.push($(set).attr('id'))
                window.history.pushState('Page', 'SCOT', '/#/guide/'+$(set).attr('id'))
                $('.container-fluid2').scrollTop(scrolled)
                scrolled = scrolled + $(toggle[0]).find('#'+this.state.idsarray[0]).height()
                this.setState({idsarray: array})
            }
            else if((e.keyCode == 75 && obj.length != 0) || (e.keyCode == 38 && obj.length != 0)){
                var set;
                set  = $(toggle[0]).find('#'+this.state.idsarray[0]).prevAll('.allevents').click()
                var array = []
                array.push($(set).attr('id'))
                window.history.pushState('Page', 'SCOT', '/#/guide/'+$(set).attr('id'))
                $('.container-fluid2').scrollTop(scrolled)
                scrolled = scrolled - $(toggle[0]).find('#'+this.state.idsarray[0]).height()
                this.setState({idsarray: array})
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
        Store.storeKey('guidegroup')
        Store.addChangeListener(this.reloadactive)
        $.ajax({
	        type: 'GET',
	        url: '/scot/api/v2/guide',
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
        this.setState({idsarray: array, objectarray: finalarray,scrollheight: height, totalcount: response.totalRecordCount})
        }.bind(this))
    },

    reloadactive: function(){     
        var notification = this.refs.notificationSystem
        if(activemqwho != 'scot-alerts' && activemqwho != 'scot-admin' && activemqwho != whoami && notification != undefined && activemqwho != "" &&  activemqwho != 'api'){
            notification.addNotification({
                message: activemqwho + activemqmessage + activemqid,
                level: 'info',
                autoDismiss: 15,
                action:  activemqstate != 'delete' ? {
                    label: 'View',
                    callback: function(){
                        if(activemqtype == 'entry' || activemqtype == 'alert'){
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
                $('.splitter').css('width', width)
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
                $('.container-fluid2').css('height', e.clientY)
            }
        }
    },
    launchEvent: function(array){
        stage = true
        if(this.state.display == 'block'){
            this.state.scrollheight = '300px'
        }
        this.setState({scrollheight: this.state.scrollheight, idsarray:array})

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
                    !this.state.mute ? React.createElement(Notificationactivemq, {ref: 'notificationSystem'}):null), 
                        React.createElement("div", {className: 'entry-header-info-null', style: {'padding-bottom': '55px',width:'100%'}}, 
                        React.createElement("div", {style: {top: '1px', 'margin-left': '10px', float:'left', 'text-align':'center', position: 'absolute'}}, 
                        React.createElement('h2', {style: {'font-size': '30px'}}, 'Guide')), 
                        React.createElement("div", {style: {float: 'right', right: '100px', left: '50px','text-align': 'center', position: 'absolute', top: '9px'}}, 
                        React.createElement('h2', {style: {'font-size': '19px'}}, 'OUO')), 
                        React.createElement(Search, null)),   

                       React.createElement('div', {className: 'mainview', style: {display: this.state.display == 'block' ? 'block' : 'flex'}},
                        React.createElement('div', {style:{display: 'block'}},
                        React.createElement('div', {style: {display: 'inline-flex'}},
                        width < 645 ?
                        React.createElement('div', {className: 'buttonmenu'},
                        React.createElement(SplitButton, {bsSize: 'small' , title: 'Select'},
                        !this.state.mute ?
                        React.createElement(Button, {eventKey: '1', onClick: this.clearNote, bsSize: 'small'}, 'Mute ', React.createElement('b', null, 'Notifications')): React.createElement(Button , {eventKey: '2', onClick: this.clearNote, bsSize: 'small'}, 'Turn On ', React.createElement('b', null, 'Notifications')),
                        React.createElement(Button, {onClick: this.clearAll, eventKey: '3', bsSize: 'small'}, 'Clear All ', React.createElement('b', null, 'Filters')),
                        React.createElement(Button, {eventKey: '5', bsSize: 'small',onClick: this.exportCSV}, 'Export to ', React.createElement('b', null, 'CSV')))) : /* , !this.state.mute ? React.createElement('button', {className: 'btn btn-default', onClick:this.dismissNote, style: styles}, 'Clear All Notifications') : null */
                        React.createElement('div', {className: 'buttonmenu'},
                        !this.state.mute ?
                        React.createElement(Button, {eventKey: '1', onClick: this.clearNote, bsSize: 'small'}, 'Mute ', React.createElement('b', null, 'Notifications')): React.createElement(Button , {eventKey: '2', onClick: this.clearNote, bsSize: 'small'}, 'Turn On ', React.createElement('b', null, 'Notifications')),
                        React.createElement(Button, {onClick: this.clearAll, eventKey: '3', bsSize: 'small'}, 'Clear All ', React.createElement('b', null, 'Filters')),
                        React.createElement(Button, {eventKey: '5', bsSize: 'small',onClick: this.exportCSV}, 'Export to ', React.createElement('b', null, 'CSV')))
                        ,

                         React.createElement(SplitButton, {bsSize: 'small', title: 'View'},
                         React.createElement(Button, {eventKey: '10', onClick:this.Portrait}, 'Portrait ', React.createElement('b', null, 'View')), React.createElement(Button, {eventKey: '11', onClick:this.Landscap}, 'Landscape ', React.createElement('b', null, 'View')), React.createElement(Button, {eventKey: '3', onClick: this.toggleView}, 'Toggle ', React.createElement('b', null, 'Detail View')))
            ),
            Object.getOwnPropertyNames(filter).length !== 0 ? React.createElement("div", {style: {width: width, color: 'blue', 'text-overflow': 'ellipsis', 'overflow-x': 'auto', 'font-weight': 'bold', 'font-style': 'italic', 'white-space': 'nowrap','padding-left': '5px'}}, 'Filtered: ' + JSON.stringify(filter)) : null,
            React.createElement('div', {className: 'guidewidth', style: {display:this.state.display}},
            React.createElement('div', {id:this.state.display == 'block' ? 'old-list-view' : 'list-view', style: {width: this.state.differentviews}},  
            React.createElement('div', {className: 'tableview',style:{display: 'flex'}},
                React.createElement("div", {className: "container-fluid2", id: 'fluid2', style: {/*'max-width': '915px',*//*'min-width': '650px',*/ width:this.state.scrollwidth, 'max-height': this.state.maxheight, 'margin-left': '0px',height: this.state.scrollheight, 'overflow-y': 'auto', 'overflow-x': 'hidden','padding-left':'5px'}}, 
                    React.createElement("div", {className: "table-row header "+ this.state.classname[0]},
                        React.createElement("div", {className: "wrapper attributes "+ this.state.classname[1]}, 
                        React.createElement('div', {className: 'wrapper status-owner-severity'},
                        React.createElement('div', {className: 'wrapper status-owner '+ this.state.sizearray[1] + ' ' + this.state.classname[3]}, 
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
                        React.createElement('div',{className: 'column index'}, 'ID'), this.state.idarrow[0] != 0 ? React.createElement('div', {className:'arrow-up', style:{ width: 0, height: 0, 'border-left': this.state.idarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-right': this.state.idarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-bottom': this.state.idarrow[1] == -1 ? '5px solid black' : null, 'border-top': this.state.idarrow[1] == -1 ? null : '5px solid black', top: '9px', right: '30px', position: 'relative'}}) : null))))),
                        React.createElement("div", {className: "wrapper title-comment-module-reporter"}, 
                        React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, 
                        React.createElement(OverlayTrigger, {trigger:['click','focus'], placement:'bottom', ref: 'myPopOversubject', rootClose: true, overlay: React.createElement(Popover, null, 
                        React.createElement('div', {className: 'Filter and Sort', id: 'subjectheader'}, React.createElement('div',
                        {style: {display: 'inline-flex'}}, React.createElement('div', null, 'Applies To'), React.createElement('div', 
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
                            React.createElement("div", {className: "column title"}, "Applies To"),
                            this.state.subjectarrow[0] != 0 ? React.createElement('div', {className:'arrow-up', style:{ width: 0, height: 0, 'border-left': this.state.subjectarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-right': this.state.subjectarrow[1] == -1 ? '5px solid transparent' : '5px solid transparent', 'border-bottom': this.state.subjectarrow[1] == -1 ? '5px solid black' : null, 'border-top': this.state.subjectarrow[1] == -1 ? null : '5px solid black', top: '9px', right: '120px', position: 'relative'}}) : null))))) 
                    )
                    ), 

                    React.createElement('div', {id: 'listpane'}, 
                    this.state.objectarray.map((value) => React.createElement('div', {className:'allevents', id: value.id}, 
                        /*React.createElement(ButtonToolbar, {style: {'padding-left': '5px'}}, React.createElement(OverlayTrigger, {trigger:['hover', 'focus'], placement:'top', positionTop: 50, title: value.id, style: {overflow: 'auto'}, overlay: React.createElement(Popover, null, 
                        React.createElement('div', null,
                        React.createElement('div', {style: {display:'flex'}}, React.createElement('div', {style: {'font-weight': 'bold'}}, 'ID:'),
                        React.createElement('div', null, value.id)),
                         React.createElement('div', {style: {display:'flex'}},
                        React.createElement('div', {style: {'font-weight': 'bold'}}, 'Subject:  '), React.createElement('div', null, value.subject))
                        ))},*/
                        React.createElement("div", {style: {background: this.state.idsarray[0] == value.id ? this.state.blue : null},onClick: this.clickable, className: value.classname + ' ' +this.state.classname[0], id: value.id}, 
                        React.createElement("div", {className: "wrapper attributes " + this.state.classname[1]},
                        React.createElement('div', {className: 'wrapper status-owner-severity'},
                        React.createElement('div', {className: 'wrapper status-owner '+ this.state.sizearray[1] + ' ' + this.state.classname[3]}, 
                            React.createElement("div", {className: 'column index'}, value.id))),
                        React.createElement("div", {className: "wrapper title-comment-module-reporter"}, 
                            React.createElement("div", {className: "wrapper title-comment"},  
                            React.createElement("div", {className: "column title"}, value.applies_to[0]) 
                            )
                        )
                        )
                    )
                   // )
                   // )
                    ))))),
                           React.createElement('div', {onMouseDown: this.dragdiv, className: 'splitter', style: {display: 'block', height: '5px', 'background-color': 'black', 'border-top': '1px solid #AAA', 'border-bottom': '1px solid #AAA', cursor: 'nwse-resize', overflow: 'hidden'}}), 
                        React.createElement(Page, {paginationToolbarProps: { pageSizes: [5, 20, 50, 100]}, pagefunction: this.getNewData, defaultPageSize: 50, count: this.state.totalcount, pagination: true})))) , stage ? 
                        React.createElement(SelectedContainer, {height: height - 117,ids: this.state.idsarray, type: 'guide'}) : null) 
,
                        !this.state.alldetail ?
                        React.createElement('div', null,
                        React.createElement('div', {className: 'toggleview'},
                        React.createElement('div', {style: {display:'block'}},
                         React.createElement('div', {style: {display: 'inline-flex'}, className: 'buttonmenu'},
                        !this.state.mute ?
                        React.createElement(Button, {eventKey: '1', onClick: this.clearNote, bsSize: 'small'}, 'Mute ', React.createElement('b', null, 'Notifications')): React.createElement(Button , {eventKey: '2', onClick: this.clearNote, bsSize: 'small'}, 'Turn On ', React.createElement('b', null, 'Notifications')),
                        React.createElement(Button, {onClick: this.clearAll, eventKey: '3', bsSize: 'small'}, 'Clear All ', React.createElement('b', null, 'Filters')),
                        React.createElement(Button, {eventKey: '5', bsSize: 'small',onClick: this.exportCSV}, 'Export to ', React.createElement('b', null, 'CSV'))/* , !this.state.mute ? React.createElement('button', {className: 'btn btn-default', onClick:this.dismissNote, style: styles}, 'Clear All Notifications') : null */,

                         React.createElement(SplitButton, {bsSize: 'small', title: 'View'},
                         React.createElement(Button, {eventKey: '10', onClick:this.Portrait}, 'Portrait ', React.createElement('b', null, 'View')), React.createElement(Button, {eventKey: '11', onClick:this.Landscap}, 'Landscape ', React.createElement('b', null, 'View')), React.createElement(Button, {eventKey: '3', onClick: this.toggleView}, 'Toggle ', React.createElement('b', null, 'Detail View'))))
            ),
                        React.createElement(SelectedContainer, {height: height - 117,ids: this.state.idsarray, type: 'guide'})
        )) : React.createElement('div', null)
        ));
    },
    clearAll: function(){
        sortarray['id'] = -1
        filter = {}
        this.setState({idtext: '',subjecttext: ''})
            this.getNewData({page: 0, limit: pageSize})
    },
    filterUp: function(v){
        if(v.keyCode == 13){
            if($($(v.currentTarget).find('.idinput').context).attr('id') == 'id'){
                filter['id'] = [$('.idinput').val()]
                this.refs.myPopOverid.hide()
                this.setState({idtext: $('.idinput').val()})
            }
            else if($($(v.currentTarget).find('.subjectinput').context).attr('id') == 'subject'){
                filter['applies_to'] = $('.subjectinput').val()
                this.refs.myPopOversubject.hide()
                this.setState({subjecttext: $('.subjectinput').val()})
            }
            this.getNewData({page: 0, limit: pageSize})
        }
    },
    clickable: function(v){
        $('#list-view').find('.container-fluid2').focus() 
        $('#'+$(v.currentTarget).find('.index').text()).find('.table-row').each(function(x,y){
            var array = []
            array.push($(y).attr('id'))
            colorrow.push($(y).attr('id'))
            window.history.pushState('Page', 'SCOT', '/#/guide/'+$(y).attr('id')) 
            this.launchEvent(array)
        }.bind(this))
        scrolled = $('.container-fluid2').scrollTop()
    },

    handlePageChange: function(pageNumber){
        this.getNewData(pageNumber)
    },

    clearNote: function(){
        if(this.state.mute){
            this.setState({mute: false})
        }
        else {
            this.setState({mute: true})
        }
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
	        url: '/scot/api/v2/guide',
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
        else if($($(v.currentTarget).find('.sort').context).attr('value') == 'subject'){
            sortarray['applies_to'] = Number($($(v.currentTarget).find('.sort').context).attr('id')) 
            this.refs.myPopOversubject.hide()
            this.setState({subjectarrow: [Number($($(v.currentTarget).find('.sort').context).attr('id'))
, Number($($(v.currentTarget).find('.sort').context).attr('id'))]})
        }
        this.getNewData({page:0, limit:pageSize})   
	},
    toggleView: function(){
        if(this.state.idsarray.length != 0){
            stage = false
            $('.mainview').hide()
            this.setState({alldetail: false, containerdisplay: 'inherit'})
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
        $('.splitter').css('width', width)
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
    Portrait: function(){
        document.onmousemove = null
        document.onmousedown = null
        document.onmouseup = null
        stage = true
        width = 650
        $('.container-fluid2').css('width', '650px')
        $('.paging').css('width', width)
        $('.splitter').css('width', '650px')
        $('.mainview').show()
        var array = []
        array = ['dates-small', 'status-owner-small', 'module-reporter-small']
                        this.setState({display: 'flex', alldetail: true, scrollheight: $(window).height() - 170, maxheight: $(window).height() - 170, resize: 'horizontal',differentviews: '',
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
        this.setState({classname: [' ', ' ', ' ', ' '],display: 'block', maxheight: '', alldetail: true, differentviews: '100%',
        scrollheight: this.state.idsarray.length != 0 ? '300px' : $(window).height()  - 170, maxwidth: '', minwidth: '',scrollwidth: '100%', sizearray: array, resize: 'vertical'})

    },
    filterclear: function(v){
        if($($(v.currentTarget).find('.clear').context).attr('value') == 'id'){
            delete filter.id
            this.refs.myPopOverid.hide()
            this.setState({idtext: ''})
        }
        else if($($(v.currentTarget).find('.clear').context).attr('value') == 'subject'){
            delete filter.applies_to
            this.refs.myPopOversubject.hide()
            this.setState({subjecttext: ''})
        }
        this.getNewData({page:0, limit: pageSize})
    },

    handlefilter: function(v){
        if($($(v.currentTarget).find('.filter').context).attr('value') == 'id'){
            filter['id'] = [$('.idinput').val()]
            this.refs.myPopOverid.hide()
            this.setState({idtext: $('.idinput').val()})
        }
        else if($($(v.currentTarget).find('.filter').context).attr('value') == 'subject'){
            filter['applies_to'] = $('.subjectinput').val()
            this.refs.myPopOversubject.hide()
            this.setState({subjecttext: $('.subjectinput').val()})
        }
        this.getNewData({page: 0, limit: pageSize})
    }
    
});

