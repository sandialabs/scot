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

var DeleteEvent = React.createClass({
    toggle: function() { 
        $.ajax({
            type: 'delete',
            url: 'scot/api/v2/' + this.props.type + '/'  + this.props.id,
            success: function(data) {
                console.log('success: ' + data); 
                this.props.toggleEventDisplay();
                //this.props.deleteToggle();
            }.bind(this),
            error: function() {
                alert('Failed to delete - contact administrator');
                this.props.deleteToggle();
            }.bind(this)
        }); 
    },
    render: function() { 
        return (
            <div>
                <Modal isOpen={true} onRequestClose={this.props.deleteToggle} style={customStyles}>
                    <div className='modal-header'>
                        <img src='images/close_toolbar.png' className='close_toolbar' onClick={this.props.deleteToggle} />
                        <h3 id='myModalLabel'>Are you sure you want to delete {this.props.subjectType}: {this.props.id}?</h3>
                    </div> 
                    <div className='modal-footer'>
                        <Button id='cancel-delete' onClick={this.props.deleteToggle}>Cancel</Button>
                        <Button bsStyle='danger' id='delete' onClick={this.toggle}>Delete</Button>     
                    </div>
                </Modal>
            </div>
        )
    }
});

var DeleteEntry = React.createClass({
     toggle: function() {
        $.ajax({
            type: 'delete',
            url: 'scot/api/v2/' + this.props.type + '/'  + this.props.id + '/entry/' + this.props.entryid,
            success: function(data) {
                console.log('success: ' + data);
                this.props.updated();
                this.props.deleteToggle();
            }.bind(this),
            error: function() {
                alert('Failed to delete - contact administrator');
                this.props.deleteToggle();
            }.bind(this)
        });
    },
    render: function() {
        return (
            <div>
                <Modal isOpen={true} onRequestClose={this.props.deleteToggle} style={customStyles}>
                    <div className='modal-header'>
                        <img src='images/close_toolbar.png' className='close_toolbar' onClick={this.props.deleteToggle} />
                        <h3 id='myModalLabel'>Are you sure you want to delete Entry: {this.props.entryid}?</h3>
                    </div>
                    <div className='modal-footer'>
                        <Button id='cancel-delete' onClick={this.props.deleteToggle}>Cancel</Button>
                        <Button bsStyle='danger' id='delete' onClick={this.toggle}>Delete</Button>
                    </div>
                </Modal>
            </div>
        )
    }  
});

module.exports = {
    DeleteEvent:DeleteEvent,
    DeleteEntry:DeleteEntry
}
