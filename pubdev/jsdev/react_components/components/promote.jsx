React           = require('react');

var Promote = React.createClass({
    getInitialState: function () {
        return {
            newURL:null,
            newType: null
        }
    },
    componentDidMount: function() {
        if (this.props.type == "alert") {
            this.setState({newType:"Event"})
            this.setState({newURL:'event'});
        } else if (this.props.type == "event") {
            this.setState({newType:"Incident"})
            this.setState({newURL:'incident'});
        } 
    },
    promote: function() {
        var data = JSON.stringify({promote:'new'});
        $.ajax({
            type: 'put',
            url: 'scot/api/v2/' + this.props.type + '/' + this.props.id,
            data: data,
            success: function(data) {
                console.log('successfully promoted');
                window.location.assign('#/'+this.state.newURL+'/'+data.id);
            }.bind(this),
            error: function() {
                this.props.updated('error','Failed to promote');
            }.bind(this)
        });
    },
    render: function() {
        var type = this.props.type;
        var id = this.props.id; 
        return (
            <span onClick={this.promote}>
                Make <b>{this.state.newType}</b>
            </span>
        )
    }
});

module.exports = Promote;
