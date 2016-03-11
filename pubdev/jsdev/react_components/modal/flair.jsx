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

var Flair = React.createClass({
    getInitialState: function() {
        return {
           testState:true
        }
    },
    render: function() {
        console.log('flair launched');
        return (
            <div>
                <Modal
                    isOpen={true}
                    onRequestClose={this.props.flairToggle}
                    style={customStyles}>
                    <div className="modal-header">
                        <img src="/images/close_toolbar.png" className="close_toolbar" onClick={this.props.flairToggle} />
                        <h3 id="myModalLabel">Flair</h3>
                    </div>
                    <div className="modal-body" style={{height: '700px', overflowY:'auto',width:'700px'}}>
                        flair
                    </div>
                    <div className="modal-footer">
                        <button class="btn" onClick={this.props.flairToggle}>Done</button>
                    </div>
                </Modal>
            </div>
        )
    }
});

module.exports = Flair;
