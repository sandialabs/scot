React           = require('react');

var Promote = React.createClass({
    promote: function() {
        var newType;
        var data = JSON.stringify({promote:'new'});
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
            data: data,
            success: function(data) {
                console.log('successfully promoted');
                console.log(data);
            }.bind(this),
            error: function() {
                alert('Failed to promote');
            }.bind(this)
        });
    },
    render: function() {
        var type = this.props.type;
        var id = this.props.id;
        var newType = null;
        var showPromote = true;
        if (type == "alert") {
            newType = "Event"
        } else if (type == "event") {
            newType = "Incident"
        } 
        return (
            <span onClick={this.promote}>
                Make <b>{newType}</b>
            </span>
        )
    }
});

module.exports = Promote;
