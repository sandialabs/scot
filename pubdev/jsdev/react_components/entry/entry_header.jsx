var React                   = require('react');
var EntryHeaderDetails      = require('./entry_header_details.jsx');
var AutoAffix               = require('react-overlays/lib/AutoAffix');

var EntryHeader = React.createClass({
        getInitialState: function(){
            return {
            }
        },
        render: function() {
            var id = this.props.id;
            var headerdata = this.props.data; 
            return (
                <div>
                    <AutoAffix>
                        <div id="NewEventInfo" className="entry-header-info-null">
                            <EntryHeaderDetails id={id} headerdata={headerdata} type='event' />
                        </div>
                </AutoAffix>                
            </div>
        );
    } 
});

module.exports = EntryHeader;
