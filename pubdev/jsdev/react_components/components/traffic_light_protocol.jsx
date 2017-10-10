var React                   = require('react');
var Button                  = require('react-bootstrap/lib/Button');
var Dropdown                = require('react-bootstrap/lib/Dropdown');
var MenuItem                = require('react-bootstrap/lib/MenuItem');
var DropdownToggle          = require("react-bootstrap/lib/DropdownToggle");
var DropdownMenu            = require("react-bootstrap/lib/DropdownMenu");
var OverlayTrigger          = require('react-bootstrap/lib/OverlayTrigger');
var Tooltip                 = require('react-bootstrap/lib/Tooltip');

var TrafficLightProtocol = React.createClass({
    
    selectColor: function(e) {
        let data  = { 'tlp': e }
        this.serverRequest = $.ajax({
            type: 'put',
            url: '/scot/api/v2/' + this.props.type + '/' + this.props.id + '/',
            data: JSON.stringify(data),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                console.log('set tlp');
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('Failed to set TLP', data);
            }.bind(this),
        });
        //this.setState({ color: e });
    },

    render: function() {
        return (
            <span style={{ padding: (this.props.type == 'entry' ? '3px 20px' : null) }}>
                <OverlayTrigger placement="top" overlay={<Tooltip id='tlp-tooltip'>{this.props.tlp}</Tooltip>}>
                    <Dropdown bsSize='xsmall' bsStyle={{ padding: (this.props.type == 'entry' ? '3px 20px' : null) }} >
                        <DropdownToggle>
                            <svg id='trafficlight1' style={{width: '12px', height: '12px'}}>
                                <circle id="circle1" r="5" cx="6" cy="6" style={{fill: ((this.props.tlp == 'red' || this.props.tlp == 'white')  ? this.props.tlp : 'gray'), stroke: 'black', strokeWidth: '2'}} />
                            </svg>    
                            <svg id='trafficlight2' style={{width: '12px', height: '12px'}}>
                                <circle id="circle2" r="5" cx="6" cy="6" style={{fill: ((this.props.tlp == 'amber' && this.props.tlp != 'white' ? 'orange' : this.props.tlp == 'white' ? 'white' : 'gray' )) , stroke: 'black', strokeWidth: '2'}} />
                            </svg>
                            <svg id='trafficlight2' style={{width: '12px', height: '12px'}}>
                                <circle id="circle3" r="5" cx="6" cy="6" style={{fill: ((this.props.tlp == 'green' || this.props.tlp == 'white') ? this.props.tlp : 'gray'), stroke: 'black', strokeWidth: '2'}} />
                            </svg>
                        </DropdownToggle>
                        <DropdownMenu>
                            <MenuItem header>Traffic Light Protocol (TLP) Color</MenuItem>
                            <MenuItem eventKey='unset' onSelect={this.selectColor}>Unset</MenuItem>
                            <MenuItem eventKey='red' onSelect={this.selectColor}>Red</MenuItem>
                            <MenuItem eventKey='amber' onSelect={this.selectColor}>Amber</MenuItem>
                            <MenuItem eventKey='green' onSelect={this.selectColor}>Green</MenuItem>
                            <MenuItem eventKey='white' onSelect={this.selectColor}>White</MenuItem>
                            <MenuItem divider/>
                            <MenuItem href="https://www.us-cert.gov/tlp">What is TLP?</MenuItem>
                        </DropdownMenu>
                    </Dropdown> 
                </OverlayTrigger>
            </span>
        )
    }
});

module.exports = TrafficLightProtocol;
