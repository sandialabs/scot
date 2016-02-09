var React                   = require('react');
var ReactTime               = require('react-time');
var EntryHeaderOptions      = require('./entry_header_options.jsx');
var AddEntryModal           = require('../modal/add_entry.jsx');
var TakeOwnership           = require('../modal/take_ownership.jsx');
var Entities                = require('../modal/entities.jsx');
var History                 = require('../modal/history.jsx');
var EntryHeaderPermission   = require('./entry_header_permission.jsx');
var AutoAffix               = require('react-overlays/lib/AutoAffix');
var Affix                   = require('react-overlays/lib/Affix');
var Sticky                  = require('react-sticky');
var Button                  = require('react-bootstrap/lib/Button');
var DebounceInput           = require('react-debounce-input');
var EntryHeader = React.createClass({
    getInitialState: function() {
        return {
            showEventData:false,
            headerData:'',
            showSource:false,
            sourceData:'',
            tagData:'',
            showTag:false,
            permissionsToolbar:false,
            entitiesToolbar:false,
            historyToolbar:false,
            entryToolbar:false,
            ownerToolbar:false
        }
    },
    componentDidMount: function() {
        this.sourceRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id + '/source', function(result) {
            var sourceResult = result.records;
            this.setState({showSource:true, sourceData:sourceResult})
        }.bind(this));
        this.eventRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id, function(result) {
            var eventResult = result;
            this.setState({showEventData:true, headerData:eventResult})
        }.bind(this));
        this.tagRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id + '/tag', function(result) {
            var tagResult = result.records;
            this.setState({showTag:true, tagData:tagResult});
        }.bind(this));
        console.log('Ran componentDidMount');    
    },
    update: function() {
        this.sourceRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id + '/source', function(result) {
            var sourceResult = result.records;
            this.setState({showSource:true, sourceData:sourceResult})
        }.bind(this));
        this.eventRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id, function(result) {
            var eventResult = result;
            this.setState({showEventData:true, headerData:eventResult})
        }.bind(this));
        console.log('Ran update')  
    },
    viewedbyfunc: function(headerData) {
        var viewedbyarr = [];
        for (prop in headerData.view_history) {
            viewedbyarr.push(prop);
        };
        return viewedbyarr;
    },
    addSource: function() {
        console.log('Add functionality for Add source onClick event once links to are created in DB');
        alert('Add functionality for Add source onClick event once links to are created in DB');
    },
    addTag: function() {
        console.log('Add functionality for Add tag onClick event once links to are created in DB');
        alert('Add functionality for Add tag onClick event once links to are created in DB');
    },
    entryToggle: function() {
        if (this.state.entryToolbar == false) {
            this.setState({entryToolbar:true})
        } else {
            this.setState({entryToolbar:false})
        }
    },
    historyToggle: function() {
        if (this.state.historyToolbar == false) {
            this.setState({historyToolbar:true});
        } else {
            this.setState({historyToolbar:false});
        }
    },
    permissionsfunc: function(headerData) {
        var writepermissionsarr = [];
        var readpermissionsarr = [];
        var readwritepermissionsarr = [];
        for (prop in headerData.groups) {
            var fullprop = headerData.groups[prop]
            if (prop == 'read') {
                headerData.groups[prop].forEach(function(fullprop) {
                    readpermissionsarr.push(fullprop)
                });
            } else if (prop == 'modify') {
                headerData.groups[prop].forEach(function(fullprop) {
                    writepermissionsarr.push(fullprop)
                });
            };
        };
        readwritepermissionsarr.push(readpermissionsarr);
        readwritepermissionsarr.push(writepermissionsarr);
        return readwritepermissionsarr;
    },
    permissionsToggle: function() {
        if (this.state.permissionsToolbar == false) {
            this.setState({permissionsToolbar:true});
        } else {
            this.setState({permissionsToolbar:false});
        }
    },
    entitiesToggle: function() {
        if (this.state.entitiesToolbar == false) {
            this.setState({entitiesToolbar:true});
        } else {
            this.setState({entitiesToolbar:false});
        }
    },
    ownerToggle: function() {
        if (this.state.ownerToolbar == false) {
            this.setState({ownerToolbar:true});
        } else {
            this.setState({ownerToolbar:false});  
            this.update();        
        }
    },
    titleCase: function(string) {
        var newstring = string.charAt(0).toUpperCase() + string.slice(1)
        return (
            newstring
        )
    },
    render: function() {
        var headerData = this.state.headerData;        
        var permissions = this.permissionsfunc(headerData); //pos 0 is read and pos 1 is write
        var viewedby = this.viewedbyfunc(headerData);
        var type = this.props.type;
        var subjectType = this.titleCase(this.props.type);
        var id = this.props.id;
        return (
                
                <div id="NewEventInfo" className="entry-header-info-null" style={{zIndex:id}}>
                    <div className='details-table' style={{display: 'flex'}}>
                        <div>{this.state.showEventData ? <EntryDataStatus data={this.state.headerData.status} />: null}</div>
                        <div style={{flexGrow:1, marginRight: 'auto'}}><h2>{this.state.showEventData ? <EntryDataSubject data={this.state.headerData.subject} type={subjectType} id={this.props.id}/>: null}</h2></div>
                    </div>
                    <div className='details-table' style={{width: '50%', margin: '0 auto'}}>
                        <table>
                            <tbody>
                                <tr>
                                    <th>Owner</th>
                                    <td><span><Button id='event_owner' onClick={this.ownerToggle}>{this.state.showEventData ? <EntryDataOwner data={this.state.headerData.owner} />: null}</Button></span></td>
                                    <th>Tags</th>
                                    <td><span className='editable'>{this.state.showTag ? <EntryDataTag data={this.state.tagData} id={id} type={type} /> : null}<Button bsStyle={'success'} onClick={this.addTag}><span onClick={this.addTag} className='glyphicon glyphicon-plus' ariaHidden='true'></span></Button></span></td>
                                </tr>
                                <tr>
                                    <th>Updated</th>
                                    <td><span id='event_updated' style={{lineHeight: '12pt', fontSize: 'inherit',paddingTop:'5px'}} >{this.state.showEventData ? <EntryDataUpdated data={this.state.headerData.updated} /> : null}</span></td>
                                    <th>Source</th>
                                    <td><span className="editable">{this.state.showSource ? <SourceData data={this.state.sourceData}id={id} type={type} /> : null }<Button bsStyle={'success'} onClick={this.addSource}><span onClick={this.addSource} className='glyphicon glyphicon-plus' ariaHidden='true'></span></Button></span></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    <EntryHeaderOptions toggleEventDisplay={this.props.toggleEventDisplay} permissionsToggle={this.permissionsToggle} entryToggle={this.entryToggle} entitiesToggle={this.entitiesToggle} historyToggle={this.historyToggle} />
                    {this.state.historyToolbar ? <History historyToggle={this.historyToggle} id={id} type={type} /> : null}
                    {this.state.entitiesToolbar ? <Entities entitiesToggle={this.entitiesToggle} id={id} type={type} /> : null}
                    {this.state.permissionsToolbar ? <EntryHeaderPermission permissions={permissions} permissionsToggle={this.permissionsToggle} /> : null}
                    {this.state.entryToolbar ? <AddEntryModal type={type} id={id} entryToggle={this.entryToggle} /> : null} 
                    {this.state.ownerToolbar ? <TakeOwnership type={type} id={id} ownerToggle={this.ownerToggle} /> : null}
                </div>
        
        )
    }
});

