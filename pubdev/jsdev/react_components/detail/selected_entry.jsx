var React                   = require('react');
var ReactDOM                = require('react-dom');
var ReactTime               = require('react-time').default;
var SplitButton             = require('react-bootstrap/lib/SplitButton.js');
var DropdownButton          = require('react-bootstrap/lib/DropdownButton.js');
var MenuItem                = require('react-bootstrap/lib/MenuItem.js');
var Button                  = require('react-bootstrap/lib/Button.js');
var AddEntry                = require('../components/add_entry.jsx');
var FileUpload              = require('../components/file_upload.jsx');
var DeleteEntry             = require('../modal/delete.jsx').DeleteEntry;
var Summary                 = require('../components/summary.jsx');
var Task                    = require('../components/task.jsx');
var SelectedPermission      = require('../components/permission.jsx');
var Frame                   = require('react-frame');
var Store                   = require('../activemq/store.jsx');
var AddFlair                = require('../components/add_flair.jsx').AddFlair;
var EntityDetail            = require('../modal/entity_detail.jsx');
var LinkWarning             = require('../modal/link_warning.jsx'); 
var Link                    = require('react-router-dom').Link;
var IncidentTable           = require('../components/incident_table.jsx');
var SignatureTable          = require('../components/signature_table.jsx');
var TrafficLightProtocol    = require('../components/traffic_light_protocol.jsx');
var Marker                  = require('../components/marker.jsx').default;
var EntityCreateModal       = require('../modal/entity_create.jsx').default;
var CustomMetaDataTable     = require('../components/custom_metadata_table.jsx');

