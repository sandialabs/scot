var React               = require('react');
var ReactTime           = require('react-time');
var SplitButton         = require('react-bootstrap/lib/SplitButton.js');
var DropdownButton      = require('react-bootstrap/lib/DropdownButton.js');
var MenuItem            = require('react-bootstrap/lib/MenuItem.js');
var Button              = require('react-bootstrap/lib/Button.js');
var AddEntryModal       = require('../modal/add_entry.jsx');
var DeleteEntry         = require('../modal/delete.jsx').DeleteEntry;
var Summary             = require('../components/summary.jsx');
var Task                = require('../components/task.jsx');
var SelectedPermission  = require('../components/permission.jsx');
var Frame               = require('react-frame');

var SelectedEntry = React.createClass({
    getInitialState: function() {
        return {
            showEntryData:false,
            entryData:''            
        }
    },
    componentDidMount: function() {
        this.headerRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id + '/entry', function(result) {
            var entryResult = result.records;
            this.setState({showEntryData:true, entryData:entryResult})
        }.bind(this));
    },
    updated: function () {
        this.headerRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id + '/entry', function(result) {
            var entryResult = result.records;
            this.setState({showEntryData:true, entryData:entryResult})
        }.bind(this));
        console.log('Ran update');
    },
    render: function() { 
        var data = this.state.entryData; 
        var type = this.props.type;
        var id = this.props.id;
        return (
            <div className="row-fluid entry-wrapper"> 
                {this.state.showEntryData ? <EntryIterator data={data} type={type} id={id} updated={this.updated} /> : null}
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
        var updated = this.props.updated;
        data.forEach(function(data) {
            rows.push(<EntryParent items={data} type={type} id={id} updated={updated} />);
        });
        return (
            <div>
                {rows}
            </div>
        )
    }
});

var EntryParent = React.createClass({
    getInitialState: function() {
        return {
            addEntryToolbar:false,   
            editEntryToolbar:false,
            replyEntryToolbar:false,
            deleteToolbar:false,
            permissionsToolbar:false,
        }
    },
    addEntryToggle: function() {
        if (this.state.addEntryToolbar == false) {
            this.setState({addEntryToolbar:true})
        } else {
            this.setState({addEntryToolbar:false})
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
        var updatedcallback = this.props.updated;
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
        itemarr.push(<EntryData subitem = {items}/>);
        for (var prop in items) {
            function childfunc(prop){
                if (prop == "children") {
                    var childobj = items[prop];
                    items[prop].forEach(function(childobj) {
                        subitemarr.push(new Array(<EntryParent items = {childobj} updated={updatedcallback} />));  
                    });
                }
            }
            childfunc(prop);
        };
        itemarr.push(subitemarr);
        var header1 = '[' + items.id + '] ';
        var header2 = ' by ' + items.owner + ' ' + taskOwner + '(updated on '; 
        var header3 = ')'; 
        var created = <ReactTime value={items.created * 1000} format="MM/DD/YYYY hh:mm:ss a" />
        var updated = <ReactTime value={items.updated * 1000} format="MM/DD/YYYY hh:mm:ss a" />
        //JSON.stringify(created,null,4);
        return (
            <div> 
                <div className={outerClassName} style={{marginLeft: 'auto', marginRight: 'auto', width:'99.3%'}}>
                    <span className="anchor" id={"/"+ type + '/' + id + '/' + items.id}/>
                    <div className={innerClassName}>
                        <div className="entry-header-inner">[<a style={{color:'black'}} href={"#/"+ type + '/' + id + '/' + items.id}>{items.id}</a>] <ReactTime value={items.created * 1000} format="MM/DD/YYYY hh:mm:ss a" /> by {items.owner} {taskOwner}(updated on <ReactTime value={items.updated * 1000} format="MM/DD/YYYY hh:mm:ss a" />)
                            <span className='pull-right' style={{display:'inline-flex'}}>
                                {this.state.permissionsToolbar ? <SelectedPermission id={items.id} type={'entry'} permissionData={items} permissionsToggle={this.permissionsToggle} updated={updatedcallback} /> : null}
                                <SplitButton bsSize='xsmall' title="Reply" key={items.id} id={'Reply '+items.id} onClick={this.replyEntryToggle}>
                                    <MenuItem eventKey='1' onClick={this.addEntryToggle}>Move</MenuItem>
                                    <MenuItem eventKey='2' onClick={this.deleteToggle}>Delete</MenuItem>
                                    <MenuItem eventKey='3'><Summary type={type} id={id} entryid={items.id} summary={summary} updated={updatedcallback} /></MenuItem>
                                    <MenuItem eventKey='4'><Task type={type} id={id} entryid={items.id} updated={updatedcallback}/></MenuItem>
                                    <MenuItem eventKey='5' onClick={this.permissionsToggle}>Permissions</MenuItem>
                                </SplitButton>
                                <Button bsSize='xsmall' onClick={this.editEntryToggle}>Edit</Button>
                            </span>
                        </div>
                    </div>
                {itemarr}
                </div> 
                {this.state.addEntryToolbar ? <AddEntryModal title='Add Entry' header1={header1} header2={header2} header3={header3} created={created} updated={updatedcallback} type={type} id={id} entryToggle={this.entryToggle} /> : null}
                {this.state.editEntryToolbar ? <AddEntryModal type = {this.props.type} title='Edit Entry' header1={header1} header2={header2} header3={header3} created={created} targetid = {id} updated={updatedcallback} type={type} stage = {'Edit'} id={items.id} entryToggle={this.entryToggle} /> : null}
                {this.state.replyEntryToolbar ? <AddEntryModal title='Reply Entry' stage = {'Reply'} type = {type} header1={header1} header2={header2} header3={header3} created={created} targetid = {id} updated={updatedcallback}  id={items.id} entryToggle={this.entryToggle} /> : null}
                {this.state.deleteToolbar ? <DeleteEntry type={type} id={id} deleteToggle={this.deleteToggle} entryid={items.id} updated={updated} /> : null}     
            </div>
        );
    }
});

var EntryData = React.createClass({ 
    render: function() {
        var rawMarkup = this.props.subitem.body_flair;
        var outerClassName = 'row-fluid entry-body'
        var innerClassName = 'row-fluid entry-body-inner'        
        return (
            <Frame styleSheets={['/css/styles.less']} style={{width:'100%',height:'100%'}}>
                <div className='row-fluid entry-body'>
                    <div className='row-fluid entry-body-inner' style={{marginLeft: 'auto', marginRight: 'auto', width:'99.3%'}} dangerouslySetInnerHTML={{ __html: rawMarkup}}/>
                </div>
            </Frame>
        )
    }
});

module.exports = SelectedEntry;
