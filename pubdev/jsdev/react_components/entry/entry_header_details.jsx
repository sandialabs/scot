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
            showSource:false,
            sourceData:'',
            permissionsToolbar:false,
            entitiesToolbar:false,
            historyToolbar:false,
            entryToolbar:false
        }
    },
    componentWillMount: function() {
        this.serverRequest = $.get('scot/api/v2/' + this.props.type + '/' + this.props.id + '/source', function(result) {
            var result = result.records;
            this.setState({showSource:true, sourceData:result})
        }.bind(this));
    },
    viewedbyfunc: function(headerdata) {
        var viewedbyarr = [];
        for (prop in headerdata.view_history) {
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
    permissionsfunc: function(headerdata) {
        var writepermissionsarr = [];
        var readpermissionsarr = [];
        var readwritepermissionsarr = [];
        for (prop in headerdata.groups) {
            var fullprop = headerdata.groups[prop]
            if (prop == 'read') {
                headerdata.groups[prop].forEach(function(fullprop) {
                    readpermissionsarr.push(fullprop)
                });
            } else if (prop == 'modify') {
                headerdata.groups[prop].forEach(function(fullprop) {
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
    render: function() {
        var headerdata = this.props.headerdata;        
        var permissions = this.permissionsfunc(headerdata); //pos 0 is read and pos 1 is write
        var viewedby = this.viewedbyfunc(headerdata);
        var id = this.props.id;
        return (
            <div>
                <div className='details-table' style={{display: 'flex'}}>
                    <div><button id="event_status" onclick="event_status_toggle()" style={{lineHeight: '12pt', fontSize: 'inherit', marginTop: '17px', width: '200px', marginLeft: 'auto'}} className="btn btn-mini status">{this.props.headerdata.status}</button></div>
                    <div style={{flexGrow:1, marginRight: 'auto'}}><h2>Event {this.props.id}: {this.props.headerdata.subject}</h2></div>
                </div>
                <div className='details-table' style={{width: '50%', margin: '0 auto'}}>
                    <table>
                        <tbody>
                            <tr>
                                <th>Owner</th>
                                <td><span className="editable"><button id='event_owner' style={{lineHeight: '12pt', fontSize: 'inherit'}} className="btn btn-mini">{this.props.headerdata.owner}</button></span></td>
                                <th>Tags</th>
                                <td><span className="editable"><button id='event_tag' style={{lineHeight: '12pt', fontSize: 'inherit'}} className="btn btn-mini">Tag Placeholder</button></span></td>
                            </tr>
                            <tr>
                                <th>Updated</th>
                                <td><span className="editable" id='event_updated' style={{lineHeight: '12pt', fontSize: 'inherit'}} className="btn btn-mini"><ReactTime value={this.props.headerdata.updated * 1000} format="MM/DD/YYYY hh:mm:ss a" /></span></td>
                                <th>Source</th>
                                <td><span className="editable">{this.state.showSource ? <SourceData data={this.state.sourceData} /> : null }</span></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
                <EntryHeaderOptions permissionsToggle={this.permissionsToggle} entryToggle={this.entryToggle} entitiesToggle={this.entitiesToggle} historyToggle={this.historyToggle} />
                {this.state.historyToolbar ? <History historyToggle={this.historyToggle} id={id} type='event' /> : null}
                {this.state.entitiesToolbar ? <Entities entitiesToggle={this.entitiesToggle} id={id} type='event' /> : null}
                {this.state.permissionsToolbar ? <EntryHeaderPermission permissions={permissions} permissionsToggle={this.permissionsToggle} /> : null}
                {this.state.entryToolbar ? <EntryEditor type='Event' id={id} entryToggle={this.entryToggle} /> : null} 
            </div>
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