var SelectedEntry = React.createClass({
    getInitialState: function() {
        var entityDetailKey = Math.floor(Math.random()*1000);
        return {
            showEntryData:this.props.showEntryData,
            showEntityData:this.props.showEntityData,
            entryData:this.props.entryData,
            entityData:this.props.entityData,
            entityid: null,
            entitytype:null,
            entityoffset:null,
            entityobj:null,
            key:this.props.id,
            flairToolbar:false,
            notificationType:null,
            notificationMessage: '',
            height: null,
            entityDetailKey:entityDetailKey
        }
    },
    componentDidMount: function() {
        if (this.props.type == 'alert' || this.props.type == 'entity' || this.props.isPopUp == 1) {
            $.ajax({
                type: 'get',
                url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/entry', 
                success: function(result) {
                    var entryResult = result.records;
                    if (this.isMounted()) {
                        this.setState({showEntryData:true, entryData:entryResult})
                        for (var i=0; i < result.records.length; i++) {
                            Store.storeKey(result.records[i].id)
                            Store.addChangeListener(this.updatedCB);
                        }
                        this.Watcher();
                    }
                }.bind(this),
                error: function(result) {
                    if (this.isMounted()) {
                        this.setState({showEntryData:true});
                        this.props.errorToggle("Failed to load entry data.", result);
                    }
                }.bind(this)
            });
            $.ajax({
                type: 'get',
                url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/entity',
                success: function(result) {
                    var entityResult = result.records;
                    if (this.isMounted()) {
                        this.setState({showEntityData:true, entityData:entityResult})
                        var waitForEntry = {
                            waitEntry: function() {
                                if(this.state.showEntryData == false){
                                    setTimeout(waitForEntry.waitEntry,50);
                                } else {
                                    setTimeout(function(){AddFlair.entityUpdate(entityResult,this.flairToolbarToggle,this.props.type,this.linkWarningToggle,this.props.id)}.bind(this));
                                }
                            }.bind(this)
                        };
                        waitForEntry.waitEntry();
                    }
                }.bind(this),
                error: function(result) {
                    if (this.isMounted()) {
                        this.setState({showEntityData: true})
                        this.props.errorToggle("Failed to load entity data.", result);
                    }
                }.bind(this)
            });
            Store.storeKey(this.props.id);
            Store.addChangeListener(this.updatedCB);
        } 
    this.containerHeightAdjust();
    window.addEventListener('resize',this.containerHeightAdjust);
    $("#ReactTable").resize(function(){ this.containerHeightAdjust}.bind(this));
    },
    componentWillReceiveProps: function() {
        this.containerHeightAdjust();
    },
    componentDidUpdate: function() {
        if(this.state.runWatcher == true) {
            this.Watcher();
        }
    },
    updatedCB: function() {
       if (this.props.type == 'alert' || this.props.type == 'entity' || this.props.isPopUp == 1) {
           $.ajax({
                type: 'get',
                url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/entry',
                success: function(result) {
                    var entryResult = result.records;
                    if (this.isMounted()) {
                        this.setState({showEntryData:true, entryData:entryResult})
                        for (var i=0; i < result.records.length; i++) {
                            Store.storeKey(result.records[i].id)
                            Store.addChangeListener(this.updatedCB);
                        }
                        this.Watcher()
                    }
                }.bind(this),
                error: function(result) {
                    if (this.isMounted()) {
                        this.setState({showEntryData:true});
                        this.props.errorToggle("Failed to load entry data ", result);
                    }
                }.bind(this)
            }); 
            $.ajax({
                type: 'get',
                url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/entity',
                success: function(result) {
                    var entityResult = result.records;
                    if (this.isMounted()) {
                        this.setState({showEntityData:true, entityData:entityResult})
                        var waitForEntry = {
                            waitEntry: function() {
                                if(this.state.showEntryData == false){
                                    setTimeout(waitForEntry.waitEntry,50);
                                } else {
                                    setTimeout(function(){AddFlair.entityUpdate(entityResult,this.flairToolbarToggle,this.props.type,this.linkWarningToggle,this.props.id)}.bind(this));
                                }
                            }.bind(this)
                        };
                        waitForEntry.waitEntry();
                    }
                }.bind(this),
                error: function(result) {
                    if (this.isMounted()) {
                        this.setState({showEntityData: true})
                        this.props.errorToggle("Failed to load entity data", result);
                    }
                }.bind(this)
            }); 
        }
    },

    flairToolbarToggle: function(id,value,type,entityoffset,entityobj) {
        if (this.isMounted()) {
            this.setState({flairToolbar:true,entityid:id,entityvalue:value,entitytype:type,entityoffset:entityoffset,entityobj:entityobj})
        }
    },

    flairToolbarOff: function() {
        if (this.isMounted()) {
            var newEntityDetailKey = this.state.entityDetailKey + 1;
            this.setState({flairToolbar:false,entityDetailKey:newEntityDetailKey});
        }
    },

    linkWarningToggle: function(href) {
        if (this.isMounted()) {
            if (this.state.linkWarningToolbar == false) {
                this.setState({linkWarningToolbar:true,link:href})
            } else {
                this.setState({linkWarningToolbar:false})
            }
        }
    },

    Watcher: function() {
        var containerid = '#' + this.props.type + '-detail-container';
        if(this.props.type != 'alertgroup') {
             
            $(containerid).find('iframe').each(function(index,ifr) {
            //requestAnimationFrame waits for the frame to be rendered (allowing the iframe to fully render before excuting the next bit of code!!!
                ifr.contentWindow.requestAnimationFrame( function() {
                    if(ifr.contentDocument != null) {
                        var arr = [];
                        //arr.push(this.props.type);
                        arr.push(this.checkFlairHover);
                        $(ifr).off('mouseenter');
                        $(ifr).off('mouseleave');
                        $(ifr).on('mouseenter', function(v,type) {
                            var intervalID = setInterval(this[0], 50, ifr);// this.flairToolbarToggle, type, this.props.linkWarningToggle, this.props.id);
                            $(ifr).data('intervalID', intervalID);
                            console.log('Now watching iframe ' + intervalID);
                        }.bind(arr));
                        $(ifr).on('mouseleave', function() {
                            var intervalID = $(ifr).data('intervalID');
                            window.clearInterval(intervalID);
                            console.log('No longer watching iframe ' + intervalID);
                        });
                    }
                }.bind(this));
            }.bind(this))
        } else {
            $(containerid).find('a, .entity').not('.not_selectable').each(function(index,tr) {
                $(tr).off('mousedown');
                $(tr).on('mousedown', function(index) {
                    var thing = index.target;
                   if ($(thing)[0].className == 'extras') { thing = $(thing)[0].parentNode}; //if an extra is clicked reference the parent element
                    if ($(thing).attr('url')) {  //link clicked
                        var url = $(thing).attr('url');
                        this.linkWarningToggle(url);
                    } else { //entity clicked
                        var entityid = $(thing).attr('data-entity-id');
                        var entityvalue = $(thing).attr('data-entity-value');
                        var entityoffset = $(thing).offset();
                        var entityobj = $(thing);
                        this.flairToolbarToggle(entityid, entityvalue, 'entity', entityoffset, entityobj);
                    }
                }.bind(this)) 
            }.bind(this));
        }
    },

    checkFlairHover: function(ifr) {
        function returnifr() {
            return ifr;
        }
        if(this.props.type != 'alertgroup') {
            if(ifr.contentDocument != null) {
                $(ifr).contents().find('.entity').each(function(index, entity) {
                    if($(entity).css('background-color') == 'rgb(255, 0, 0)') {
                        $(entity).data('state', 'down');
                    } else if ($(entity).data('state') == 'down') {
                        $(entity).data('state', 'up');
                        var entityid = $(entity).attr('data-entity-id');
                        var entityvalue = $(entity).attr('data-entity-value');
                        var entityobj = $(entity);
                        var ifr = returnifr();
                        var entityoffset = {top: $(entity).offset().top+$(ifr).offset().top, left: $(entity).offset().left+$(ifr).offset().left}
                        this.flairToolbarToggle(entityid,entityvalue,'entity',entityoffset, entityobj)                    
                    }
                }.bind(this));
            }
            if(ifr.contentDocument != null) {
                $(ifr).contents().find('a').each(function(index,a) {
                    if($(a).css('color') == 'rgb(255, 0, 0)') {
                        $(a).data('state','down');
                    } else if ($(a).data('state') == 'down') {
                        $(a).data('state','up');
                        var url = $(a).attr('url');
                        this.linkWarningToggle(url);
                    }
                }.bind(this));
            }
        } 
    }, 

    containerHeightAdjust: function() {
        //Using setTimeout so full screen toggle animation has time to finish before resizing detail section
        setTimeout( function() {
            var scrollHeight;
            let ListViewTableHeight = parseInt(document.defaultView.getComputedStyle(document.getElementsByClassName('ReactTable')[0]).height, 10);
            if (ListViewTableHeight !== 0) {
                scrollHeight = $(window).height() - ListViewTableHeight - $('#header').height() - 78 
                scrollHeight = scrollHeight + 'px'
            } else {
                scrollHeight = $(window).height() - $('#header').height() - 78 
                scrollHeight = scrollHeight + 'px'
            }
            //$('#detail-container').css('height',scrollHeight);
            if (this.isMounted()) {
                this.setState({height:scrollHeight});
            }
        }.bind(this), 500);
        
    },

    render: function() { 
        var divid = 'detail-container';
        var height = this.state.height;
        var data = this.props.entryData;
        var type = this.props.type;
        var id = this.props.id;
        var showEntryData = this.props.showEntryData;
        var divClass = 'row-fluid entry-wrapper entry-wrapper-main'
        if (type =='alert') {
            //divClass = 'row-fluid entry-wrapper entry-wrapper-main-300'
            divClass = 'row-fluid entry-wrapper entry-wrapper-main-nh'
            data = this.state.entryData;
            showEntryData = this.state.showEntryData;
        } else if (type =='alertgroup') {
            divClass = 'row-fluid alert-wrapper entry-wrapper-main';
        } else if (type == 'entity' || this.props.isPopUp == 1) {
            divClass = 'row-fluid entry-wrapper-entity';
            data = this.state.entryData;
            showEntryData = this.state.showEntryData;
        }
        //lazy loading flair - this needs to be done here because it is not initialized when this function is called by itself (alerts and entities)
        var EntityDetail = require('../modal/entity_detail.jsx');
        if (type == 'alert' || this.props.isPopUp == 1) {
            divid = this.props.type + '-detail-container';
            height = null;
        }
        return (
            <div id={divid} key={id} className={divClass} style={{height:height}}> 
                <CustomMetaDataTable type={type} id={id} errorToggle={this.props.errorToggle} />
                {/*{(type == 'incident' && this.props.headerData != null) ? <IncidentTable type={type} id={id} headerData={this.props.headerData} errorToggle={this.props.errorToggle}/> : null}*/}
                {(type == 'signature' && this.props.headerData != null) ? <SignatureTable type={type} id={id} headerData={this.props.headerData} errorToggle={this.props.errorToggle} showSignatureOptions={this.props.showSignatureOptions} /> : null}
                {showEntryData ? <EntryIterator data={data} type={type} id={id} alertSelected={this.props.alertSelected} headerData={this.props.headerData} alertPreSelectedId={this.props.alertPreSelectedId} isPopUp={this.props.isPopUp} entryToggle={this.props.entryToggle} updated={this.updatedCB} aType={this.props.aType} aID={this.props.aID} entryToolbar={this.props.entryToolbar} errorToggle={this.props.errorToggle} fileUploadToggle={this.props.fileUploadToggle} fileUploadToolbar={this.props.fileUploadToolbar} flairOff={this.props.flairOff}/> : <span>Loading...</span>} 
                {this.props.entryToolbar ? <div>{this.props.isAlertSelected == false ? <AddEntry entryAction={'Add'} type={this.props.type} targetid={this.props.id} id={null} addedentry={this.props.entryToggle} updated={this.updatedCB} errorToggle={this.props.errorToggle}/> : null}</div> : null}
                {this.props.fileUploadToolbar ? <div>{this.props.isAlertSelected == false ? <FileUpload type={this.props.type} targetid={this.props.id} id={'file_upload'} fileUploadToggle={this.props.fileUploadToggle} updated={this.updatedCB} errorToggle={this.props.errorToggle}/> : null}</div> : null}
                {this.state.flairToolbar ? <EntityDetail key={this.state.entityDetailKey} flairToolbarToggle={this.flairToolbarToggle} flairToolbarOff={this.flairToolbarOff} entityid={this.state.entityid} entityvalue={this.state.entityvalue} entitytype={this.state.entitytype} type={this.props.type} id={this.props.id} aID={this.props.aID} aType={this.props.aType} entityoffset={this.state.entityoffset} entityobj={this.state.entityobj} linkWarningToggle={this.linkWarningToggle} errorToggle={this.props.errorToggle}/>: null}
                {this.state.linkWarningToolbar ? <LinkWarning linkWarningToggle={this.linkWarningToggle} link={this.state.link}/> : null}
            </div>       
        );
    }
});

