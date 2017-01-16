var React = require('react');
var Panel = require('react-bootstrap/lib/Panel.js');
var Badge = require('react-bootstrap/lib/Badge.js');

var Stats = React.createClass({
    getInitialState: function() {
        return {
            StatsData: null
        }
    },
    componentDidMount: function() {
        //TODO open this up when we have a final front page route for stats
        /*$.ajax({
            type: 'get',
            url: '/scot/api/v2/stat',
        }).success(function(response) {
            this.setState({StatsData:response.records});
        }.bind(this))*/
    },
    render: function() {
        var StatsRows = [];
        if (this.state.StatsData != null) {
            for (i=0; i < this.state.StatsData.length; i++) {
                var timeago = timeSince(this.state.StatsData[i].last_activity);
                StatsRows.push(
                    <Panel header={this.state.StatsData[i].username} >
                        <div style={{display:'flex', flexFlow:'column'}}>
                            <div>Stats go here</div>
                        </div>
                    </Panel>
                )
            }
        } else {
            StatsRows.push(
                <Panel header={'Stats'}>
                    <div style={{fontWeight:'bold'}}>Coming Soon</div>
                </Panel>
            )
        }
        return (
            <div id='stats' className="dashboard col-md-4">
                <div style={{textAlign:'center'}}>
                    <h2>Stats</h2>
                </div>
                <div>
                    {StatsRows}
                </div>
            </div>
        );
    }
});

module.exports = Stats;
