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

var Summary = React.createClass({ 
     toggle: function() {
        var json = {'summary':1};
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/entry/' + this.props.entryid,
            data: json,
            success: function(data) {
                console.log('success: ' + data);
                this.props.updated();
                this.props.summaryToggle();
            }.bind(this),
            error: function() {
                alert('Failed to make summary - contact administrator');
                this.props.summaryToggle();
            }.bind(this)
        });
    },
    render: function() {
        return (
            <div>
                <Modal isOpen={true} onRequestClose={this.props.summaryToggle} style={customStyles}>
                    <div className='modal-header'>
                        <img src='images/close_toolbar.png' className='close_toolbar' onClick={this.props.summaryToggle} />
                        <h3 id='myModalLabel'>Are you sure you want to make Entry: {this.props.entryid} the summary?</h3>
                    </div>
                    <div className='modal-body pull-right'>
                        <Button id='cancel-summary' onClick={this.props.summaryToggle}>Cancel</Button>
                        <Button bsStyle='primary' id='summary' onClick={this.toggle}>Make Summary</Button>
                    </div>
                </Modal>
            </div>
        )
    }  
});

module.exports = Summary; 