var EntryIterator = React.createClass({
    render: function() {
        var rows = [];
        var data = this.props.data;
        var type = this.props.type;
        var id = this.props.id;  
        if (data[0] == undefined) {
            if (type != 'alertgroup') {
                return (
                    <div>
                        <div style={{color:'blue'}}>No entries found. Would you like to create one?</div>
                    </div>
                )
            } else {
                return (
                    <div>
                        <div style={{color:'blue'}}>No alerts found or they are unable to be rendered. Please check the source and correct the formatting of the alert if necessary</div>
                    </div>
                )
            }
        } else {
            if (type != 'alertgroup') {
                data.forEach(function(data) {
                    rows.push(<EntryParent key={data.id} items={data} type={type} id={id} isPopUp={this.props.isPopUp} errorToggle={this.props.errorToggle}/>);
                }.bind(this));
            } else {
                rows.push(<AlertParent key={id} items={data} type={type} id={id} headerData={this.props.headerData} alertSelected={this.props.alertSelected} alertPreSelectedId={this.props.alertPreSelectedId} aType={this.props.aType} aID={this.props.aID} entryToolbar={this.props.entryToolbar} entryToggle={this.props.entryToggle} updated={this.props.updated} fileUploadToggle={this.props.fileUploadToggle} fileUploadToolbar={this.props.fileUploadToolbar} errorToggle={this.props.errorToggle} flairOff={this.props.flairOff}/>);
            }
            return (
                <div>
                    {rows}
                </div>
            )
        }
    }
});

