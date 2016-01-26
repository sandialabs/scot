var React           = require('react');
var Modal           = require('react-modal');

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

var EntryHeaderHistory = React.createClass({
    render: function() {
        return (
            <div>
                <Modal
                    isOpen={true}
                    onRequestClose={this.props.historyToggle}
                    style={customStyles}>
                    <div className="modal-header">
                        <img src="/images/close_toolbar.png" className="close_toolbar" onClick={this.props.historyToggle} />
                        <h3 id="myModalLabel">Current History</h3>
                    </div>
                    <div className="modal-body">
                        <p>HISTORY GOES HERE ONCE DB IS READY</p>
                    </div>
                    <div className="modal-footer">
                        <button class="btn" onClick={this.props.historyToggle}>Done</button>
                    </div>
                </Modal>
            </div>
        )
    }
});

module.exports = EntryHeaderHistory;
