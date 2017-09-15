var React = require('react');
var Panel = require('react-bootstrap/lib/Panel.js');
var Badge = require('react-bootstrap/lib/Badge.js');
var Tooltip = require('react-bootstrap/lib/Tooltip.js');
var OverlayTrigger = require('react-bootstrap/lib/OverlayTrigger.js');

var Gamification = React.createClass({
    getInitialState: function() {
        return {
            GameData: null
        }
    },
    componentDidMount: function() {
        $.ajax({
            type: 'get',
            url: '/scot/api/v2/game',
            success: function(response) {
                this.setState({GameData:response});
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('unable to get game data', data);
            }.bind(this)
        })
    },
    titleCase: function(string) {
        var newstring = string.charAt(0).toUpperCase() + string.slice(1)
        return (
            newstring
        )
    },
    render: function() {
        var GameRows = [];
        if (this.state.GameData != null) {
            for (var key in this.state.GameData) {
                var keyCapitalized = this.titleCase(key);
                GameRows.push(
                    <OverlayTrigger placement="top" overlay={<Tooltip id='tooltip'>{this.state.GameData[key][0].tooltip}</Tooltip>}>
                        <Panel header={keyCapitalized} >
                            <div>
                                <div>{this.state.GameData[key][0].username} <Badge>{this.state.GameData[key][0].count}</Badge></div>
                                <div>{this.state.GameData[key][1].username} <Badge>{this.state.GameData[key][1].count}</Badge></div>
                                <div>{this.state.GameData[key][2].username} <Badge>{this.state.GameData[key][2].count}</Badge></div>
                            </div>
                        </Panel>
                    </OverlayTrigger>
                )
            }
        }
        return (
            <div id='gamification' className="dashboard col-md-2">
                <div>
                    <h2>Leader Board</h2>
                </div>
                <div>
                    {GameRows}
                </div>
            </div>
        );
    }
});

module.exports = Gamification;
