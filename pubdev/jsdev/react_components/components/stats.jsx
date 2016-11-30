var React = require('react');
var Panel = require('react-bootstrap/lib/Panel.js');
var Badge = require('react-bootstrap/lib/Badge.js');

var Stats = React.createClass({
    getInitialState: function() {
        return {
            StatData: null
        }
    },
    componentDidMount: function() {
        $.ajax({
            type: 'get',
            url: '/scot/api/v2/status',
        }).success(function(response) {
            this.setState({StatData:response});
        }.bind(this))
    },
    render: function() {
        var StatRows = [];
        if (this.state.StatData != null) {
            for (var key in this.state.StatData) {
                StatRows.push(
                    <Panel header={key} >
                        <div style={{display:'flex', flexFlow:'column'}}>
                            <div style={{fontWeight:'bold'}}>{this.state.StatData[key]}</div>
                        </div>
                    </Panel>
                )
            }
        } else {
            StatRows.push(
                <Panel header={'SCOT 3.5 Stats'}>
                    <br/>
                    <div style={{fontWeight:'bold'}}>Coming Soon</div>
                    <br/>
                </Panel>
            )
        }
        return (
            <div id='stats' className="stats">
                <div style={{textAlign:'center'}}>
                    <h2>Stats</h2>
                </div>
                <div style={{display:'flex'}}>
                    {StatRows}
                </div>
            </div>
        );
    }
});

module.exports = Stats;