var AlertParent = React.createClass({
    getInitialState: function() {
        var arr = [];
        return {
            activeIndex: arr,
            lastIndex: null,
            allSelected:false,
            lastId: null,
            activeId: arr,
        }
    },
    componentDidMount: function() {
        var filterOption = false;
        var widgetOption = ['sortTbody'];
        if (this.props.items.length > 1) { filterOption = true; widgetOption = ['sortTbody', 'filter']}
        $('#sortabletable').tablesorter({
            widgets: widgetOption,
            widgetOptions: {
                sortTbody_primaryRow : '.main',
                sortTbody_sortRows   : false,
                sortTbody_noSort     : 'tablesorter-no-sort-tbody',

                // include child row content while filtering the second demo table
                filter_childRows     : filterOption
            }
        });
        
        //Ctrl + A to select all alerts
        $('#main-detail-container').keydown(function(event){
            //prevent from working when in input
            if ($('input').is(':focus')) {return};
            //check for ctrl + a with keyCode 
            if (event.keyCode == 65 && (event.ctrlKey == true || event.metaKey == true)) {
                this.rowClicked(null,null,'all',null);
                event.preventDefault()
            }
        }.bind(this))
    },
    componentWillUnmount: function() {
        $('#main-detail-container').unbind('keydown');
    },
    
    componentDidUpdate: function() {
        //update the table, but not if a tinymce editor window is open as it will break the editing window
        if (!$('.mce-tinymce')[0] && window.getSelection().toString() == '' ) {
            $('#sortabletable').trigger('update');
        }
    },

    rowClicked: function(id,index,clickType,status) {
        var array = this.state.activeIndex.slice();
        var activeIdArray = this.state.activeId.slice();
        var selected = true;
        this.setState({allSelected:false});
        if (clickType == 'ctrl') {
            for (var i=0; i < activeIdArray.length; i++) {
                if (activeIdArray[i] === id) {
                    activeIdArray.splice(i,1)
                    this.setState({activeId:activeIdArray})
                    selected = false;
                }
            }
            if (selected == true) {
                activeIdArray.push(id);
                this.setState({activeId:activeIdArray})
            }
        } else if (clickType == 'shift') {
            var keyObj = {};
            var i = 0;
            $('.alertTableHorizontal').find('tr').not('.not_selectable').each(function(index,x){
                var id = $(x).attr('id');
                keyObj[id] = i;
                i++;
            }.bind(this));
            if (this.state.lastId != undefined) { 
                var min = Math.min(keyObj[this.state.lastId],keyObj[id]);
                var max = Math.max(keyObj[this.state.lastId],keyObj[id]);
                //var min = max - min + 1;
                var range = [];
                /*while (min--) {
                    range[min]=max--;
                }*/
                for (var q=min; q <= max; q++) {
                    range.push(q)
                }
                for (var i=0; i < range.length; i++) {
                    for (var prop in keyObj) {
                        if (keyObj[prop] == range[i]) {
                            activeIdArray.push(parseInt(prop));
                        }
                    }
                }
                this.setState({activeId:activeIdArray})
            }
        } else if (clickType == 'all') {
            activeIdArray = [];
            for (var i=0; i < this.props.items.length; i++) {
                activeIdArray.push(this.props.items[i].id)
            }
            this.setState({activeId:activeIdArray,allSelected:true});
        } else {
            activeIdArray = [];
            activeIdArray.push(id);
            this.setState({activeId:activeIdArray});
        }
        this.setState({lastIndex:index,lastId:id});
        if (activeIdArray.length == 1) {
            this.props.alertSelected('oneactive',activeIdArray[0],'alert');
        } else if (activeIdArray.length == 0){   
            this.props.alertSelected(null,null,'alert');
        } else {
            this.props.alertSelected('showall',null,'alert')
        }
    },
    render: function() {
        //var z = 0;
        var items = this.props.items;
        var body = [];
        var header = [];
        var columns = false;
        var dataColumns = false;
        let linkToSearch = [];
        if (items[0] != undefined){
            var col_names;
            //checking two locations for columns. Will make this a single location in future revision
            
            if (col_names == undefined) {
                if (items[0].columns != undefined) {
                    if (items[0].columns.length != 0) { 
                        col_names = items[0].columns.slice(0) //slices forces a copy of array
                    } 
                }
            }
            
            if (col_names == undefined) {
                if (items[0].data != undefined) {
                    if (items[0].data.columns != undefined) {
                        if (items[0].data.columns.length != 0) {
                            col_names = items[0].data.columns.slice(0);
                        }
                    }
                }
            }
            if (col_names == undefined) {
                if (this.props.headerData != undefined) {
                    if (this.props.headerData.columns != undefined) {
                        if (this.props.headerData.columns.length != 0) {
                            col_names = this.props.headerData.columns.slice(0);
                        }
                    }
                }
            }
            if (col_names == undefined) {
                console.log('Error finding columns in JSON');
                if (this.props.headerData != undefined){
                    if (this.props.headerData.body != undefined) {
                        return (
                            <div>
                                <div style={{color:'red'}}>If you see this message, please notify your SCOT admin. Parsing failed on the message below. The raw alert is displayed.</div>
                                <div className='alertTableHorizontal' dangerouslySetInnerHTML={{ __html: this.props.headerData.body}}/>
                            </div>
                        )
                    }
                }
            }
            col_names.unshift('entries'); //Add entries to 3rd column
            col_names.unshift('status'); //Add status to 2nd column
            col_names.unshift('id'); //Add entries number to 1st column
            for (var i=0; i < col_names.length; i++){
                header.push(<AlertHeader colName={col_names[i]} key={i}/>)
            }
            for (var z=0; z < items.length; z++) {
                var dataFlair = null;
                if (Object.getOwnPropertyNames(items[z].data_with_flair).length != 0 && !this.props.flairOff ) {
                    dataFlair = items[z].data_with_flair;
                } else {
                    dataFlair = items[z].data;
                }
                
                body.push(<AlertBody key={z} index={z} data={items[z]} dataFlair={dataFlair} headerData={this.props.headerData} activeIndex={this.state.activeIndex} rowClicked={this.rowClicked} alertSelected={this.props.alertSelected} allSelected={this.state.allSelected} alertPreSelectedId={this.props.alertPreSelectedId} activeId={this.state.activeId} aID={this.props.aID} aType={this.props.aType} entryToggle={this.props.entryToggle} entryToolbar={this.props.entryToolbar} updated={this.props.updated} fileUploadToggle={this.props.fileUploadToggle} fileUploadToolbar={this.props.fileUploadToolbar} errorToggle={this.props.errorToggle} />)
            }
            
            var search = null;
            if (items[0].data_with_flair != undefined && !this.props.flairOff ) {
                search = items[0].data_with_flair.search;
            } else {
                search = items[0].data.search;
            }


            for ( let y = 0; y < this.props.headerData.ahrefs.length; y++ ) {
                linkToSearch.push( <a href={ this.props.headerData.ahrefs[y].link }>{this.props.headerData.ahrefs[y].subject}</a>);
                linkToSearch.push( <br/> );
            }

        } else if (this.props.headerData != undefined){
            if (this.props.headerData.body != undefined) {
                return (
                    <div>
                        <div style={{color:'red'}}>If you see this message, please notify your SCOT admin. Parsing failed on the message below. The raw alert is displayed.</div>
                        <div className='alertTableHorizontal' dangerouslySetInnerHTML={{ __html: this.props.headerData.body}}/>
                    </div>
                )
            }
        }
        return (
            <div>
                <div>
                    <table className="tablesorter alertTableHorizontal" id={'sortabletable'} width='100%'>
                        <thead>
                            <tr>
                                {header}
                            </tr>
                        </thead>
                            {body}
                    </table>
                </div>
                {search != undefined ? 
                    <div className='alertTableHorizontal'>
                        {linkToSearch}
                        <div dangerouslySetInnerHTML={{ __html: search}}/>
                    </div> 
                : 
                    null
                }
            </div>
        )
    }
});
var AlertHeader = React.createClass({
    render: function() {
        return (
            <th>{this.props.colName}</th>
        )
    }
});
var AlertBody = React.createClass({
    getInitialState: function() {
        return {
            selected: 'un-selected',
            promotedNumber: null,
            showEntry: false,
            promoteFetch:false,
            showAddEntryToolbar: false,
            showFileUpload: false,
            showFileUploadToolbar: false,
        }
    },
    onClick: function(event) {
        if (event.shiftKey == true) {
            this.props.rowClicked(this.props.data.id,this.props.index,'shift',null);
        } else if (event.ctrlKey == true || event.metaKey == true) {
            this.props.rowClicked(this.props.data.id,this.props.index,'ctrl',this.props.data.status)
        } else {
            this.props.rowClicked(this.props.data.id,this.props.index,'',this.props.data.status);
        }
    },
    toggleEntry: function() {
        if (this.state.showEntry == false) {
            this.setState({showEntry: true})
        } else {
            this.setState({showEntry: false})
        }
    },
    toggleOnAddEntry: function() {
        if (this.state.showAddEntryToolbar == false) {
            this.setState({showAddEntryToolbar: true, showEntry:true})
        } 
    },
    toggleOffAddEntry: function() {
        if (this.state.showAddEntryToolbar == true) {
            this.setState({showAddEntryToolbar: false});
            this.props.entryToggle();
        }
    },
    toggleFileUpload: function() {
        if (this.state.showFileUpload == false) {
            this.setState({showFileUpload: true})
        } else {
            this.setState({showFileUpload: false})
        }
    },
    toggleOnFileUpload: function() {
        if (this.state.showFileUploadToolbar == false) {
            this.setState({showFileUploadToolbar: true, showEntry:true})
        }
    },
    toggleOffFileUpload: function() {
        if (this.state.showFileUploadToolbar == true) {
            this.setState({showFileUploadToolbar: false});
            this.props.fileUploadToggle();
        }
    },
    navigateTo: function() {
        window.open('#/event/'+this.state.promotedNumber)
    },
    componentDidMount: function() {
        if (this.props.data.status == 'promoted') {
            $.ajax({
                type: 'GET',
                url: '/scot/api/v2/alert/'+this.props.data.id+ '/event',
                success: function(response){
                    if (this.isMounted()) {
                        this.setState({promotedNumber:response.records[0].id});
                    }
                }.bind(this),
                error: function(data) {
                    this.props.errorToggle('failed to get promoted id' , data)
                }.bind(this)
            })
            
            if (this.isMounted()) {
                this.setState({promoteFetch:true})
            }
        }
        //Pre Selects the alert in an alertgroup if alertPreSelectedId is passed to the component
        if (this.props.alertPreSelectedId != null) {
            if (this.props.alertPreSelectedId == this.props.data.id) {
                this.props.rowClicked(this.props.data.id,this.props.index,'',this.props.data.status);
            }
        }
    },
    componentWillReceiveProps: function(nextProps) {
        if (this.state.promoteFetch == false) {
            if (this.props.data.status == 'promoted') {
                $.ajax({
                    type: 'GET',
                    url: '/scot/api/v2/alert/'+this.props.data.id+ '/event',
                    success: function(response){
                        if (this.isMounted()) {
                            this.setState({promotedNumber:response.records[0].id});             
                        }
                    }.bind(this),
                    error: function(data) {
                        this.props.errorToggle('failed to get promoted id', data);
                    }.bind(this),
                })
                
                if (this.isMounted()) {    
                    this.setState({promoteFetch:true});
                }
            }
        }
        if (this.props.data.id == this.props.aID && nextProps.entryToolbar == true && this.state.showAddEntryToolbar == false) {
            this.toggleOnAddEntry();
        } else if (this.props.data.id != nextProps.aID && nextProps.entryToolbar == true && this.state.showAddEntryToolbar == true) {
            this.toggleOffAddEntry();
        } 
        if (this.props.data.id == this.props.aID && nextProps.fileUploadToolbar == true && this.state.showFileUploadToolbar == false) {
            this.toggleOnFileUpload();
        } else if (this.props.data.id != nextProps.aID && nextProps.fileUploadToolbar == true && this.state.showFileUploadToolbar == true) {
            this.toggleOffFileUpload();
        }
    },
    render: function() {
        var data = this.props.data;
        var headerData = this.props.headerData;
        var dataFlair = this.props.dataFlair;
        var index = this.props.index;
        var columns;
        var selected = 'un-selected'
        var rowReturn=[];
        var buttonStyle = '';
        var open = '';
        var closed = '';
        var promoted = '';
        if (data.status == 'open') {
            buttonStyle = 'red';
        } else if (data.status == 'closed') {
            buttonStyle = 'green';
        } else if (data.status == 'promoted') {
            buttonStyle = 'warning';
        }
        
        if (columns == undefined) {
            if (data.columns != undefined) {
                if (data.columns.length != 0) {
                    columns = data.columns
                } 
            }
        }
        if (columns == undefined) {
            if (data.data != undefined) {
                if (data.data.columns != undefined) {
                    if (data.data.columns.length != 0) {
                        columns = data.data.columns
                    }
                }
            }
        }
        if (columns == undefined) {
            if (this.props.headerData != undefined) {
                if (this.props.headerData.length != 0) {
                    columns = this.props.headerData.columns;
                } else {
                    console.log('Error finding columns in JSON'); 
                }
            }
        }
        
        for (var i=0; i < columns.length; i++) {
            var value = columns[i];
            rowReturn.push(<AlertRow data={data} dataFlair={dataFlair} value={value} />)
        }
        if (this.props.allSelected == false) {
            for (var j=0; j < this.props.activeId.length; j++) {
                if (this.props.activeId[j] === data.id) {
                    selected = 'selected';
                } 
            }
        } else {
            selected = 'selected'
        }
        var id = 'alert_'+data.id+'_status';
        return (
            <tbody>
                <tr id={data.id} className={'main ' + selected} style={{cursor: 'pointer'}} onMouseDown={this.onClick}>
                    <td style={{marginRight:'4px'}}>{data.id}</td>
                    <td style={{marginRight:'4px'}}>{data.status != 'promoted' ? <span style={{color:buttonStyle}}>{data.status}</span> : <Button bsSize='xsmall' bsStyle={buttonStyle} id={id} onMouseDown={this.navigateTo} style={{lineHeight: '12pt', fontSize: '10pt', marginLeft: 'auto'}}>{data.status}</Button>}</td>
                    {data.entry_count == 0 ? <td style={{marginRight:'4px'}}>{data.entry_count}</td> : <td style={{marginRight:'4px'}}><span style={{color: 'blue', textDecoration: 'underline', cursor: 'pointer'}} onMouseDown={this.toggleEntry}>{data.entry_count}</span></td>}
                    {rowReturn}
                </tr>
                <AlertRowBlank id={data.id} type={'alert'} showEntry={this.state.showEntry} aID={this.props.aID} aType={this.props.aType} updated={this.props.updated} showAddEntryToolbar={this.state.showAddEntryToolbar} toggleOffAddEntry={this.toggleOffAddEntry} showFileUploadToolbar={this.state.showFileUploadToolbar} toggleOffFileUpload={this.toggleOffFileUpload} errorToggle={this.props.errorToggle}/>
            </tbody>
        )
    }
});
var AlertRow = React.createClass({
    render: function() {
        var data = this.props.data;
        var dataFlair = this.props.dataFlair;
        var value = this.props.value;
        
        let rowContent = dataFlair[value];
        
        if ( Array.isArray( dataFlair[value] )) {
            for ( let i = 0; i < dataFlair[value].length; i++ ) {
                rowContent = $('<div>').text(dataFlair[value][i]).html();
            }
        };

        return (
            <td style={{marginRight:'4px'}}>
                <div className='alert_data_cell' dangerouslySetInnerHTML={{ __html: rowContent}}/>
            </td>
        )
    }
});
var AlertRowBlank = React.createClass({
    render: function() {
        var id = this.props.id;
        var showEntry = this.props.showEntry;
        var showAddEntryToolbar = this.props.showAddEntryToolbar;
        var showFileUploadToolbar = this.props.showFileUploadToolbar;
        var DisplayValue = 'none';
        var arr = [];
        arr.push(<SelectedEntry type={this.props.type} id={this.props.id} errorToggle={this.props.errorToggle}/>)
        if (showEntry == true) {
            DisplayValue = 'table-row';
        } 
        return (
            <tr className='not_selectable' style={{display:DisplayValue}}>
                <td colSpan="50">
                    {showEntry ? <div>{<SelectedEntry type={this.props.type} id={this.props.id} errorToggle={this.props.errorToggle}/>}</div> : null}
                    {showAddEntryToolbar ? <AddEntry entryAction={'Add'} type={this.props.type} targetid={this.props.id} id={null} addedentry={this.props.toggleOffAddEntry} updated={this.props.updated} errorToggle={this.props.errorToggle}/> : null}
                    {showFileUploadToolbar ? <FileUpload type={this.props.aType} targetid={this.props.id} errorToggle={this.props.errorToggle} fileUploadToggle={this.props.toggleOffFileUpload}/> : null} 
                </td>
            </tr>
        )
    }
});
var EntryParent = React.createClass({
    getInitialState: function() {
        return {
            editEntryToolbar:false,
            replyEntryToolbar:false,
            deleteToolbar:false,
            permissionsToolbar:false,
            fileUploadToolbar: false,
            showEntityCreateModal: false,
            highlightedText: null,
        }
    }, 
    componentDidMount: function() {
        Store.storeKey(this.props.items.id);
        Store.addChangeListener(this.refreshButton);
    },
    //TODO modify manual entry refresh to be done on automatically based on STOMP single entry update. This works for now.
    refreshButton: function() {
        if ($('#refresh-detail')) {
            $('#refresh-detail').click();
        }
    },
    editEntryToggle: function() {
        if (this.state.editEntryToolbar == false) {
            this.setState({editEntryToolbar:true})
        } else {
            this.setState({editEntryToolbar:false})
        }
    },
    replyEntryToggle: function() {
        if (this.state.replyEntryToolbar == false) {
            this.setState({replyEntryToolbar:true})
        } else {
            this.setState({replyEntryToolbar:false})
        }
    },
    deleteToggle: function() {
        if (this.state.deleteToolbar == false) {
            this.setState({deleteToolbar:true})
        } else {
            this.setState({deleteToolbar:false})
        }
    },
    permissionsToggle: function() {
        if (this.state.permissionsToolbar == false) {
            this.setState({permissionsToolbar:true})
        } else {
            this.setState({permissionsToolbar:false})
        }
    },
    reparseFlair: function() {
        $.ajax({
            type: 'put',
            url: '/scot/api/v2/entry/'+this.props.items.id,
            data: JSON.stringify({parsed:0}),
            contentType: 'application/json; charset=UTF-8',
            success: function(response){
                console.log('reparsing started');
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('failed to start reparsing of data', data)
            }.bind(this)
        })
    },
    fileUploadToggle: function() {
        if (this.state.fileUploadToolbar == false) {
            this.setState({fileUploadToolbar:true});
        } else {
            this.setState({fileUploadToolbar:false});
        }
    },
    render: function() {
        var itemarr = [];
        var subitemarr = [];
        var items = this.props.items;
        var type = this.props.type;
        var id = this.props.id;
        var isPopUp = this.props.isPopUp;
        var itemsClass = this.props.items.class;
        var summary = 0;                                        //define Summary as false unless itemsClass is "summary"
        var editEntryToolbar = this.state.editEntryToolbar;
        var editEntryToggle = this.editEntryToggle;
        var errorToggle=this.props.errorToggle;
        var outerClassName = 'row-fluid entry-outer';
        var innerClassName = 'row-fluid entry-header';
        var taskOwner = '';
        if (itemsClass == 'summary') {
            outerClassName += ' summary_entry';
            summary = 1;
        }
        if (itemsClass == 'task') {
            if (items.metadata.task.status == 'open' || items.metadata.task.status == 'assigned') {
                taskOwner = '-- Task Owner ' + items.metadata.task.who + ' ';
                outerClassName += ' todo_open_outer';
                innerClassName += ' todo_open';
            } else if ((items.metadata.task.status == 'closed' || items.metadata.task.status == 'completed') && items.metadata.task.who != null ) {
                taskOwner = '-- Task Owner ' + items.metadata.task.who + ' ';
                outerClassName += ' todo_completed_outer';
                innerClassName += ' todo_completed';
            } else if (items.metadata.task.status == 'closed' || items.metadata.task.status == 'completed') {
                outerClassName += ' todo_undefined_outer';
                innerClassName += ' todo_undefined';
            }
        }
        if (itemsClass == 'alert') {
            outerClassName += ' event_entry_container_alert'
        }
        itemarr.push(<EntryData id={items.id} key={items.id} subitem = {items} type={type} targetid={id} editEntryToolbar={editEntryToolbar} editEntryToggle={editEntryToggle} isPopUp={isPopUp} errorToggle={this.props.errorToggle} />);
        for (var prop in items) {
            function childfunc(prop){
                if (prop == "children") {
                    var childobj = items[prop];
                    items[prop].forEach(function(childobj) {
                        subitemarr.push(new Array(<EntryParent items = {childobj} id={id} type={type} editEntryToolbar={editEntryToolbar} editEntryToggle={editEntryToggle} isPopUp={isPopUp} errorToggle={errorToggle}/>));  
                    });
                }
            }
            childfunc(prop);
        };
        itemarr.push(subitemarr);

        let entryActions = [];
        if ( this.props.items ) {
            if ( this.props.items.actions ) {
                for ( let i = 0; i < this.props.items.actions.length; i++ ) {
                    if ( this.props.items.actions[i].send_to_name && this.props.items.actions[i].send_to_url ) {
                        entryActions.push(<EntryAction 
                            id={this.props.items.actions[i].send_to_name} 
                            datahref={this.props.items.actions[i].send_to_url} 
                            errorToggle={this.props.errorToggle}
                            />
                        )
                    }
                }
            }
        }

        var header1 = '[' + items.id + '] ';
        var header2 = ' by ' + items.owner + ' ' + taskOwner + '(updated on '; 
        var header3 = ')'; 
        var createdTime = items.created;
        var updatedTime = items.updated; 
        let entryHeaderInnerId = 'entry-header-inner-' + this.props.id + ' entry-header-inner';

        return (
            <div> 
                { this.state.showEntityCreateModal ? <EntityCreateModal match={this.state.highlightedText} modalActive={this.state.showEntityCreateModal} ToggleCreateEntity = {this.ToggleCreateEntity} errorToggle={this.props.errorToggle}/> : null }
                <div className={outerClassName} style={{marginLeft: 'auto', marginRight: 'auto', width:'99.3%'}}>
                    <span className="anchor" id={"/"+ type + '/' + id + '/' + items.id}/>
                    <div className={innerClassName}>
                        <div id={entryHeaderInnerId} className={entryHeaderInnerId}>[<Link style={{color:'black'}} to={'/' + type + '/' + id + '/' + items.id}>{items.id}</Link>] <ReactTime value={items.created * 1000} format="MM/DD/YYYY hh:mm:ss a" /> by {items.owner} {taskOwner}(updated on <ReactTime value={items.updated * 1000} format="MM/DD/YYYY hh:mm:ss a" />)
                            { this.state.highlightedText != '' && this.state.highlightedText != null ? <Button bsSize='xsmall' bsStyle='success' onClick={this.ToggleCreateEntity}>Create Entity</Button> : null }
                            { this.props.items.body_flair != '' && this.props.items.parsed == 0 ? <span style={{color: 'green', fontWeight: 'bold' }}> Entry awaiting flair engine. Content may be inaccurate.</span> : null }
                            <span className='pull-right' style={{display:'inline-flex',paddingRight:'3px'}}>
                                {this.state.permissionsToolbar ? <SelectedPermission updateid={id} id={items.id} type={'entry'} permissionData={items} permissionsToggle={this.permissionsToggle} /> : null}
                                <SplitButton bsSize='xsmall' title="Reply" key={items.id} id={'Reply '+items.id} onClick={this.replyEntryToggle} pullRight> 
                                    { type != 'entity' ? <MenuItem eventKey='1' onClick={this.fileUploadToggle}>Upload File</MenuItem> : null}
                                    {entryActions}
                                    <MenuItem eventKey='3'><Summary type={type} id={id} entryid={items.id} summary={summary} errorToggle={this.props.errorToggle}/></MenuItem>
                                    <MenuItem eventKey='4'><Task type={type} id={id} entryid={items.id} taskData={items} errorToggle={this.props.errorToggle} /></MenuItem>
                                    <Marker type={'entry'} id={items.id} string={items.body_plain} />
                                    <MenuItem onClick={this.permissionsToggle}>Permissions</MenuItem>
                                    <MenuItem onClick={this.reparseFlair}>Reparse Flair</MenuItem>
                                    <TrafficLightProtocol type={'entry'} id={items.id} tlp={items.tlp} errorToggle={this.props.errorToggle} />
                                    <MenuItem divider />
                                    <MenuItem eventKey='2' onClick={this.deleteToggle}>Delete</MenuItem>
                                </SplitButton>
                                <Button bsSize='xsmall' onClick={this.editEntryToggle}>Edit</Button>
                            </span>
                        </div>
                    </div>
                {itemarr}
                {this.state.replyEntryToolbar ? <AddEntry entryAction={'Reply'} type = {type} header1={header1} header2={header2} header3={header3} createdTime={createdTime} updatedTime={updatedTime} targetid={id} id={items.id} addedentry={this.replyEntryToggle} errorToggle={this.props.errorToggle} /> : null}
                {this.state.fileUploadToolbar ? <FileUpload type={this.props.type} targetid={this.props.id} entryid={this.props.items.id} fileUploadToggle={this.fileUploadToggle} errorToggle={this.props.errorToggle}/> : null}
                </div> 
                {this.state.deleteToolbar ? <DeleteEntry type={type} id={id} deleteToggle={this.deleteToggle} entryid={items.id} errorToggle={this.props.errorToggle} /> : null}     
            </div>
        );
    },

    componentWillReceiveProps: function() {
        this.checkHighlight();
    },

    checkHighlight: function() {
        let content;
        let iframe = document.getElementById('iframe_' + this.props.items.id);
        if ( iframe ) {
            content = iframe.contentWindow.getSelection().toString();
            if ( this.state.highlightedText != content ) {
                console.log(iframe + ' has highlighted text: ' + content);
                this.setState({highlightedText: content });
            } else {
                return;
            }
        }
    },

    ToggleCreateEntity: function() {
        this.setState({ showEntityCreateModal: !this.state.showEntityCreateModal });
    },

});

