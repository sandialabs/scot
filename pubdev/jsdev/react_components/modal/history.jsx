var React           = require('react');
var ReactTime       = require('react-time');
var Modal           = require('react-modal');
var type;
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

var History = React.createClass({
    getInitialState: function() {
        return {
            historyBody:false,
            data: ''
        }
    },
    componentDidMount: function() {
        this.serverRequest = $.get('/scot/api/v2/'+ this.props.type + '/' + this.props.id + '/history', function (result) {
            var result = result.records;
            this.setState({historyBody:true, data:result})
        }.bind(this));
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
                    <div className="modal-body" style={{height: '75vh', width:'700px',overflowY:'auto'}}>
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

var HistoryData = React.createClass({
    render: function() {
        var rows = [];
        data = this.props.data;
        for (var prop in data) {
            rows.push(<HistoryDataIterator data={data[prop]} />); 
        }
        return (
            <div>
                {rows}
            </div>
        )
    }
})


var HistoryDataIterator = React.createClass({
    render: function() {
    data = this.props.data;
    return (
        <div>ID: {data.id} - <ReactTime value={data.when * 1000} format="MM/DD/YYYY hh:mm:ss a" /> - {data.who} - {data.what}</div>
    )}
});



module.exports = History;
