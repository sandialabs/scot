var React               = require('react');
var Modal               = require('react-modal');
var Button              = require('react-bootstrap/lib/Button');
const customStyles = {
    content : {
        top     : '50%',
        left    : '50%',
        right   : 'auto',
        bottom  : 'auto',
        marginRight: '-50%',
        transform:  'translate(-50%, -50%)'
    }
}

var TakeOwnership = React.createClass({
    getInitialState: function() {
        return {
            whoami:'', 
        }
    },
    componentDidMount: function() {
        //this.whoamiRequest = $.get('scot/api/v2/') ADD THE REST HERE
        whoamiResult = 'angeor';
        this.setState({whoami:whoamiResult})
    },
    toggle: function() { 
        var json = {'owner':this.state.whoami}
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/event/' + this.props.id,
            data: json,
            success: function(data) {
                console.log('success: ' + data);
            },
            error: function() {
                alert('Failed to make you owner - contact administrator');
            }.bind(this)
        }); 
        this.props.ownerToggle();
    },
    render: function() { 
        return (
            <div>
                <Modal isOpen={true} onRequestClose={this.props.ownerToggle} style={customStyles}>
                    <div className='modal-header'>
                        <img src='images/close_toolbar.png' className='close_toolbar' onClick={this.props.ownerToggle} />
                        <h3 id='myModalLabel'>Take Ownership</h3>
                    </div>
                    <div className='modal-body'>
                        Are you sure you want to take ownership of this event?
                    </div>
                    <div className='modal-footer'>
                        <Button id='cancel-ownership' onClick={this.props.ownerToggle}>Cancel</Button>
                        <Button bsStyle='info' id='take-ownership' onClick={this.toggle}>Take Ownership</Button>     
                    </div>
                </Modal>
            </div>
        )
    }
});

module.exports = TakeOwnership;