let EntryAction = React.createClass({
    getInitialState: function() {

        return {
            [this.props.id] : false,
            disabled: false,
        }        
    },

    submit: function() {
        let url = this.props.datahref;
        let id = this.props.id;
        
        $.ajax({
            type: 'post',
            url: url,
            success: function(response) {
                this.setState({ [id]: true, disabled: false });
                console.log('submitted the entry action');
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('failed to submit the entry action', data);
                this.setState({ disabled: false });
            }.bind(this),
        });
        this.setState({ disabled: true });
    },
    
    render: function() {
        return (
            <MenuItem disabled={this.state.disabled} >
                <span id={this.props.id} data-href={this.props.datahref} onClick={this.submit} style={{display:'block'}}>{this.props.id} { 
                    this.state[this.props.id] ? 
                        <span style={{color: 'green'}}>success</span> 
                    : 
                        null
                    }
                </span>
            </MenuItem> 
        )
    }
});

var EntryData = React.createClass({ 
    getInitialState: function() {
        /*if (this.props.type == 'entity' || this.props.isPopUp == 1) {
            return {
                height: '250px',
            }
        }*/
        return {
            height:'1px',
        }
    }, 
    onLoad: function() {
        if (document.getElementById('iframe_'+this.props.id) != undefined){
            if (document.getElementById('iframe_'+this.props.id).contentDocument.readyState === 'complete') {
                var ifr = $('#iframe_'+this.props.id);
                var ifrContents = $(ifr).contents();
                var ifrContentsHead = $(ifrContents).find('head');
                if (ifrContentsHead) {
                    if (!$(ifrContentsHead).find('link')) {
                        ifrContentsHead.append($("<link/>", {rel: "stylesheet", href: 'css/sandbox.css', type: "text/css"}))
                    }
                }
                //if (this.props.type != 'entity') {
                    setTimeout(function() {
                        if (document.getElementById('iframe_'+this.props.id) != undefined) {
                            document.getElementById('iframe_'+this.props.id).contentWindow.requestAnimationFrame( function() {
                                var newheight; 
                                newheight = document.getElementById('iframe_'+this.props.id).contentWindow.document.body.scrollHeight;
                                newheight = newheight + 'px';
                                if (this.state.height != newheight) {
                                    this.setState({height:newheight});
                                }
                            }.bind(this))
                        }
                    }.bind(this),250); 
                //}
            } else {
                setTimeout(this.onLoad,0);
            }
        }
    },
    componentWillReceiveProps: function() {
        this.onLoad();
    },
    render: function() {
        var rawMarkup = this.props.subitem.body_flair;
        if (this.props.subitem.body_flair == '') {
            rawMarkup = this.props.subitem.body;
        }
        var id = this.props.id;
        var entry_body_id = 'entry-body-' + this.props.id;
        var entry_body_inner_id = 'entry-body-inner-' + this.props.id;
        return (
            <div id={entry_body_id} key={this.props.id} className={'row-fluid entry-body'}>
                <div id={entry_body_inner_id} className={'row-fluid entry-body-inner'} style={{marginLeft: 'auto', marginRight: 'auto', width:'99.3%'}}>
                    {this.props.editEntryToolbar ? <AddEntry entryAction={'Edit'} type={this.props.type} targetid={this.props.targetid} id={id} addedentry={this.props.editEntryToggle} parent={this.props.subitem.parent} errorToggle={this.props.errorToggle} /> : 
                    <Frame frameBorder={'0'} id={'iframe_' + id} sandbox={'allow-same-origin'} styleSheets={['/css/sandbox.css']} style={{width:'100%',height:this.state.height}}> 
                        <div dangerouslySetInnerHTML={{ __html: rawMarkup}}/>
                    </Frame>}
                </div>
            </div>
        )
    },
    componentDidMount: function() {
        this.onLoad();
    },
});
module.exports = SelectedEntry;
