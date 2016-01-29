var React   = require('react');

var EntryHeaderDetails = React.createClass({
    render: function() {
        return (
            <table className="details-table">
                <tbody>
                    <tr>
                        <th className="events">Event #</th>
                        <th>Subject</th>
                        <th className="events">Owner</th>
                        <th className="alerts events">Status</th>
                        <th className="alerts">Viewed By</th>
                        <th className="intel events alerts">Tags</th>
                        <th className="intel events alerts">Source</th>
                        <th className="events" id="linked_alerts_title">Alert(s)</th>
                    </tr>
                    <tr>
                        <td style={{fontSize: '15pt'}} id="event_id"><span style={{display: 'none'}} id="preview_type" />{this.props.id}</td>
                        <td><input id="subjectEditor" className="editable" type="text" value={this.props.headerdata.subject} /></td>
                        <td className="events"><span className="editable"><button id="event_owner" onclick="take_ownership()" style={{lineHeight: '12pt', fontSize: 'inherit'}} className="btn btn-mini">{this.props.headerdata.owner}</button></span>
                        </td>
                        <td className="alerts events"><span className="editable"><button id="event_status" onclick="open_close_event()" style={{lineHeight: '12pt', fontSize: 'inherit'}} className="btn btn-mini">{this.props.headerdata.status}</button></span></td>
                        <td className="intel alerts events"><input className="editable multi_tag" id="viewed_by" value={this.props.viewedby}/></td>
                        <td className="intel events alerts"><input className="editable multi_tag" id="event_source2" value="TAG PLACEHOLDER"/></td>
                        <td className="events"><span className="editable" id="linked_alerts">SOURCE PLACEHOLDER</span></td>
                        <td className="events"><span onclick="linked_incident(this)" style={{cursor: 'pointer'}} className="editable" id="linked_alerts">Linked Incidents Placeholder</span></td>
                        <td>
                        </td>
                    </tr>
                </tbody>
            </table>
        )
    }
});

module.exports = EntryHeaderDetails;
