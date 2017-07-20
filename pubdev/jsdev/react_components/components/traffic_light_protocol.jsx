var React                   = require('react');
var Button                  = require('react-bootstrap/lib/Button');
var Dropdown                = require('react-bootstrap/lib/Dropdown');
var MenuItem                = require('react-bootstrap/lib/MenuItem');
var DropdownToggle          = require("react-bootstrap/lib/DropdownToggle");
var DropdownMenu            = require("react-bootstrap/lib/DropdownMenu");
var TrafficLightProtocol = React.createClass({
    
    getInitialState: function() {
        return {
            color: 'transparent',
            notset: true,
        }
    },

    componentDidMount: function() {
        /*this.serverRequest = $.get('/scot/api/v2/'+ this.props.type + '/' + this.props.id + '/history', function (result) {
            var result = result.records;
            this.setState({historyBody:true, data:result})
        }.bind(this));*/
        this.setState({ color: 'green', notset: false });
    },

    selectColor: function(e) {
        this.setState({color: e});
    },

    render: function() {
        return (
            <div>
                <Dropdown bsSize='xsmall'>
                    <DropdownToggle>
                        <svg id='trafficlight1' style={{width: '20px', height: '20px'}}>
                            <circle id="circle1" r="10" cx="10" cy="10" style={{fill: ((this.state.color == 'red' || this.state.color == 'white')  ? this.state.color : 'gray'), stroke: 'black', strokeWidth: '2'}} />
                        </svg>    
                        <svg id='trafficlight2' style={{width: '20px', height: '20px'}}>
                            <circle id="circle2" r="10" cx="10" cy="10" style={{fill: ((this.state.color == 'yellow' || this.state.color == 'white') ? this.state.color : 'gray') , stroke: 'black', strokeWidth: '2'}} />
                        </svg>
                        <svg id='trafficlight2' style={{width: '20px', height: '20px'}}>
                            <circle id="circle3" r="10" cx="10" cy="10" style={{fill: ((this.state.color == 'green' || this.state.color == 'white') ? this.state.color : 'gray'), stroke: 'black', strokeWidth: '2'}} />
                        </svg>
                    </DropdownToggle>
                    <DropdownMenu>
                        <MenuItem header>Traffic Light Protocol (TLP) Color</MenuItem>
                        <MenuItem eventKey='notset' onSelect={this.selectColor}>Unset</MenuItem>
                        <MenuItem eventKey='red' onSelect={this.selectColor}>Red</MenuItem>
                        <MenuItem eventKey='yellow' onSelect={this.selectColor}>Yellow</MenuItem>
                        <MenuItem eventKey='green' onSelect={this.selectColor}>Green</MenuItem>
                        <MenuItem eventKey='white' onSelect={this.selectColor}>White</MenuItem>
                        <MenuItem divider/>
                        <MenuItem href="https://www.us-cert.gov/tlp">What is TLP?</MenuItem>
                    </DropdownMenu>
                </Dropdown> 
            </div>
        )
    }
});

module.exports = TrafficLightProtocol;
