var React                   = require('react');
var ReactDOM                = require('react-dom');
var ReactTime               = require('react-time');
var SplitButton             = require('react-bootstrap/lib/SplitButton.js');
var DropdownButton          = require('react-bootstrap/lib/DropdownButton.js');
var MenuItem                = require('react-bootstrap/lib/MenuItem.js');
var Button                  = require('react-bootstrap/lib/Button.js');
var AddEntryModal           = require('../modal/add_entry.jsx');
var DeleteEntry             = require('../modal/delete.jsx').DeleteEntry;
var Summary                 = require('../components/summary.jsx');
var Task                    = require('../components/task.jsx');
var SelectedPermission      = require('../components/permission.jsx');
var Frame                   = require('react-frame');
var Store                   = require('../activemq/store.jsx');
var AppActions              = require('../flux/actions.jsx');
var AddFlair                = require('../components/add_flair.jsx').AddFlair;
var Watcher                 = require('../components/add_flair.jsx').Watcher;
var Flair                   = require('../modal/flair_modal.jsx');
var LinkWarning             = require('../modal/link_warning.jsx'); 
var SelectedHeaderOptions   = require('./selected_header_options.jsx');

var SelectedEntry = React.createClass({
    getInitialState: function() {
        return {
            showEntryData:this.props.showEntryData,
            showEntityData:this.props.showEntityData,
            entryData:this.props.entryData,
            entityData:this.props.entityData,
            key:this.props.id,
            flairToolbar:false,
        }
    },
    componentDidMount: function() {
        if (this.props.type == 'alert' || this.props.type == 'entity') {
            this.headerRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id + '/entry', function(result) {
                var entryResult = result.records;
                this.setState({showEntryData:true, entryData:entryResult})
                for (i=0; i < result.records.length; i++) {
                    Store.storeKey(result.records[i].id)
                    Store.addChangeListener(this.updatedCB);
                }
                Watcher.pentry(null,this.flairToolbarToggle,this.props.type,this.linkWarningToggle,this.props.id,null)
            }.bind(this));
            this.entityRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id + '/entity', function(result) {
                var entityResult = result.records;
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
            }.bind(this)); 
        Store.storeKey(this.props.id);
        Store.addChangeListener(this.updatedCB);
        } 
    }, 
    updatedCB: function() {
       if (this.props.type == 'alert' || this.props.type == 'entity') {
            this.headerRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id + '/entry', function(result) {
                var entryResult = result.records;
                this.setState({showEntryData:true, entryData:entryResult})
                for (i=0; i < result.records.length; i++) {
                    Store.storeKey(result.records[i].id)
                    Store.addChangeListener(this.updatedCB);
                }
                Watcher.pentry(null,this.flairToolbarToggle,this.props.type,this.linkWarningToggle,this.props.id,null)
            }.bind(this));
            this.entityRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id + '/entity', function(result) {
                var entityResult = result.records;
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
            }.bind(this)); 
        }
    },
    flairToolbarToggle: function(id,value) {
        if (this.state.flairToolbar == false) {
            this.setState({flairToolbar:true,entityid:id,entityvalue:value})
        } else {
            this.setState({flairToolbar:false})
        }
    },
    linkWarningToggle: function(href) {
        if (this.state.linkWarningToolbar == false) {
            this.setState({linkWarningToolbar:true,link:href})
        } else {
            this.setState({linkWarningToolbar:false})
        }
    },
    render: function() { 
        var data = this.props.entryData;
        var type = this.props.type;
        var id = this.props.id;
        var showEntryData = this.props.showEntryData;
        var divClass = 'row-fluid entry-wrapper entry-wrapper-main'
        if (type =='alert' || type == 'entity') {
            //default size commented out for now
            //divClass = 'row-fluid entry-wrapper entry-wrapper-main-70'
            divClass= 'row-fluid entry-wrapper-main-nh';
            data = this.state.entryData;
            showEntryData = this.state.showEntryData;
        } else if (type =='alertgroup') {
            divClass = 'row-fluid alert-wrapper entry-wrapper-main';
        }
        return (
            <div className={divClass} style={{height:this.props.windowHeight}}> 
                {this.props.entryToolbar ? <div>{this.props.isAlertSelected == false ? <AddEntryModal title={'Add Entry'} type={this.props.type} targetid={this.props.id} id={this.props.id} addedentry={this.props.entryToggle} updated={this.updatedCB}/> : <AddEntryModal title={'Add Entry'} type={this.props.aType} targetid={this.props.aID} addedentry={this.props.entryToggle} updated={this.updatedCB}/> }</div> : null}
                {showEntryData ? <EntryIterator data={data} type={type} id={id} alertSelected={this.props.alertSelected} headerData={this.props.headerData}/> : <span>Loading...</span>} 
                {this.state.flairToolbar ? <Flair flairToolbarToggle={this.flairToolbarToggle} entityid={this.state.entityid} entityvalue={this.state.entityvalue}/> : null}
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
        if (type != 'alertgroup') {
            data.forEach(function(data) {
                rows.push(<EntryParent key={data.id} items={data} type={type} id={id} />);
            }.bind(this));
        } else {
            rows.push(<AlertParent items={data} type={type} id={id} headerData={this.props.headerData} alertSelected={this.props.alertSelected} />);
        }
        return (
            <div>
                {rows}
            </div>
        )
    }
});

