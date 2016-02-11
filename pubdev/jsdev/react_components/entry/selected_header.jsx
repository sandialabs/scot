var React                   = require('react');
var ReactTime               = require('react-time');
var SelectedHeaderOptions   = require('./selected_header_options.jsx');
var AddEntryModal           = require('../modal/add_entry.jsx');
var Owner                   = require('../modal/owner.jsx');
var Entities                = require('../modal/entities.jsx');
var History                 = require('../modal/history.jsx');
var SelectedPermission      = require('./selected_permission.jsx');
var AutoAffix               = require('react-overlays/lib/AutoAffix');
var Affix                   = require('react-overlays/lib/Affix');
var Sticky                  = require('react-sticky');
var Button                  = require('react-bootstrap/lib/Button');
var DebounceInput           = require('react-debounce-input');
var SelectedEntry           = require('./selected_entry.jsx');
var SelectedHeader = React.createClass({
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
    updated: function() {
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
        console.log('Ran update')  
    },
    viewedbyfunc: function(headerData) {
        var viewedbyarr = [];
        for (prop in headerData.view_history) {
            viewedbyarr.push(prop);
        };
        return viewedbyarr;
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
            <div>
                <div id="NewEventInfo" className="entry-header-info-null" style={{zIndex:id}}>
                    <div className='details-table' style={{display: 'flex'}}>
                        <div>{this.state.showEventData ? <EntryDataStatus data={this.state.headerData.status} id={id} type={type} updated={this.updated} />: null}</div>
                        <div style={{flexGrow:1, marginRight: 'auto'}}><h2>{this.state.showEventData ? <EntryDataSubject data={this.state.headerData.subject} type={subjectType} id={this.props.id} updated={this.updated} />: null}</h2></div>
                    </div>
                    <div className='details-table' style={{width: '50%', margin: '0 auto'}}>
                        <table>
                            <tbody>
                                <tr>
                                    <th>Owner</th>
                                    <td><span>{this.state.showEventData ? <Owner data={this.state.headerData.owner} type={type} id={id} updated={this.updated} />: null}</span></td>
                                    <th>Tags</th>
                                    <td><span className='editable'>{this.state.showTag ? <EntryDataTag data={this.state.tagData} id={id} type={type} updated={this.updated}/> : null}</span></td>
                                </tr>
                                <tr>
                                    <th>Updated</th>
                                    <td><span id='event_updated' style={{lineHeight: '12pt', fontSize: 'inherit',paddingTop:'5px'}} >{this.state.showEventData ? <EntryDataUpdated data={this.state.headerData.updated} /> : null}</span></td>
                                    <th>Source</th>
                                    <td><span className="editable">{this.state.showSource ? <SourceData data={this.state.sourceData}id={id} type={type} updated={this.updated} /> : null }</span></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    <SelectedHeaderOptions toggleEventDisplay={this.props.toggleEventDisplay} permissionsToggle={this.permissionsToggle} entryToggle={this.entryToggle} entitiesToggle={this.entitiesToggle} historyToggle={this.historyToggle} />
                    {this.state.historyToolbar ? <History historyToggle={this.historyToggle} id={id} type={type} /> : null}
                    {this.state.entitiesToolbar ? <Entities entitiesToggle={this.entitiesToggle} id={id} type={type} /> : null}
                    {this.state.permissionsToolbar ? <SelectedPermission permissions={permissions} permissionsToggle={this.permissionsToggle} /> : null}
                    {this.state.entryToolbar ? <AddEntryModal type={type} id={id} entryToggle={this.entryToggle} /> : null}  
                </div>
                <SelectedEntry id={id} type={type} />
            </div>
        )
    }
});

var EntryDataUpdated = React.createClass({
    render: function() {
        data = this.props.data;
        return (
            <div><ReactTime value={data * 1000} format="MM/DD/YY hh:mm:ss a" /></div>
        )
    }
});

var EntryDataStatus = React.createClass({
    getInitialState: function() {
        return {
            buttonStatus:this.props.data
        }
    },
    eventStatusToggle: function () {
        if (this.state.buttonStatus == 'open') {
            this.setState({buttonStatus:'closed'});
            this.statusAjax('closed');
        } else if (this.state.buttonStatus == 'closed') {
            this.setState({buttonStatus:'open'});
            this.statusAjax('open');
        }
    },
    statusAjax: function(newStatus) {
        console.log(newStatus);
        var json = {'status':newStatus};
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
            data: json,
            success: function(data) {
                console.log('success status change to: ' + data);
                this.props.updated();
            }.bind(this),
            error: function() {
                alert('Failed to change status - contact administrator');
            }.bind(this)
        });
    },
    render: function() { 
        var buttonStyle = ''
        if (this.state.buttonStatus == 'open') {
            buttonStyle = 'danger'; 
        } else if (this.state.buttonStatus == 'closed') {
            buttonStyle = 'success';
        } else if (this.state.buttonStatus == 'promoted') {
            buttonStyle = 'warning'
        };
        return (
            <Button bsStyle={buttonStyle} id="event_status" onClick={this.eventStatusToggle} style={{lineHeight: '12pt', fontSize: 'inherit', marginTop: '17px', width: '200px', marginLeft: 'auto'}}>{this.state.buttonStatus}</Button>
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
                    this.props.updated();
                }.bind(this),
                error: function() { 
                    alert('Failed to make the update to the subject');
                }.bind(this)
            });
        }
    },
    render: function() {
        return (
            <div>{this.state.type} {this.state.id}: <DebounceInput debounceTimeout={500} type='text' value={this.state.value} onChange={this.handleChange} /></div>
        )
    }
});

