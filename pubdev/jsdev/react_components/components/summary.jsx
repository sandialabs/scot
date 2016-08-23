var React               = require('react');
var Modal               = require('react-modal');
var Button              = require('react-bootstrap/lib/Button');
var AppActions          = require('../flux/actions.jsx');
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
            summary:this.props.summary,
            key:this.props.id,
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
            data: JSON.stringify(json),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                console.log('success: ' + data);
                AppActions.updateItem(this.state.key,'headerUpdate');
            }.bind(this),
            error: function() {
                this.props.updated('error','Failed to make summary');
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
            <span style={{display:'block'}} onClick={onClick}>{summaryDisplay}</span>
        )
    }  
});

module.exports = Summary; 