var AlertParent = React.createClass({
    getInitialState: function() {
        var arr = [];
        return {
            activeIndex: arr,
            lastIndex: null,
            allSelected:false,
        }
    },
    componentDidMount: function() {
        $('#sortabletable').tablesorter();
        
        //Ctrl + A to select all alerts
        $(document.body).keydown(function(event){
            //prevent from working when in input
            if ($('input').is(':focus')) {return};
            //check for ctrl + a with keyCode 
            if (event.keyCode == 65 && (event.ctrlKey == true || event.metaKey == true)) {
                this.rowClicked(null,null,'all',null);
                event.preventDefault()
            }
        }.bind(this)) 
    },
    rowClicked: function(id,index,clickType,status) {
        var array = this.state.activeIndex.slice();
        var selected = true;
        this.setState({allSelected:false});
        if (clickType == 'ctrl') {
            for (var i=0; i < array.length; i++) {
                if (array[i] === index) {
                    array.splice(i,1)
                    this.setState({activeIndex:array})
                    selected = false;
                }
            }
            if (selected == true) {
                array.push(index);
                this.setState({activeIndex:array})
            }
        } else if (clickType == 'shift') {
            if (this.state.lastIndex != undefined) {
                var min = Math.min(this.state.lastIndex,index);
                var max = Math.max(this.state.lastIndex,index);
                var min = max - min + 1;
                var range = [];
                while (min--) {
                    range[min]=max--;
                }
                for (i=0; i < range.length; i++) {
                    array.push(range[i]);
                }
                this.setState({activeIndex:array})
            }
        } else if (clickType == 'all') {
            var array = [];
            for (var i=0; i < this.props.items.length; i++) {
                array.push(this.props.items[i].id)
            }
            this.setState({activeIndex:array,allSelected:true});
        } else {
            var array = [];
            array.push(index);
            this.setState({activeIndex:array});
        }
        this.setState({lastIndex:index});
        if (array.length == 1) {
            this.props.alertSelected(array[0],id,'alert');
        } else if (array.length == 0){   
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
        if (items[0] != undefined){
            var col_names;
            //checking two locations for columns. Will make this a single location in future revision
            if (items[0].columns.length != 0) { 
                col_names = items[0].columns.slice(0) //slices forces a copy of array
            } else if (items[0].data.columns.length != 0) {
                col_names = items[0].data.columns.slice(0)
            } else {
                console.log('Error finding columns in JSON');
            }
            col_names.unshift('entries'); //Add entries to 3rd column
            col_names.unshift('status'); //Add status to 2nd column
            col_names.unshift('id'); //Add entries number to 1st column
            for (var i=0; i < col_names.length; i++){
                header.push(<AlertHeader colName={col_names[i]} />)
            }
            for (var z=0; z < items.length; z++) {
                var dataFlair = null;
                if (Object.getOwnPropertyNames(items[z].data_with_flair).length != 0) {
                    dataFlair = items[z].data_with_flair;
                } else {
                    dataFlair = items[z].data;
                }
                
                body.push(<AlertBody index={z} data={items[z]} dataFlair={dataFlair} activeIndex={this.state.activeIndex} rowClicked={this.rowClicked} alertSelected={this.props.alertSelected} allSelected={this.state.allSelected}/>)
            }
            var search = null;
            if (items[0].data_with_flair != undefined) {
                search = items[0].data_with_flair.search;
            } else {
                search = items[0].data.search;
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
                        <tbody>
                            {body}
                        </tbody>
                    </table>
                </div>
                {search != undefined ? <div className='alertTableHorizontal' dangerouslySetInnerHTML={{ __html: search}}/> : null}
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
    navigateTo: function() {
        window.open('#/event/'+this.state.promotedNumber)
    },
    componentDidMount: function() {
        if (this.props.data.status == 'promoted') {
            $.ajax({
                type: 'GET',
                url: '/scot/api/v2/alert/'+this.props.data.id+ '/event'
            }).success(function(response){
                this.setState({promotedNumber:response.records[0].id});             
            }.bind(this))
            this.setState({promoteFetch:true})
        }
        
    },
    componentWillReceiveProps: function() {
        if (this.state.promoteFetch == false) {
            if (this.props.data.status == 'promoted') {
                $.ajax({
                    type: 'GET',
                    url: '/scot/api/v2/alert/'+this.props.data.id+ '/event'
                }).success(function(response){
                    this.setState({promotedNumber:response.records[0].id});             
                }.bind(this))
                this.setState({promoteFetch:true});
            }
        }
    },
    render: function() {
        var data = this.props.data;
        var dataFlair = this.props.dataFlair;
        var index = this.props.index;
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
        var columns;
        if (data.columns.length != 0) {
            columns = data.columns
        } else if (data.data.columns.length != 0) {
            columns = data.data.columns
        } else {
            console.log('Error finding columns in JSON');
        }
        for (var i=0; i < columns.length; i++) {
            var value = columns[i];
            rowReturn.push(<AlertRow data={data} dataFlair={dataFlair} value={value} />)
        }
        if (this.props.allSelected == false) {
            for (var j=0; j < this.props.activeIndex.length; j++) {
                if (this.props.activeIndex[j] === index) {
                    selected = 'selected';
                } 
            }
        } else {
            selected = 'selected'
        }
        var id = 'alert_'+data.id+'_status';
        return (
            <div>
                <tr index={index} id={data.id} className={selected} style={{cursor: 'pointer'}} onClick={this.onClick}>
                    <td valign='top' style={{marginRight:'4px'}}>{data.id}</td>
                    <td valign='top' style={{marginRight:'4px'}}>{data.status != 'promoted' ? <span style={{color:buttonStyle}}>{data.status}</span> : <Button bsSize='xsmall' bsStyle={buttonStyle} id={id} onClick={this.navigateTo} style={{lineHeight: '12pt', fontSize: '10pt', marginLeft: 'auto'}}>{data.status}</Button>}</td>
                    {data.entry_count == 0 ? <td valign='top' style={{marginRight:'4px'}}>{data.entry_count}</td> : <td valign='top' style={{marginRight:'4px'}}><a href="javascript: void(0)" onClick={this.toggleEntry}>{data.entry_count}</a></td>}
                    {rowReturn}
                </tr>
                <AlertRowBlank id={data.id} type={'alert'} showEntry={this.state.showEntry} />
            </div>
        )
    }
});

var AlertRow = React.createClass({
    render: function() {
        var data = this.props.data;
        var dataFlair = this.props.dataFlair;
        var value = this.props.value;
        var rowReturn=[];
        return (
            <td valign='top' style={{marginRight:'4px'}}>
                <div className='alert_data_cell' dangerouslySetInnerHTML={{ __html: dataFlair[value]}}/>
            </td>
        )
    }
});

AlertRowBlank = React.createClass({
    render: function() {
        var id = this.props.id;
        var showEntry = this.props.showEntry;
        var arr = [];
        arr.push(<SelectedEntry type={this.props.type} id={this.props.id} />)
        return (
            <tr className='not_selectable'>
                <td style={{padding:'0'}}>
                </td>
                <td colSpan="50" style={{padding:'1px'}}>
                    {showEntry ? <div>{arr}</div> : null}
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
    render: function() {
        var itemarr = [];
        var subitemarr = [];
        var items = this.props.items;
        var type = this.props.type;
        var id = this.props.id;
        var summary = items.summary;
        var outerClassName = 'row-fluid entry-outer';
        var innerClassName = 'row-fluid entry-header';
        var taskOwner = '';
        if (summary == 1) {
            outerClassName += ' summary_entry';
        }
        if (items.task.status == 'open' || items.task.status == 'assigned') {
            taskOwner = '-- Task Owner ' + items.task.who + ' ';
            outerClassName += ' todo_open_outer';
            innerClassName += ' todo_open';
        } else if (items.task.status == 'closed' && items.task.who != null ) {
            taskOwner = '-- Task Owner ' + items.task.who + ' ';
            outerClassName += ' todo_completed_outer';
            innerClassName += ' todo_completed';
        } else if (items.task.status == 'closed') {
            outerClassName += ' todo_undefined_outer';
            innerClassName += ' todo_undefined';
        }
        itemarr.push(<EntryData id={items.id} key={items.id} subitem = {items} type={type} targetid={id} />);
        for (var prop in items) {
            function childfunc(prop){
                if (prop == "children") {
                    var childobj = items[prop];
                    items[prop].forEach(function(childobj) {
                        subitemarr.push(new Array(<EntryParent  items = {childobj} id={id} type={type} />));  
                    });
                }
            }
            childfunc(prop);
        };
        itemarr.push(subitemarr);
        var header1 = '[' + items.id + '] ';
        var header2 = ' by ' + items.owner + ' ' + taskOwner + '(updated on '; 
        var header3 = ')'; 
        var createdTime = items.created;
        var updatedTime = items.updated; 
        return (
            <div> 
                <div className={outerClassName} style={{marginLeft: 'auto', marginRight: 'auto', width:'99.3%'}}>
                    <span className="anchor" id={"/"+ type + '/' + id + '/' + items.id}/>
                    <div className={innerClassName}>
                        <div className="entry-header-inner">[<a style={{color:'black'}} href={"#/"+ type + '/' + id + '/' + items.id}>{items.id}</a>] <ReactTime value={items.created * 1000} format="MM/DD/YYYY hh:mm:ss a" /> by {items.owner} {taskOwner}(updated on <ReactTime value={items.updated * 1000} format="MM/DD/YYYY hh:mm:ss a" />)
                            <span className='pull-right' style={{display:'inline-flex',paddingRight:'3px'}}>
                                {this.state.permissionsToolbar ? <SelectedPermission updateid={id} id={items.id} type={'entry'} permissionData={items} permissionsToggle={this.permissionsToggle} /> : null}
                                <SplitButton bsSize='xsmall' title="Reply" key={items.id} id={'Reply '+items.id} onClick={this.replyEntryToggle} pullRight> 
                                    <MenuItem eventKey='2' onClick={this.deleteToggle}>Delete</MenuItem>
                                    <MenuItem eventKey='3'><Summary type={type} id={id} entryid={items.id} summary={summary} /></MenuItem>
                                    <MenuItem eventKey='4'><Task type={type} id={id} entryid={items.id} taskData={items.task} /></MenuItem>
                                    <MenuItem eventKey='5' onClick={this.permissionsToggle}>Permissions</MenuItem>
                                </SplitButton>
                                <Button bsSize='xsmall' onClick={this.editEntryToggle}>Edit</Button>
                            </span>
                        </div>
                    </div>
                {this.state.editEntryToolbar ? <AddEntryModal type = {this.props.type} title='Edit Entry' header1={header1} header2={header2} header3={header3} createdTime={createdTime} updatedTime={updatedTime} parent={items.parent} targetid={id} type={type} stage = {'Edit'} id={items.id} addedentry={this.editEntryToggle} /> : null}
                {itemarr}
                {this.state.replyEntryToolbar ? <AddEntryModal title='Reply Entry' stage = {'Reply'} type = {type} header1={header1} header2={header2} header3={header3} createdTime={createdTime} updatedTime={updatedTime} targetid={id} id={items.id} addedentry={this.replyEntryToggle} /> : null}
                </div> 
                {this.state.deleteToolbar ? <DeleteEntry type={type} id={id} deleteToggle={this.deleteToggle} entryid={items.id} /> : null}     
            </div>
        );
    }
});

var EntryData = React.createClass({ 
    getInitialState: function() {
        if (this.props.type == 'entity') {
            return {
                height: '250px',
            }
        }
        return {
            height:'1px',
        }
    }, 
    onLoad: function() {
        if (document.getElementById('iframe_'+this.props.id).contentDocument.readyState === 'complete') {
            if (this.props.type != 'entity') {
                setTimeout(function() {
                    document.getElementById('iframe_'+this.props.id).contentWindow.requestAnimationFrame( function() {
                        var newheight; 
                        newheight = document.getElementById('iframe_'+this.props.id).contentWindow.document.body.scrollHeight;
                        newheight = newheight + 'px';
                        if (this.state.height != newheight) {
                            this.setState({height:newheight});
                        }
                    }.bind(this))
                }.bind(this)); 
            }
            var ifr = $('#iframe_'+this.props.id);
            var ifrContents = $(ifr).contents();
            var ifrContentsHead = $(ifrContents).find('head');
            if (ifrContentsHead) {
                ifrContentsHead.append($("<link/>", {rel: "stylesheet", href: 'css/sandbox.css', type: "text/css"}))
            }
        } else {
            setTimeout(this.onLoad,0);
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
        return (
            <div key={this.props.id} className={'row-fluid entry-body'}>
                <div className={'row-fluid entry-body-inner'} style={{marginLeft: 'auto', marginRight: 'auto', width:'99.3%'}}>
                    <Frame frameBorder={'0'} id={'iframe_' + id} sandbox={'allow-same-origin'} styleSheets={['/css/sandbox.css']} style={{width:'100%',height:this.state.height}}>
                    <div dangerouslySetInnerHTML={{ __html: rawMarkup}}/>
                    </Frame>
                </div>
            </div>
        )
    },
    componentDidMount: function() {
        this.onLoad();
    },
});

module.exports = SelectedEntry
