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
var Task = React.createClass({
    getInitialState: function () {
        return {
            taskOwner:null,
            taskStatus:null,
            whoami:''
        }
    },
    componentWillMount: function () {
        $.get('scot/api/v2/whoami', function (result) {
            var result = result.user;
            this.setState({whoami:result})
        }.bind(this));
        this.taskRequest = $.get('scot/api/v2/entry/' + this.props.entryid, function(result) {
            var taskOwner = result.task.who;
            var taskStatus = result.task.status;
            this.setState({taskOwner:taskOwner, taskStatus:taskStatus})
        }.bind(this)); 
    },
    makeTask: function () {
        var json = {'make_task':1}
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/entry/' + this.props.entryid,
            data: JSON.stringify(json),
            success: function(data) {
                console.log('success: ' + data);
                this.props.updated();
            }.bind(this),
            error: function() {
                alert('Failed to close task - contact administrator');
            }.bind(this)
        }); 
    },
    closeTask: function() {
        var json = {'close_task':1}
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/entry/' + this.props.entryid,
            data: JSON.stringify(json),
            success: function(data) {
                console.log('success: ' + data);
                this.props.updated();
            }.bind(this),
            error: function() {
                alert('Failed to close task - contact administrator');
            }.bind(this)
        });
    },
    takeTask: function() {
        var json = {'take_task':1} 
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/entry/' + this.props.entryid,
            data: JSON.stringify(json),
            success: function(data) {
                console.log('success: ' + data);
                this.props.updated();
            }.bind(this),
            error: function() {
                alert('Failed to make Task owner - contact administrator');
            }.bind(this)
        });
    },
    render: function () {
        var taskDisplay = 'Task Loading...';
        var onClick; 
        if (this.state.taskStatus === undefined || this.state.taskStatus === null) {
            taskDisplay = 'Make Task';
            onClick = this.makeTask;
        } else if (this.state.whoami != this.state.taskOwner && this.state.taskStatus == 'open') {
            taskDisplay = 'Assign task to me';
            onClick = this.takeTask;
        } else if (this.state.whoami == this.state.taskOwner && this.state.taskStatus == 'open') {
            taskDisplay = 'Close Task';
            onClick = this.closeTask;
        } else if (this.state.taskStatus == 'closed') {
            taskDisplay = 'Reopen Task';
            onClick = this.makeTask;
        } else if (this.state.whoami == this.state.taskOwner && this.state.taskStatus == 'assigned') {
            taskDisplay = 'Close Task';
            onClick = this.closeTask;
        } else if (this.state.whoami != this.state.taskowner && this.state.taskStatus == 'assigned') {
            taskDisplay = 'Assign task to me';
            onClick = this.takeTask;
        }
        return (
            <span onClick={onClick}>{taskDisplay}</span>
        )
    }
});

module.exports = Task;
