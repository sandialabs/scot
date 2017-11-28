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
            key:this.props.id,
        }
     },
     toggle: function() {
        var newClass;
        if (this.props.summary === 1) {
            newClass = 'entry';
        } else if (this.props.summary === 0) {
            newClass = 'summary';
        }
        var json = {'class':newClass};
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/entry/' + this.props.entryid,
            data: JSON.stringify(json),
            contentType: 'application/json; charset=UTF-8',
            success: function(data) {
                console.log('success: ' + data);
            }.bind(this),
            error: function(data) {
                this.props.errorToggle('Failed to make summary', data);
            }.bind(this)
        });
    },
    render: function() {
        var summaryDisplay = 'Summary Loading...'
        var onClick;
        if (this.props.summary == 0) {
            summaryDisplay = 'Make Summary';
            onClick = this.toggle;
        } else if (this.props.summary == 1) {
            summaryDisplay = 'Remove Summary';
            onClick = this.toggle;
        }
        return (
            <span style={{display:'block'}} onClick={onClick}>{summaryDisplay}</span>
        )
    }  
});

module.exports = Summary; 
