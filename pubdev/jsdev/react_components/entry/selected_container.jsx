var React = require('react');
var SelectedHeader = require('./selected_header.jsx');

var SelectedContainer = React.createClass({
    render: function() {
        var datarows = [];
        datarows.push(<SelectedHeader key={this.props.id} id={this.props.id} type={this.props.type} toggleEventDisplay={this.props.viewEvent} taskid={this.props.taskid} alertPreSelectedId={this.props.alertPreSelectedId}/>); 
        //var width = this.state.width;
        var width = '100%';
        if ($('#list-view')[0] != undefined ) {
            width = 'calc(100% ' + '- ' + $('#list-view').width() + 'px)';
        }
        return (
            <div id='main-detail-container' className="entry-container" style={{width: width,position: 'relative'}} tabIndex='3'> 
                {datarows}
            </div>
        );
    }
});

module.exports = SelectedContainer;