var EntryDataTag = React.createClass({ 
    getInitialState: function() {
        return {tagEntry:false, newTag:'', potentialTags:'', togglePotentialTags:false}
    },
    handleChange: function(event) { 
        this.setState({newTag:event.target.value})
        /*this.serverRequest = $.get('/scot/api/v2/ac/tag/' + this.state.newTag, function (result) {
            var result = result.records;
            console.log(result);
            for (var prop in result) {
                arr.push(result[prop])
            }
            this.setState({potentialTags:result,togglePotentialTags:true})
        }.bind(this));*/
    },
    addTag: function() {
            if (this.state.newTag != '') {
                var newTagArr = [];
                var data = this.props.data;
                var tag = 'tag'; 
                for (var prop in data) {
                    newTagArr.push(data[prop].value);
                }
                newTagArr.push(this.state.newTag);
                $.ajax({
                    type: 'put',
                    url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
                    data: JSON.stringify({tag:newTagArr}),
                    contentType: 'application/json; charset=UTF-8',
                    success: function(data) {
                        console.log('success: tag added');
                        this.toggleTagEntry();
                        this.props.updated();
                        this.setState({newTag:'',togglePotentialTags:false});
                    }.bind(this),
                    error: function() {
                        alert('Failed to add tag - contact administrator');
                        this.toggleTagEntry();
                        this.setState({newTag:'',togglePotentialTags:false});
                    }.bind(this)
                });
            } else { 
                alert('Tag can not be empty');
            };
    },
    toggleTagEntry: function () {
        if (this.state.tagEntry == false) {
            this.setState({tagEntry:true})
        } else if (this.state.tagEntry == true) {
            this.setState({tagEntry:false})
        };
    },
    render: function() {
        var rows = [];
        var id = this.props.id;
        var type = this.props.type;
        var data = this.props.data;
        for (var prop in data) {
            rows.push(<TagDataIterator data={data[prop]} id={id} type={type} updated={this.props.updated} />);
        } 
        return (
            <div>
                {rows}
                <Button bsStyle={'success'} onClick={this.toggleTagEntry}><span className='glyphicon glyphicon-plus' ariaHidden='true'></span></Button>
                {this.state.tagEntry ? <div style={{color:'black'}}><DebounceInput debounceTimeout={300} type='text' value={this.state.newTag} onChange={this.handleChange} /> <Button onClick={this.addTag}>Add</Button></div>: null} 
                {this.state.potentialTags ? <NewTagIterator potentialTags={this.state.potentialTags} addTag={this.addTag} />: null}
            </div>
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
            success: function(data) {
                console.log('deleted tag success: ' + data);
                this.props.updated();
            }.bind(this),
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

var NewTagIterator =  React.createClass({
    render: function() {
        var potentialTags = this.props.potentialTags;
        var defaultValue = 'potential tags...';
        return (
            <DropdownInput
                options={potentialTags}
                defaultValue={defaultValue}
                menuClassName='dropdown-input'
                onSelect={this.props.addTag}
                placeholder='Search...'
            />
        )
    }
});

var SourceData = React.createClass({
    getInitialState: function() {
        return {sourceEntry:false, newSource:''}
    },
    handleChange: function(event) {
        this.setState({newSource:event.target.value})
        var potentialSource = 'ajax return here';
        /*this.serverRequest = $.get('/scot/api/v2/tag', function (result) {
            var result = result.records;
            console.log(result);
        }.bind(this));*/
    },
    addSource: function() {
        if (this.state.newSource != '') {
            var newSourceArr = [];
            var data = this.props.data;
            var source = 'source';
            for (var prop in data) { 
                newSourceArr.push(data[prop].value);
            }
            newSourceArr.push(this.state.newSource);
            $.ajax({
                type: 'put',
                url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
                data: JSON.stringify({source:newSourceArr}),
                contentType: 'application/json; charset=UTF-8',
                success: function(data) {
                    console.log('success: source added');
                    this.toggleSourceEntry();
                    this.props.updated();
                    this.setState({newSource:''});
                }.bind(this),
                error: function() {
                    alert('Failed to add source - contact administrator');
                    this.toggleSourceEntry();
                    this.setState({newSource:''});
                }.bind(this)
            });}
        else {
            alert('Tag can not be empty');
        };
    },
    toggleSourceEntry: function () {
        if (this.state.sourceEntry == false) {
            this.setState({sourceEntry:true})
        } else if (this.state.sourceEntry == true) {
            this.setState({sourceEntry:false})
        };
    },
    render: function() {
        var rows = [];
        var id = this.props.id;
        var type = this.props.type;
        var data = this.props.data;
        for (var prop in data) {
            rows.push(<SourceDataIterator data={data[prop]} id={id} type={type} updated={this.props.updated} />);
        }
        return (
            <div>
                {rows}
                <Button bsStyle={'success'} onClick={this.toggleSourceEntry}><span className='glyphicon glyphicon-plus' ariaHidden='true'></span></Button>
                {this.state.sourceEntry ? <div style={{color:'black'}}><DebounceInput debounceTimeout={300} type='text' value={this.state.newSource} onChange={this.handleChange} /> <Button onClick={this.addSource}>Add</Button></div>: null} 
            </div>
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
                this.props.updated();
            }.bind(this),
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

module.exports = SelectedHeader;
