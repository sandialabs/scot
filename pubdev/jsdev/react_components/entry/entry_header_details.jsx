var React                   = require('react');
var ReactTime               = require('react-time');
var EntryHeaderOptions      = require('./entry_header_options.jsx');
var EntryEditor             = require('./entry_editor.jsx');
var Entities                = require('../modal/entities.jsx');
var History                 = require('../modal/history.jsx');
var EntryHeaderPermission   = require('./entry_header_permission.jsx');

var EntryHeaderDetails = React.createClass({
    getInitialState: function() {
        return {
            showEventData:false,
            headerData:'',
            showSource:false,
            sourceData:'',
            permissionsToolbar:false,
            entitiesToolbar:false,
            historyToolbar:false,
            entryToolbar:false
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
                <div className='details-table' style={{display: 'flex'}}>
                    <div><button id="event_status" onclick="event_status_toggle()" style={{lineHeight: '12pt', fontSize: 'inherit', marginTop: '17px', width: '200px', marginLeft: 'auto'}} className="btn btn-mini status">{this.state.showEventData ? <EntryDataStatus data={this.state.headerData.status} />: null}</button></div>
                    <div style={{flexGrow:1, marginRight: 'auto'}}><h2>{this.state.showEventData ? <EntryDataSubject data={this.state.headerData.subject} type={subjectType} id={this.props.id}/>: null}</h2></div>
                </div>
                <div className='details-table' style={{width: '50%', margin: '0 auto'}}>
                    <table>
                        <tbody>
                            <tr>
                                <th>Owner</th>
                                <td><span className="editable"><button id='event_owner' style={{lineHeight: '12pt', fontSize: 'inherit'}} className="btn btn-mini">{this.state.showEventData ? <EntryDataOwner data={this.state.headerData.owner} />: null}</button></span></td>
                                <th>Tags</th>
                                <td><span className="editable"><button id='event_tag' style={{lineHeight: '12pt', fontSize: 'inherit'}} className="btn btn-mini">{this.state.showEventData ? <EntryDataTag data='Tag Placeholder' /> : null}</button></span></td>
                            </tr>
                            <tr>
                                <th>Updated</th>
                                <td><span className="editable" id='event_updated' style={{lineHeight: '12pt', fontSize: 'inherit'}} className="btn btn-mini">{this.state.showEventdata ? <ReactTime value={this.state.headerData.updated * 1000} format="MM/DD/YYYY hh:mm:ss a" /> : null}</span></td>
                                <th>Source</th>
                                <td><span className="editable">{this.state.showSource ? <SourceData data={this.state.sourceData} /> : null }</span></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <EntryHeaderOptions permissionsToggle={this.permissionsToggle} entryToggle={this.entryToggle} entitiesToggle={this.entitiesToggle} historyToggle={this.historyToggle} />
                {this.state.historyToolbar ? <History historyToggle={this.historyToggle} id={id} type={type} /> : null}
                {this.state.entitiesToolbar ? <Entities entitiesToggle={this.entitiesToggle} id={id} type={type} /> : null}
                {this.state.permissionsToolbar ? <EntryHeaderPermission permissions={permissions} permissionsToggle={this.permissionsToggle} /> : null}
                {this.state.entryToolbar ? <EntryEditor type={type} id={id} entryToggle={this.entryToggle} /> : null} 
            </div>
        )
    }
});

var EntryDataStatus = React.createClass({
    render: function() {
        data = this.props.data;
        return (
            <div>{data}</div>
        )
    }
});

var EntryDataSubject = React.createClass({
    render: function() {
        id = this.props.id;
        type = this.props.type;
        data = this.props.data;
        return (
            <div>{type} {id}: {data}</div>
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
        data = this.props.data;
        return (
            <div>{data}</div>
        )
    }
});
var SourceData = React.createClass({
    render: function() {
        var rows = [];
        data = this.props.data;
        for (var prop in data) {
            rows.push(<SourceDataIterator data={data[prop]} />);
        }
        return (
            <div>{rows}</div>
        )
    }
});

var SourceDataIterator = React.createClass({
    render: function() {
        data = this.props.data;
        return (
            <button id="event_source" style={{lineHeight: '12pt', fontSize: 'inherit'}} className="btn btn-mini">{data.value}</button>
        )
    }
});
module.exports = EntryHeaderDetails;
