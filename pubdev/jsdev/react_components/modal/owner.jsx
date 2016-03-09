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

var Owner = React.createClass({
    getInitialState: function() {
        return {
            currentOwner:this.props.data,
            whoami:'', 
            ownerToolbar: false,
        }
    },
    componentDidMount: function() {
        this.whoamiRequest = $.get('scot/api/v2/whoami', function (result) {
            var result = result.user;
            this.setState({whoami:result})
        }.bind(this)); 
    },
    toggle: function() { 
        var json = {'owner':this.state.whoami}
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/' + this.props.type + '/'  + this.props.id,
            data: json,
            success: function(data) {
                console.log('success: ' + data);
                this.setState({currentOwner:this.state.whoami});
                this.props.updated();
                this.ownerToggle();
            }.bind(this),
            error: function() {
                this.props.updated('red','Failed to change owner');
                this.ownerToggle();
            }.bind(this)
        }); 
    },
    ownerToggle: function() {
        if (this.state.ownerToolbar == false) {
            this.setState({ownerToolbar:true});
        } else {
            this.setState({ownerToolbar:false});
        } 
    },
    render: function() { 
        return (
            <div>
                <Button bsSize='xsmall' id='event_owner' onClick={this.ownerToggle}>{this.state.currentOwner}</Button>
                {this.state.ownerToolbar ? <Modal isOpen={true} onRequestClose={this.ownerToggle} style={customStyles}>
                    <div className='modal-header'>
                        <img src='images/close_toolbar.png' className='close_toolbar' onClick={this.ownerToggle} />
                        <h3 id='myModalLabel'>Take Ownership</h3>
                    </div>
                    <div className='modal-body'>
                        Are you sure you want to take ownership of this event?
                    </div>
                    <div className='modal-footer'>
                        <Button id='cancel-ownership' onClick={this.ownerToggle}>Cancel</Button>
                        <Button bsStyle='info' id='take-ownership' onClick={this.toggle}>Take Ownership</Button>     
                    </div>
                </Modal> : null }
            </div>
        )
    }
});

module.exports = Owner;
