var React = require('react');
var SelectedHeader = require('./selected_header.jsx');

var SelectedContainer = React.createClass({
    render: function() {
        var datarows = [];
        for (i=0; i < this.props.ids.length; i++) { 
            datarows.push(<SelectedHeader key={this.props.ids[i]} id={this.props.ids[i]} type={this.props.type} toggleEventDisplay={this.props.viewEvent} taskid={this.props.taskid} alertPreSelectedId={this.props.alertPreSelectedId}/>); 
        }
        //var width = this.state.width;
        var width = '100%';
        if ($('#list-view')[0] != undefined ) {
            width = 'calc(100% ' + '- ' + $('#list-view').width() + 'px)';
        }
        return (
            <div className="entry-container" style={{width: width,position: 'relative'}}> 
                {datarows}
            </div>
        );
    }
});

module.exports = SelectedContainer;
