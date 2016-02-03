var React = require('react');
var EntryHeader = require('./entry_header.jsx');
var EntryWrapper = require('./entry_wrapper.jsx');

var EntryContainer = React.createClass({
    getInitialState: function() {
        return {
            type:this.props.type,
            ids:this.props.ids,
        }
    },
    render: function() {
        var datarows = [];
        for (i=0; i < this.state.ids.length; i++) { 
            datarows.push(<EntryHeader id={this.state.ids[i]} type={this.state.type} toggleEventDisplay={this.props.viewEvent}/>);
            datarows.push(<EntryWrapper id={this.state.ids[i]} type={this.state.type}/>);
        }
        return (
            <div className="entry-container">
                {datarows}
            </div>
        );
    }
});

module.exports = EntryContainer;
