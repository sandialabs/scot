var React           = require('react');
var ReactTime       = require('react-time');
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
            historyBody:false,
            data: ''
        }
    },
    componentDidMount: function() {
    if(this.props.type == 'alertgroup'){
        type = this.props.type
        var filter = {}
        filter['id'] = [this.props.id]
        var result  = $.ajax({type: 'GET', url: '/scot/api/v2/alertgroup', data: {match: JSON.stringify(filter)}})
        result.success(function(response) {
            var response = response.records;
            this.setState({historyBody:true, data: response})
        }.bind(this))

    }
    else {
        this.serverRequest = $.get('/scot/api/v2/'+ this.props.type + '/' + this.props.id + '/history', function (result) {
            var result = result.records;
            this.setState({historyBody:true, data:result})
        }.bind(this));
    }
    },
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
                    <div className="modal-body" style={{height: '700px', overflowY:'auto',width:'700px'}}>
                       {this.state.historyBody ? <HistoryData data={this.state.data} /> : null }
                    </div>
                    <div className="modal-footer">
                        <button class="btn" onClick={this.props.historyToggle}>Done</button>
                    </div>
                </Modal>
            </div>
        )
    }
});
