var React           = require('react');
var Button          = require('react-bootstrap/lib/Button');

var TrafficLightProtocol = React.createClass({
    getInitialState: function() {
        return {
            tlpColor: 'notSet',
        }
    },
    componentDidMount: function() {
        /*this.serverRequest = $.get('/scot/api/v2/'+ this.props.type + '/' + this.props.id + '/history', function (result) {
            var result = result.records;
            this.setState({historyBody:true, data:result})
        }.bind(this));*/
        this.setState({ tlpColor: 'green' });
    },
    
    render: function() {
        return (
            <Button bsSize='xsmall'><img src={ '/images/tlp/tlp_icons_rgb_' + this.state.tlpColor + '_sm.png' }/></Button> 
        )
    }
});

module.exports = TrafficLightProtocol;
