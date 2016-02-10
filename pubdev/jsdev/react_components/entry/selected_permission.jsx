var React           = require('react');

var EntryHeaderPermission = React.createClass({
    render: function() {
        return (
            <div id="" className="toolbar">
                <img src="/images/close_toolbar.png" className="close_toolbar" onClick={this.props.permissionsToggle} />
                <center>
                    Event Permissions:
                    Read Groups:<input className="entry_select2" id="read_permissions" value={this.props.permissions[0]}  />
                    Write Groups:<input className="entry_select2" id="write_permissions" value={this.props.permissions[1]} />
                </center>
            </div> 
        )
    }
});

module.exports = EntryHeaderPermission
