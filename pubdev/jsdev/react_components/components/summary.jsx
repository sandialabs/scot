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
     getInitialState: function () {
        return {
            summary:this.props.summary
        }
     },
     toggle: function() {
        var newSummary;
        if (this.state.summary === 1) {
            newSummary = 0;
        } else if (this.state.summary === 0) {
            newSummary = 1;
        }
        var json = {'summary':newSummary};
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/entry/' + this.props.entryid,
            data: json,
            success: function(data) {
                console.log('success: ' + data);
                this.props.updated();
            }.bind(this),
            error: function() {
                alert('Failed to make summary - contact administrator');
            }.bind(this)
        });
    },
    render: function() {
        var summaryDisplay = 'Summary Loading...'
        var onClick;
        if (this.state.summary == 0) {
            summaryDisplay = 'Make Summary';
            onClick = this.toggle;
        } else if (this.state.summary == 1) {
            summaryDisplay = 'Remove Summary';
            onClick = this.toggle;
        }
        return (
            <span onClick={onClick}>{summaryDisplay}</span>
        )
    }  
});

module.exports = Summary; 