var EntryDataUpdated = React.createClass({
    render: function() {
        data = this.props.data;
        return (
            <div><ReactTime value={data * 1000} format="MM/DD/YYY hh:mm:ss a" /></div>
        )
    }
});

var EntryDataStatus = React.createClass({
    render: function() {
        data = this.props.data;
        var buttonStyle = ''
        if (data == 'open') {
            buttonStyle = 'danger'; 
        } else if (data == 'closed') {
            buttonStyle = 'success';
        } else if (data == 'promoted') {
            buttonStyle = 'warning'
        };
        return (
            <Button bsStyle={buttonStyle} id="event_status" onclick="event_status_toggle()" style={{lineHeight: '12pt', fontSize: 'inherit', marginTop: '17px', width: '200px', marginLeft: 'auto'}}>{data}</Button>
        )
    }
});

var EntryDataSubject = React.createClass({
    getInitialState: function() {
        return {value:this.props.data, type:this.props.type, id:this.props.id}
    },
    handleChange: function(event) {
        this.setState({value:event.target.value});
        if (this.state.value != this.props.data) {
            var json = {subject:this.state.value}
            $.ajax({
                type: 'put',
                url: 'scot/api/v2/' + this.state.type + '/' + this.state.id,
                data: json,
                success: function(data) {
                    console.log('success: ' + data);
                },
                error: function() { 
                    alert('Failed to make the update to the subject');
                }.bind(this)
            });
        }
        console.log('end handle change');
    },
    render: function() {
        return (
            <div>{this.state.type} {this.state.id}: <DebounceInput debounceTimeout={1000} type='text' value={this.state.value} onChange={this.handleChange} /></div>
        )
    }
});

var EntryDataOwner = React.createClass({
    render: function() {
        data = this.props.data;
        return (
            <div>{data}</div>
        )
    }
});

var EntryDataTag = React.createClass({
    render: function() {
        var rows = [];
        var id = this.props.id;
        var type = this.props.type;
        var data = this.props.data;
        for (var prop in data) {
            rows.push(<TagDataIterator data={data[prop]} id={id} type={type} />);
        } 
        return (
            <div>{rows}</div>
        )
    }
});

var TagDataIterator = React.createClass({
    getInitialState: function() {
        return {tag:true}
    },
    tagDelete: function() {
        $.ajax({
            type: 'delete',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/tag/' + this.props.data.id,
            //data: json,
            success: function(data) {
                console.log('deleted tag success: ' + data);
            },
            error: function() {
                alert('Failed to delete the tag - contact administrator');
            }.bind(this)
        });
        this.setState({tag:false});
        },
    render: function() {
        data = this.props.data;
        return (
            <Button id="event_tag" onClick={this.tagDelete}><span className="glyphicon glyphicon-remove-circle" ariaHidden="true"></span> {data.value}</Button>
        )
    }
});

var SourceData = React.createClass({
    render: function() {
        var rows = [];
        var id = this.props.id;
        var type = this.props.type;
        var data = this.props.data;
        for (var prop in data) {
            rows.push(<SourceDataIterator data={data[prop]} id={id} type={type} />);
        }
        return (
            <div>{rows}</div>
        )
    }
});

var SourceDataIterator = React.createClass({
    getInitialState: function() {
        return {source:true}
    },
    sourceDelete: function() {
        $.ajax({
            type: 'delete',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id + '/source/' + this.props.data.id,
            //data: json,
            success: function(data) {
                console.log('deleted source success: ' + data);
            },
            error: function() {
                alert('Failed to delete the source - contact administrator');
            }.bind(this)
        });
        this.setState({source:false});
    },     
    render: function() {
        data = this.props.data;
        return (
            <Button id="event_source" onClick={this.sourceDelete}><span className="glyphicon glyphicon-remove-circle" ariaHidden="true"></span> {data.value}</Button>
        )
    }
});

module.exports = EntryHeader;
