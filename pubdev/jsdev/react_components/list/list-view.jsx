'use strict';


var React                   = require('react')
var SelectedContainer       = require('../detail/selected_container.jsx')
var Store                   = require('../activemq/store.jsx')
var Page                    = require('../components/paging.jsx')
var Popover                 = require('react-bootstrap/lib/Popover')
var OverlayTrigger          = require('react-bootstrap/lib/OverlayTrigger')
var ButtonToolbar           = require('react-bootstrap/lib/ButtonToolbar')
var DateRangePicker         = require('../../../node_modules/react-daterange-picker')
var Button                  = require('react-bootstrap/lib/Button')
var SplitButton             = require('react-bootstrap/lib/SplitButton.js');
var DropdownButton          = require('react-bootstrap/lib/DropdownButton.js');
var MenuItem                = require('react-bootstrap/lib/MenuItem.js');
var ListViewHeader          = require('./list-view-header.jsx');
var ListViewData            = require('./list-view-data.jsx');
var datasource
var height;
var width;
var listStartX;
var listStartY;
var listStartWidth;
var listStartHeight;
module.exports = React.createClass({

    getInitialState: function(){
        var type = this.props.type;
        var typeCapitalized = this.titleCase(this.props.type);
        var id = this.props.id;
        var alertPreSelectedId = null;
        var scrollHeight = $(window).height() - 170
        var scrollWidth  = '650px'  
        var columnsDisplay = [];
        var columns = [];
        var columnsClassName = [];
        var showSelectedContainer = false;
        var sort = {'id':-1};
        var activepage = {page:0, limit:50};
        var filter;
        width = 650
        
        columnsDisplay = listColumnsJSON.columnsDisplay[this.props.type];
        columns = listColumnsJSON.columns[this.props.type];
        columnsClassName = listColumnsJSON.columnsClassName[this.props.type];
        
        if (this.props.listViewSort != null) {
            sort = JSON.parse(this.props.listViewSort)
        } 
        if (this.props.listViewPage != null) {
            activepage = JSON.parse(this.props.listViewPage);
        }
        if (this.props.listViewFilter != null) {
            filter = JSON.parse(this.props.listViewFilter);
        }
        if (this.props.type == 'alert') {showSelectedContainer = false; typeCapitalized = 'Alertgroup'; type='alertgroup'; alertPreSelectedId=id;};

        return {
            splitter: true, 
            selectedColor: '#AEDAFF',
            sourcetags: [], tags: [], startepoch:'', endepoch: '', idtext: '', totalcount: 0, activepage: activepage,
            statustext: '', subjecttext:'', idsarray: [], classname: [' ', ' ',' ', ' '],
            alldetail : true, viewsarrow: [0,0], idarrow: [-1,-1], subjectarrow: [0, 0], statusarrow: [0, 0],
            resize: 'horizontal',createdarrow: [0, 0], sourcearrow:[0, 0],tagsarrow: [0, 0],
            viewstext: '', entriestext: '', scrollheight: scrollHeight, display: 'flex',
            differentviews: '',maxwidth: '915px', maxheight: scrollHeight,  minwidth: '650px',
            suggestiontags: [], suggestionssource: [], sourcetext: '', tagstext: '', scrollwidth: scrollWidth, reload: false, 
            viewfilter: false, viewevent: false, showevent: true, objectarray:[], csv:true,fsearch: '', handler: [], listViewOrientation: 'landscape-list-view', columns:columns, columnsDisplay:columnsDisplay, columnsClassName:columnsClassName, typeCapitalized: typeCapitalized, type: type, queryType: type, id: id, showSelectedContainer: showSelectedContainer, listViewContainerDisplay: null, viewMode:this.props.viewMode, offset: 0, sort: sort, filter: filter, match: null, alertPreSelectedId: alertPreSelectedId, entryid: this.props.id2, listViewKey:1, loading: true, initialAutoScrollToId: false, };
    },
    componentWillMount: function() {
        if (this.props.viewMode == undefined || this.props.viewMode == 'default') {
            this.Landscape();
        } else if (this.props.viewMode == 'landscape') {
            this.Landscape();
        } else if (this.props.viewMode == 'portrait') {
            this.Portrait();
        }
        
    },
    componentDidMount: function(){
        var height = this.state.scrollheight
        var sortBy = this.state.sort;
        var filterBy = this.state.filter;
        var pageLimit = this.state.activepage.limit;
        var pageNumber = this.state.activepage.page;
        var idsarray = [];
        var newPage;
        if(this.props.id != undefined){
            if(this.props.id.length > 0){
                array = this.props.id
                //scrolled = $('.container-fluid2').scrollTop()    
                if(this.state.viewMode == 'landscape'){
                    height = '25vh'
                }
            }
        }

        if (this.props.type == 'alert') {
            $.ajax({
                type: 'get',
                url: 'scot/api/v2/alert/' + this.props.id
            }).success(function(response1){
                var newresponse = response1
                this.setState({id: newresponse.alertgroup, showSelectedContainer:true})
            }.bind(this))
        };

        var array = []
        var finalarray = [];
        //register for creation
        var storeKey = this.props.type + 'listview';
        Store.storeKey(storeKey)
        Store.addChangeListener(this.reloadactive)
        //List View code
        var  url = '/scot/api/v2/' + this.state.type;
        if (this.props.type == 'alert') {
            url = '/scot/api/v2/alertgroup'
        }
        //get page number
        if  (pageNumber != 0){
            newPage = (pageNumber - 1) * pageLimit
        } else {
            newPage = 0;
        } 
        var data = {limit:pageLimit, offset: newPage, sort: JSON.stringify(sortBy)}
        //add filter to the data object
        if (filterBy != undefined) {
            $.each(filterBy, function(key,value) {
                data[key] = value;
            })
        }

        $.ajax({
	        type: 'GET',
	        url: url,
	        data: data,
            traditional:true,
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
                        if (item != undefined) {
                            var sourcearr = item.join(', ')
                            finalarray[key]["source"] = sourcearr;
                        }
                    }
                    else if (num == 'tags' || num == 'tag'){
                        if (item != undefined) {
                            var tagarr = item.join(', ')
                            finalarray[key]["tag"] = tagarr;
                        }
                    }
	                else{
	                    finalarray[key][num] = item
	                }
                    if (num == 'id') {
                        Store.storeKey(item)
                        Store.addChangeListener(this.reloadactive)
                        idsarray.push(item);            
                    }
                }.bind(this))
                if(key %2 == 0){
                    finalarray[key]["classname"] = 'table-row roweven'
                }
                else {
                    finalarray[key]["classname"] = 'table-row rowodd'
                }
            }.bind(this))
            this.setState({scrollheight:height, objectarray: finalarray, totalcount: response.totalRecordCount, loading:false, idsarray:idsarray});
            if (this.props.type == 'alert' && this.state.showSelectedContainer == false) {
                this.setState({showSelectedContainer:false})
            } else if (this.state.id == undefined) {
                this.setState({showSelectedContainer: false})
            } else {
                this.setState({showSelectedContainer: true})
            };
            
        }.bind(this))
        
        //get incident handler
        $.ajax({
            type: 'get',
            url: '/scot/api/v2/handler?current=1'
        }).success(function(response){
            this.setState({handler: response.records})
        }.bind(this))
        
        $('#list-view-container').keydown(function(e){
            if ($('input').is(':focus')) {return};
            if (e.ctrlKey != true && e.metaKey != true) {
                var up = $('#list-view-data-div').find('.list-view-data-div').find('#'+this.state.id).prevAll('.table-row')
                var down = $('#list-view-data-div').find('.list-view-data-div').find('#'+this.state.id).nextAll('.table-row')
                if((e.keyCode == 74 && down.length != 0) || (e.keyCode == 40 && down.length != 0)){
                    var set;
                    set  = down[0].click()
                    if (e.keyCode == 40) {
                        e.preventDefault();
                    }
                    //var array = []
                    //array.push($(set).attr('id'))
                    //window.history.pushState('Page', 'SCOT', '/#/' + this.state.type+ '/'+ this.state.id)
                    //$('.container-fluid2').scrollTop(scrolled)
                    //scrolled = scrolled + $('#list-view-data-div').find('.list-view-data-div').find('#'+this.state.id).height()
                    //this.setState({id: })
                }
                else if((e.keyCode == 75 && up.length != 0) || (e.keyCode == 38 && up.length != 0)){
                    var set;
                    set  = up[0].click()
                    if (e.keyCode == 38) {
                        e.preventDefault();
                    }
                    //var array = []
                    //array.push($(set).attr('id'))
                    //window.history.pushState('Page', 'SCOT', '/#/'+this.state.type +'/'+$(set).attr('id'))
                    //$('.container-fluid2').scrollTop(scrolled)
                    //scrolled = scrolled -  $('#list-view-data-div').find('.list-view-data-div').find('#'+this.state.id).height()
                    //this.setState({idsarray: array})
                } 
            }    
        }.bind(this))
        $(document.body).keydown(function(e) {
            if ($('input').is(':focus')) {return};
            if ($('textarea').is(':focus')) {return};
            if (e.keyCode == 70 && (e.ctrlKey != true && e.metaKey != true)) {
                this.toggleView();
            }
        }.bind(this));
    },
    
    //Callback for AMQ updates
    reloadactive: function(){    
        this.getNewData() 
    },

    //This is used for the dragging portrait and landscape views
    reloadItem: function(e){
        $('iframe').each(function(index,ifr){
            $(ifr).addClass('pointerEventsOff')
        })
        height = $(window).height() - 170
        if(e != null){
            $('.container-fluid2').css('height', listStartHeight + e.clientY - listStartY)
            $('#list-view-data-div').css('height', listStartHeight + e.clientY - listStartY)
            this.forceUpdate();
        }
    },
    launchEvent: function(type,rowid,entryid){
        if(this.state.display == 'block'){
            this.state.scrollheight = '25vh'
        }
        this.setState({alertPreSelectedId: 0, scrollheight: this.state.scrollheight, id:rowid, showSelectedContainer: true, queryType:type, entryid:entryid})

    },
    render: function() {
        var listViewContainerHeight;
        var showClearFilter = false;
        var handler = []; 
        if (this.state.listViewContainerDisplay == null) {
            listViewContainerHeight = null;
        } else {
            listViewContainerHeight = '0px'
        }
        for (var i=0; i < this.state.handler.length; i++) {
            handler.push(this.state.handler[i].username + ' ' )
        }
        if (this.state.id != null && this.state.typeCapitalized != null) {
            document.title = this.state.typeCapitalized.charAt(0) + '-' + this.state.id
        }
        if (checkCookie('listViewFilter'+this.props.type) != null || checkCookie('listViewSort'+this.props.type) != null || checkCookie('listViewPage'+this.props.type) != null) {
            showClearFilter = true
        } 
        return (
            <div key={this.state.listViewKey} className="allComponents">
                <div className="black-border-line">
                    <div className='mainview'>
                        <div>
                           <div style={{display: 'inline-flex'}}>
                                {this.props.notificationSetting == 'on'?
                                    <Button eventKey='1' onClick={this.props.notificationToggle} bsSize='xsmall'>Mute Notifications</Button> :
                                    <Button eventKey='2' onClick={this.props.notificationToggle} bsSize='xsmall'>Turn On Notifications</Button>
                                }
                                {this.props.type == 'event' || this.props.type == 'intel' || this.props.type == 'incident' || this.props.type == 'signature' ? <Button onClick={this.createNewThing} eventKey='6' bsSize='xsmall'>Create {this.state.typeCapitalized}</Button> : null}
                                <Button eventKey='5' bsSize='xsmall' onClick={this.exportCSV}>Export to CSV</Button> 
                                <Button bsSize='xsmall' onClick={this.toggleView}>Full Screen Toggle (f)</Button>
                                {showClearFilter ? <Button onClick={this.clearAll} eventKey='3' bsSize='xsmall' bsStyle={'info'}>Clear All Filters</Button> : null}
                            </div>
                                <div id='list-view-container' style={{display:this.state.listViewContainerDisplay, height:listViewContainerHeight, opacity:this.state.loading ? '.2' : '1'}} tabIndex='1'>
                                    <div id={this.state.listViewOrientation} tabIndex='2'>
                                        <div className='tableview' style={{display: 'flex'}}>
                                            <div id='fluid2' className="container-fluid2" style={{width:'100%', maxHeight: this.state.maxheight, marginLeft: '0px',height: this.state.scrollheight, 'overflow': 'hidden',paddingLeft:'5px', display:'flex', flexFlow: 'column'}}>                 
                                                <table style={{width:'100%'}}>
                                                    <ListViewHeader data={this.state.objectarray} columns={this.state.columns} columnsDisplay={this.state.columnsDisplay} columnsClassName={this.state.columnsClassName} handleSort={this.handleSort} sort={this.state.sort} filter={this.state.filter} handleFilter={this.handleFilter} startepoch={this.state.startepoch} endepoch={this.state.endepoch} type={this.props.type}/>
                                                </table>
                                                <div id='list-view-data-div' style={{height:this.state.scrollheight}} className='list-view-overflow'>
                                                    <div className='list-view-data-div' style={{display:'block'}}>
                                                        <table style={{width:'100%'}}>
                                                            <ListViewData data={this.state.objectarray} columns={this.state.columns} columnsClassName={this.state.columnsClassName} type={this.state.type} selected={this.selected} selectedId={this.state.id}/>
                                                        </table>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <Page pagefunction={this.getNewData} defaultPageSize={50} count={this.state.totalcount} pagination={true} type={this.props.type} defaultpage={this.state.activepage.page}/>
                                    <div onMouseDown={this.dragdiv} className='splitter' style={{display:'block', height:'5px', backgroundColor:'black', borderTop:'1px solid #AAA', borderBottom:'1px solid #AAA', cursor: 'row-resize', overflow:'hidden'}}/>
                                </div>
                            {this.state.showSelectedContainer ? <SelectedContainer id={this.state.id} type={this.state.queryType} alertPreSelectedId={this.state.alertPreSelectedId} taskid={this.state.entryid} handleFilter={this.handleFilter} errorToggle={this.props.errorToggle}/> : null}
                        </div>
                    </div>
                </div>
            </div>
        )
    },
    AutoScrollToId: function() {
        //auto scrolls to selected id
        if ($('#'+this.state.id).offset() != undefined && $('.list-view-table-data').offset() != undefined) {
            var cParentTop =  $('.list-view-table-data').offset().top;
            var cTop = $('#'+this.state.id).offset().top - cParentTop;
            var cHeight = $('#'+this.state.id).outerHeight(true);
            var windowTop = $('#list-view-data-div').offset().top;
            var visibleHeight = $('#list-view-data-div').height();

            var scrolled = $('#list-view-data-div').scrollTop();
            if (cTop < (scrolled)) {
                $('#list-view-data-div').animate({'scrollTop': cTop-(visibleHeight/2)}, 'fast', '');
            } else if (cTop + cHeight + cParentTop> windowTop + visibleHeight) {
                $('#list-view-data-div').animate({'scrollTop': (cTop + cParentTop) - visibleHeight + scrolled + cHeight}, 'fast', 'swing');
            }
            this.setState({initialAutoScrollToId: true});
        }
    },
    componentDidUpdate: function(prevProps, prevState) {
        //auto scrolls to selected id
        for (var i=0; i < this.state.objectarray.length; i++){          //Iterate through all of the items in the list to verify that the current id still matches the rows in the list. If not, don't scroll
            var idReference = this.state.objectarray[i].id;
            if (this.state.id != null && this.state.id == idReference && this.state.id != prevState.id || this.state.id != null && this.state.id == idReference && prevState.initialAutoScrollToId == false ) {     //Checks that the id is present, is on the screen, and will not be kicked off again if its already been scrolled to before. The || statement handles the initial load since the id hasn't been scrolled to before.
               this.AutoScrollToId(); 
            }
        }
    },
    componentWillReceiveProps: function(nextProps) {
        if ( nextProps.id == undefined ) {
            this.setState({type: nextProps.type, id:null, showSelectedContainer: false, scrollheight: $(window).height() - 170});
        } else if (nextProps.id != this.props.id) {
            this.setState({type: nextProps.type, id: nextProps.id});
        }
    },

    stopdrag: function(e){
        $('iframe').each(function(index,ifr){
        $(ifr).removeClass('pointerEventsOff')
        }) 
        document.onmousemove = null
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
    toggleView: function(){
        if(this.state.id.length != 0 && this.state.showSelectedContainer == true  && this.state.listViewContainerDisplay != 'none' ){
            this.setState({listViewContainerDisplay: 'none', scrollheight:'0px'})
        } else {
            this.setState({listViewContainerDisplay: null, scrollheight:'25vh'})
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
        $('.container-fluid2').css('width', '650px')
        width = 650
        $('.paging').css('width', width)
        $('.splitter').css('width', '5px')
        $('.mainview').show()
        var array = []
        array = ['dates-small', 'status-owner-small', 'module-reporter-small']
                        this.setState({splitter: true, display: 'flex', alldetail: true, scrollheight: $(window).height() - 170, maxheight: $(window).height() - 170, resize: 'horizontal',differentviews: '',
                        maxwidth: '', minwidth: '',scrollwidth: '650px', sizearray: array})
        this.setState({listViewOrientation: 'portrait-list-view'})
        setCookie('viewMode',"portrait",1000);
    },
    Landscape: function(){
        document.onmousemove = null
        document.onmousedown = null
        document.onmouseup = null
        width = 650
        $('.paging').css('width', '100%')
        $('.splitter').css('width', '100%')
        $('.mainview').show()
        this.setState({classname: [' ', ' ', ' ', ' '],splitter: false, display: 'block', maxheight: '', alldetail: true, differentviews: '100%',
        scrollheight: this.state.id != null ? '300px' : $(window).height()  - 170, maxwidth: '', minwidth: '',scrollwidth: '100%', resize: 'vertical'})
        this.setState({listViewOrientation: 'landscape-list-view'});
        setCookie('viewMode',"landscape",1000);
    },
    clearAll: function(){
        /*sortarray['id'] = -1
        filter = {}
        this.setState({tags: [], sourcetags: [], startepoch: '', endepoch: '', idtext: '',
            upstartepoch: '', upendepoch: '', statustext: '', subjecttext: '', entriestext: '', ownertext: '',
            viewstext: ''})
            this.getNewData({page: 0, limit: pageSize})*/
        var newListViewKey = this.state.listViewKey + 1;
        this.setState({listViewKey:newListViewKey, activePage: {page:0, limit:50}, sort:{'id':-1}});  
        this.handleFilter(null,null,true); //clear filters
        this.getNewData({page:0, limit:50}, {'id':-1}, {})
        deleteCookie('listViewFilter'+this.props.type) //clear filter cookie
        deleteCookie('listViewSort'+this.props.type) //clear sort cookie
        deleteCookie('listViewPage'+this.props.type) //clear page cookie
    },
    selected: function(type,rowid,taskid){
        if (taskid == null) {
            //window.history.pushState('Page', 'SCOT', '/#/' + type +'/'+rowid)  
            this.props.history.push( '/' + type + '/' + rowid );
            //this.launchEvent(type, rowid)
        } else {
            //If a task, swap the rowid and the taskid
            //window.history.pushState('Page', 'SCOT', '/#/' + type + '/' + taskid + '/' + rowid)
            this.props.history.push( '/' + type + '/' + taskid + '/' + rowid );
            //this.launchEvent(type, taskid, rowid);
        }
        //scrolled = $('.list-view-data-div').scrollTop()
        if(this.state.display == 'block'){
            this.state.scrollheight = '25vh'
        }
        this.setState({alertPreSelectedId: 0, scrollheight: this.state.scrollheight, showSelectedContainer: true })
    },
    getNewData: function(page, sort, filter){
        this.setState({loading:true}); //display loading opacity
        var sortBy = sort;
        var filterBy = filter;
        var pageLimit;
        var pageNumber;
        var idsarray = this.state.idsarray;
        var newidsarray = [];
        //defaultpage = page.page
        if (page == undefined) {
            pageNumber = this.state.activepage.page;
            pageLimit = this.state.activepage.limit;
        } else {
            if (page.page == undefined) {
                pageNumber = this.state.activepage.page;
            } else {
                pageNumber = page.page;
            }
            if (page.limit == undefined) {
                pageLimit = this.state.activepage.limit
            } else {
                pageLimit = page.limit;
            }
        }
        var newPage;
        if  (pageNumber != 0){
            newPage = (pageNumber - 1) * pageLimit
        } else {
            //page.limit = pageLimit;
            newPage = 0;
        }
        //sort check
        if (sortBy == undefined) {
            sortBy = this.state.sort;
        } 
        //filter check
        if (filterBy == undefined){
            filterBy = this.state.filter;
        }
        var data = {limit: pageLimit, offset: newPage, sort: JSON.stringify(sortBy)}
        //add filter to the data object
        if (filterBy != undefined) {
            $.each(filterBy, function(key,value) {
                data[key] = value;
            })
        }
        var newarray = []
        
        $.ajax({
	        type: 'GET',
	        url: '/scot/api/v2/'+this.state.type,
	        data: data,
            traditional: true,
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
                        if (item != undefined) {
                            var sourcearr = item.join(', ')
                            newarray[key]["source"] = sourcearr;
                        }
                    }
                    else if (num == 'tags' || num == 'tag'){
                        if (item != undefined) {
                            var tagarr = item.join(', ')
                            newarray[key]["tag"] = tagarr;
                        }
                    } 
	                else{
	                    newarray[key][num] = item
	                }
                    if (num == 'id') {
                        var idalreadyadded = false;
                        for (var i=0; i < idsarray.length; i++) {
                            if (item == idsarray[i]) {
                                idalreadyadded = true;
                            }
                        }
                        if (idalreadyadded == false) {
                            Store.storeKey(item)
                            Store.addChangeListener(this.reloadactive)
                        }
                        newidsarray.push(item);
                    }
	            }.bind(this))
                if(key %2 == 0){
                    newarray[key]['classname'] = 'table-row roweven'
                }
                else {
                    newarray[key]['classname'] = 'table-row rowodd'
                }
	        }.bind(this))
                this.setState({totalcount: response.totalRecordCount, activepage: {page:pageNumber, limit:pageLimit}, objectarray: newarray, loading:false, idsarray:newidsarray})
        }.bind(this))
        //get incident handler
        $.ajax({
            type: 'get',
            url: '/scot/api/v2/handler?current=1'
        }).success(function(response){
            this.setState({handler: response.records})
        }.bind(this))
    },

    exportCSV: function(){
        var keys = []
        var columns = this.state.columns;
	    $.each(columns, function(key, value){
            keys.push(value);
	    });
	    var csv = ''
    	$('.list-view-table-data').find('.table-row').each(function(key, value){
	        var storearray = []
            $(value).find('td').each(function(x,y) {
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
    handleSort : function(column, clearall){
        var currentSort = this.state.sort;
        var intDirection;
        if (clearall == true) {
            this.setState({sort:{'id':-1}});
        } else{
            if(Object.keys(currentSort).length === 0 && currentSort.constructor === Object) {
                currentSort[column] = direction;
            } else {
                var obj = Object.keys(currentSort);
                if (obj[0] == column) {
                    var direction = currentSort[obj];
                    if (direction == -1) { 
                        intDirection = 1;
                    } else {
                        intDirection = -1;
                    }
                    currentSort[column] = intDirection;
                } else {
                    currentSort = {};
                    currentSort[column] = 1;
                }
            }
            this.setState({sort:currentSort}); 
            this.getNewData(null, currentSort, null)   
	        var cookieName = 'listViewSort' + this.props.type;
            setCookie(cookieName,JSON.stringify(currentSort),1000);
        }
    },


    handleFilter: function(column,string,clearall,type){
        var currentFilter = this.state.filter;
        var newFilterObj = {};
        var _type;
        if (type != undefined) {
            _type = type;
        } else {
            _type = this.props.type;
        }
        if (clearall == true) {
            this.setState({filter:newFilterObj})
        } else { 
            if (string.length == 0 || string.length == null) { //check if string is blank
                if (currentFilter != null) {
                    if (currentFilter[column]) {
                        delete currentFilter[column];
                    }
                }
                for (var prop in currentFilter) { newFilterObj[prop] = currentFilter[prop]}; // combine current filter with new one
            } else {
                var array;
                if (typeof(string) == 'string') {
                    array = string.split(',');
                } else {
                    array = string; //this is used if string is an array of strings to search (tags/source)
                }
                var inProgressFilter = [];
                var newFilter = [];
                //if no filter applied
                if (currentFilter == undefined) {
                    for (var i=0; i < array.length; i++) {
                        inProgressFilter.push(array[i]);
                    }
                    newFilterObj[column] = inProgressFilter;
                //filter is applied
                } else {
                    //already filtered column being modified
                    if (currentFilter[column] != undefined) {
                        for (var i=0; i < array.length; i++) {
                            inProgressFilter.push(array[i]);
                        }
                        delete currentFilter[column]
                        newFilterObj[column] = inProgressFilter;
                    } else {  //column not yet filtered, so append it to the existing filters
                        for (var i=0; i < array.length; i++) {
                            inProgressFilter.push(array[i]);
                        }
                        newFilterObj[column] = inProgressFilter;
                    }
                    for (var prop in currentFilter) { newFilterObj[prop] = currentFilter[prop]}; // combine current filter with new one
                }
            }
            this.setState({filter:newFilterObj});
            if (type == this.props.type || type == undefined) {    //Check if the type passed in matches the type displayed. If not, it's updating the filter for a future query in a different type. Undefined implies its the same type, so update 
                this.getNewData({page:0},null,newFilterObj)
            }
            var cookieName = 'listViewFilter' + _type;
            setCookie(cookieName,JSON.stringify(newFilterObj),1000);
        }
    },
    titleCase: function(string) {
        var newstring = string.charAt(0).toUpperCase() + string.slice(1)
        return (
            newstring
        )
    },
    createNewThing: function(){
    var data;
    if (this.props.type == 'signature') {
        data = JSON.stringify({name:'Name your Signature', status: 'disabled'});   
    } else {
        data = JSON.stringify({subject: 'No Subject'});
    }
        $.ajax({
            type: 'POST',
            url: '/scot/api/v2/'+this.props.type,
            data: data
        }).success(function(response){
            this.selected(this.props.type, response.id);
            //this.props.history.push( '/' + this.props.type + '/' + response.id );
            //this.launchEvent(this.props.type,response.id)
            //window.history.pushState('Page', 'SCOT', '/#/'+this.props.type+'/'+response.id);
        }.bind(this))
    }, 
});

