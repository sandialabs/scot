var React = require('react');
var SelectedHeader = require('./selected_header.jsx');

var SelectedContainer = React.createClass({
    getInitialState: function() {
        return {
            type:this.props.type,
            ids:this.props.ids,
        }
    },
    render: function() {
        var datarows = [];
        for (i=0; i < this.state.ids.length; i++) { 
            datarows.push(<SelectedHeader key={this.state.ids[i]} id={this.state.ids[i]} type={this.state.type} toggleEventDisplay={this.props.viewEvent}/>); 
        }
        return (
            <div className="entry-container"> 
                {datarows}
            </div>
        );
    }
});

module.exports = SelectedContainer;
